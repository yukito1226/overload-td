extends Node
## 進行状況（セーブ）と各種計算式

const SAVE_PATH := "user://necrothrone_save.json"

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
	load_game()

# ---------------- セーブ ----------------
func fresh_run(s: Dictionary) -> void:
	s["souls"] = 0.0
	s["stage"] = 1
	s["max_stage"] = 1
	s["relics"] = []
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
	var s := {"core": 0, "talents": {}, "rebirths": 0, "best": 1, "intro": false}
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

func relic_n(k: String) -> int:
	return S["relics"].count(k)

func card_lv_cost(lv: int) -> int:
	return int(floor(25.0 * pow(1.55, lv - 1)))

func up_cost(k: String) -> int:
	var u: Dictionary = Data.UPS[k]
	return int(floor(u["base"] * pow(u["g"], S["up"][k])))

func soul_mult() -> float:
	return (1.0 + 0.1 * S["up"]["wallet"]) * (1.0 + 0.25 * T("harvest"))

func unit_stats(id: String) -> Dictionary:
	var c: Dictionary = Data.CARDS[id]
	var lv := int(S["cards"].get(id, 1))
	var lm := 1.0 + 0.25 * (lv - 1)
	var atk_m := lm * pow(1.12, T("might")) * (1.0 + 0.15 * relic_n("crown"))
	var hp_m := lm * pow(1.12, T("flesh")) * (1.0 + 0.15 * relic_n("hide"))
	return {
		"hp": roundi(c["hp"] * hp_m), "atk": roundi(c["atk"] * atk_m),
		"spd": c["spd"] * (1.0 + 0.12 * relic_n("march")),
		"cd": c["cd"] * pow(0.88, relic_n("hourg")) * pow(0.88, T("rite")),
	}

func regen_rate() -> float:
	return 32.0 * (1.0 + 0.1 * S["up"]["regen"]) * (1.0 + 0.1 * T("flow")) * (1.0 + 0.15 * relic_n("grail"))

func max_mana() -> int:
	return 600 + 120 * S["up"]["maxm"]

func castle_hp() -> int:
	return roundi(1500.0 * (1.0 + 0.2 * S["up"]["castle"]) * (1.0 + 0.25 * relic_n("shield")) * (1.0 + 0.4 * T("fortress")))

func enemy_scale(s: int) -> Dictionary:
	return {"hp": pow(1.13, s - 1), "atk": pow(1.09, s - 1)}

func ebase_hp(s: int) -> int:
	return roundi(1100.0 * pow(1.15, s - 1))

func win_souls(s: int) -> int:
	return int(floor((40.0 + s * 14.0) * pow(1.13, s - 1) * soul_mult()))

func rebirth_gain() -> int:
	var m: int = S["max_stage"]
	return int(floor(pow(m, 1.6) / 4.0)) if m >= 5 else 0

func fmt(n: float) -> String:
	if n >= 1e6:
		return "%.2fM" % (n / 1e6)
	if n >= 1e4:
		return "%.1fk" % (n / 1e3)
	return str(int(floor(n)))

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
