extends Node
## 進行状況（セーブ）と各種計算式

const SAVE_PATH_NORMAL := "user://necrothrone_save.json"
const SAVE_PATH_DEBUG := "user://necrothrone_save_debug.json"

## 起動オプション（`godot --path . -- --debug --stage=10` のように -- の後ろに書く）
##   --debug     デバッグパネル（F1）を有効化し、通常とは別のセーブを使う
##   --stage=N   起動したらすぐステージNのバトルを始める（--debug も自動で有効）
##   --fresh     デバッグ用セーブを初期化して始める
var debug := false
var boot_stage := 0
var SAVE_PATH := SAVE_PATH_NORMAL

const C_BG := Color("#0d0a12")
const C_PANEL := Color("#1a1422")
const C_PANEL2 := Color("#241b30")
const C_LINE := Color("#3d2f52")
const C_TEXT := Color("#e8e0f0")
const C_DIM := Color("#9a8cb0")
const C_ACCENT := Color("#b07cff")
const C_GOLD := Color("#e0b040")
const C_RED := Color("#ff4a5a")

var S: Dictionary = {}
var font: Font

func _ready() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Yu Gothic UI", "Yu Gothic", "Meiryo", "Hiragino Sans", "Hiragino Kaku Gothic ProN", "Noto Sans CJK JP", "Noto Sans JP", "sans-serif"])
	font = f
	_parse_args()
	if debug and "--fresh" in OS.get_cmdline_user_args() and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	load_game()

func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--debug":
			debug = true
		elif a.begins_with("--stage="):
			boot_stage = max(1, int(a.get_slice("=", 1)))
			debug = true
	# エディタから実行したとき（エクスポート版でないとき）もデバッグパネルを使える
	if OS.has_feature("editor"):
		debug = true
	if debug:
		SAVE_PATH = SAVE_PATH_DEBUG

# ---------------- セーブ ----------------
func fresh_run(s: Dictionary) -> void:
	s["souls"] = 0.0
	s["stage"] = 1
	s["max_stage"] = 1
	s["up"] = {"regen": 0, "maxm": 0, "castle": 0, "wallet": 0}
	var cards := {}
	for k in Data.STARTER:
		cards[k] = 1
	var extra := []
	for k in Data.CARDS:
		if not Data.STARTER.has(k):
			extra.append(k)
	var pact := int(s.get("talents", {}).get("pact", 0))
	for i in min(pact, extra.size()):
		cards[extra[i]] = 1
	s["cards"] = cards
	var deck := []
	for k in cards:
		if deck.size() < 6:
			deck.append(k)
	s["deck"] = deck

func new_save() -> Dictionary:
	var s := {"core": 0, "talents": {}, "rebirths": 0, "best": 1, "intro": false, "relic_lv": {}, "shards": 0.0}
	fresh_run(s)
	return s

func load_game() -> void:
	S = {}
	if FileAccess.file_exists(SAVE_PATH):
		var txt := FileAccess.get_file_as_string(SAVE_PATH)
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary and parsed.has("cards"):
			S = parsed
	if S.is_empty():
		S = new_save()
	# JSONは数値をfloatで返すので整数に戻す
	for k in ["stage", "max_stage", "core", "rebirths", "best"]:
		S[k] = int(S.get(k, 1))
	for k in S["cards"]:
		S["cards"][k] = int(S["cards"][k])
	for k in S["up"]:
		S["up"][k] = int(S["up"][k])
	for k in S["talents"]:
		S["talents"][k] = int(S["talents"][k])
	# 遺物：旧形式（周回ごとの重ね取りリスト）を永続Lvに変換
	if not S.has("relic_lv"):
		S["relic_lv"] = {}
		for r in S.get("relics", []):
			if Data.RELICS.has(r):
				S["relic_lv"][r] = int(S["relic_lv"].get(r, 0)) + 1
	S.erase("relics")
	for k in S["relic_lv"].keys():
		if Data.RELICS.has(k):
			S["relic_lv"][k] = int(S["relic_lv"][k])
		else:
			S["relic_lv"].erase(k)
	S["shards"] = float(S.get("shards", 0.0))
	S["souls"] = float(S.get("souls", 0.0))

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(S))

func wipe() -> void:
	S = new_save()
	save_game()

# ---------------- 計算 ----------------
func T(k: String) -> int:
	return int(S["talents"].get(k, 0))

## パッシブの次のLvに必要な冥核（最大Lvなら -1）
func passive_cost(k: String) -> int:
	var p: Dictionary = Data.PASSIVES[k]
	var lv := T(k)
	if lv >= p["max"]:
		return -1
	return int(p["base"]) * (lv + 1)

## 解放条件を満たしているか
func passive_unlocked(k: String) -> bool:
	var p: Dictionary = Data.PASSIVES[k]
	if not p.has("req"):
		return true
	return T(p["req"][0]) >= int(p["req"][1])

# ---------------- 遺物 ----------------
func rl(k: String) -> int:
	return int(S["relic_lv"].get(k, 0))

func relic_count() -> int:
	return S["relic_lv"].size()

## 掛け算型の遺物の倍率（未所持なら1）
func relic_mul(k: String) -> float:
	return pow(1.0 + Data.RELICS[k]["v"], rl(k))

## 足し算型の遺物の値（未所持なら0）
func relic_add(k: String) -> float:
	var r: Dictionary = Data.RELICS[k]
	return r["v"] * min(rl(k), int(r.get("max", 9999)))

func relic_value_text(k: String, lv: int) -> String:
	var r: Dictionary = Data.RELICS[k]
	if r["kind"] == "mul":
		if k == "chain":
			return "×" + fmt_mult(pow(pow(1.0 + r["v"], lv), max(1, relic_count())))
		return "×" + fmt_mult(pow(1.0 + r["v"], lv))
	var v: float = r["v"] * min(lv, int(r.get("max", 9999)))
	if r.get("flat", false):
		return "+%d" % int(v)
	return "+%d%%" % roundi(v * 100)

## 次のLvに必要な欠片（最大Lvなら -1）
func relic_cost(k: String) -> float:
	var r: Dictionary = Data.RELICS[k]
	var lv := rl(k)
	if r["kind"] == "add" and lv >= int(r.get("max", 9999)):
		return -1.0
	return floor(Data.RARITY[r["rarity"]]["cost"] * pow(1.45, lv - 1))

func relic_up(k: String) -> bool:
	var c := relic_cost(k)
	if c < 0 or S["shards"] < c or rl(k) == 0:
		return false
	S["shards"] -= c
	S["relic_lv"][k] = rl(k) + 1
	return true

## 安い順にまとめて強化。上げた回数を返す
func relic_up_all() -> int:
	var n := 0
	while true:
		var best := ""
		var bc := INF
		for k in S["relic_lv"]:
			var c := relic_cost(k)
			if c >= 0 and c < bc:
				bc = c
				best = k
		if best == "" or S["shards"] < bc:
			break
		relic_up(best)
		n += 1
	return n

## レア度の重みでランダムな遺物を1つ選ぶ
func roll_relic() -> String:
	var tot := 0.0
	for k in Data.RELICS:
		tot += Data.RARITY[Data.RELICS[k]["rarity"]]["weight"]
	var x := randf() * tot
	for k in Data.RELICS:
		x -= Data.RARITY[Data.RELICS[k]["rarity"]]["weight"]
		if x <= 0:
			return k
	return Data.RELICS.keys()[0]

## 遺物を得る：未所持なら発見（Lv1）、所持済みならLv+1
func gain_relic(k: String) -> void:
	S["relic_lv"][k] = rl(k) + 1

func shard_win(s: int) -> float:
	return floor(3.0 * pow(1.14, s - 1) * relic_mul("fang") * (1.0 + 0.1 * S["rebirths"]))

# ---------------- 魂貨・ユニット ----------------
func card_lv_cost(lv: int) -> float:
	return floor(25.0 * pow(1.55, lv - 1))

func up_cost(k: String) -> float:
	var u: Dictionary = Data.UPS[k]
	return floor(u["base"] * pow(u["g"], S["up"][k]))

func soul_mult() -> float:
	return (1.0 + 0.1 * S["up"]["wallet"]) * (1.0 + 0.25 * T("harvest")) * relic_mul("purse")

func atk_mult() -> float:
	return pow(1.12, T("might")) * relic_mul("crown") * relic_mul("heart") * pow(relic_mul("chain"), relic_count())

func hp_mult() -> float:
	return pow(1.12, T("flesh")) * relic_mul("hide") * relic_mul("heart")

func unit_stats(id: String) -> Dictionary:
	var c: Dictionary = Data.CARDS[id]
	var lv := int(S["cards"].get(id, 1))
	var lm := pow(1.17, lv - 1)
	return {
		"hp": floor(c["hp"] * lm * hp_mult()), "atk": floor(c["atk"] * lm * atk_mult()),
		"spd": c["spd"] * (1.0 + relic_add("march")),
		"cd": c["cd"] * (1.0 - relic_add("hourg")) * pow(0.88, T("rite")),
	}

func crit_rate() -> float:
	return relic_add("lens")

func regen_rate() -> float:
	return 32.0 * (1.0 + 0.1 * S["up"]["regen"]) * (1.0 + 0.1 * T("flow")) * (1.0 + relic_add("grail"))

func max_mana() -> int:
	return 600 + 120 * S["up"]["maxm"]

func castle_hp() -> float:
	return floor(1500.0 * (1.0 + 0.2 * S["up"]["castle"]) * relic_mul("shield") * (1.0 + 0.4 * T("fortress")))

func enemy_scale(s: int) -> Dictionary:
	return {"hp": pow(1.13, s - 1), "atk": pow(1.09, s - 1)}

func ebase_hp(s: int) -> float:
	return floor(1100.0 * pow(1.15, s - 1))

func win_souls(s: int) -> float:
	return floor((40.0 + s * 14.0) * pow(1.13, s - 1) * soul_mult())

func rebirth_gain() -> int:
	var m: int = S["max_stage"]
	return int(floor(pow(m, 1.6) / 4.0 * (1.0 + relic_add("tome")))) if m >= 5 else 0

# ---------------- 数値表記 ----------------
const UNITS := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

## 大きな数を短く表す：12,345 → 12.3K、4.56e15 → 4.56Qa、それ以上は 1.23e45
func fmt(n: float) -> String:
	if is_nan(n) or is_inf(n):
		return "∞"
	var neg := n < 0
	n = absf(n)
	var s := ""
	if n < 10000.0:
		s = str(int(floor(n)))
	else:
		var e := int(floor(log(n) / log(10.0)))
		var tier := e / 3
		if tier < UNITS.size():
			var v := n / pow(10.0, tier * 3)
			s = ("%.2f" % v if v < 10 else ("%.1f" % v if v < 100 else "%d" % int(v))) + UNITS[tier]
		else:
			s = "%.2fe%d" % [n / pow(10.0, e), e]
	return ("-" if neg else "") + s

## 倍率の表記（×1.25、×12.3、×4.56M）
func fmt_mult(m: float) -> String:
	if m < 10:
		return "%.2f" % m
	if m < 1000:
		return "%.1f" % m
	return fmt(m)

# ---------------- UI ヘルパー ----------------
func sb(bg: Color, border: Color, radius := 6, bw := 1, pad := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s

func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 14
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(C_TEXT, 0.35))
	t.set_stylebox("normal", "Button", sb(C_PANEL2, C_LINE, 5, 1, 7))
	t.set_stylebox("hover", "Button", sb(C_PANEL2.lightened(0.08), C_ACCENT, 5, 1, 7))
	t.set_stylebox("pressed", "Button", sb(C_PANEL2.darkened(0.2), C_ACCENT, 5, 1, 7))
	t.set_stylebox("disabled", "Button", sb(C_PANEL2.darkened(0.3), C_LINE.darkened(0.3), 5, 1, 7))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", sb(C_PANEL, C_LINE))
	t.set_stylebox("panel", "TabContainer", sb(C_PANEL2, C_LINE, 6, 1, 10))
	t.set_stylebox("tab_selected", "TabContainer", sb(C_PANEL2, C_LINE, 6, 1, 8))
	t.set_stylebox("tab_unselected", "TabContainer", sb(C_PANEL, C_LINE, 6, 1, 8))
	t.set_stylebox("tab_hovered", "TabContainer", sb(C_PANEL.lightened(0.05), C_ACCENT, 6, 1, 8))
	t.set_color("font_selected_color", "TabContainer", C_TEXT)
	t.set_color("font_unselected_color", "TabContainer", C_DIM)
	t.set_color("font_hovered_color", "TabContainer", C_TEXT)
	t.set_stylebox("background", "ProgressBar", sb(Color("#140e1c"), C_LINE, 4, 1, 0))
	t.set_stylebox("fill", "ProgressBar", sb(Color("#7a3cc0"), Color("#b07cff"), 4, 0, 0))
	t.set_color("font_color", "ProgressBar", Color.WHITE)
	return t

func label(text: String, size := 14, color := C_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func button(text: String, cb: Callable, color := Color(0, 0, 0, 0)) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	if color.a > 0:
		b.add_theme_color_override("font_color", color)
		b.add_theme_stylebox_override("normal", sb(C_PANEL2, color, 5, 1, 7))
	return b
