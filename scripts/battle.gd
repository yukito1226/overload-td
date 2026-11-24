extends Node2D
## タワーディフェンスのバトル画面

const W := 960.0
const H := 420.0
const GROUND := 340.0
const CASTLE_X := 90.0
const EBASE_X := 880.0
const TIME_LIMIT := 180.0

class Unit:
	var side: int
	var d: Dictionary
	var hp: float
	var mx: float
	var atk: float
	var spd: float
	var x: float
	var lane: float
	var atk_t := 0.2
	var anim := 0.0
	var kb := 0.0
	var kb_done := 0
	var tex: Texture2D
	var w: float
	var h: float
	var walk: float
	var dead := false
	var hit := 0.0
	var saved := false

var main
var stage := 1
var t := 0.0
var units: Array = []
var proj: Array = []
var fx: Array = []
var nums: Array = []
var pillars: Array = []
var mana := 0.0
var castle := {}
var ebase := {}
var cds := {}
var spawn_t := 2.0
var sc := {}
var rushed := false
var rush_left := 0
var rush_t := 0.0
var boss_spawned := false
var spell := 0.0
var spell_max := 30.0
var over := false
var won := false
var kills := 0
var soul_bonus := 0
var shake := 0.0
var flash := 0.0
var banner := {}
var speed := 1
var legion_t := 0.0
var cannon_t := 1.0
var bolts: Array = []
var core_gain := 0

var bg_tex: ImageTexture
var font: Font
var hand_btns: Array = []
var hand_cd: Array = []
var mana_bar: ProgressBar
var spell_btn: Button
var spd_btn: Button

func _ready() -> void:
	font = G.font
	sc = G.enemy_scale(stage)
	mana = min(G.max_mana(), 60.0 * G.T("start"))
	castle = {"x": CASTLE_X, "hp": float(G.castle_hp()), "max": float(G.castle_hp())}
	ebase = {"x": EBASE_X, "hp": float(G.ebase_hp(stage)), "max": float(G.ebase_hp(stage))}
	spell_max = 30.0 * pow(0.8, G.relic_n("bell")) * pow(0.85, G.T("chant"))
	legion_t = _legion_interval()
	for id in G.S["deck"]:
		cds[id] = 0.0
	bg_tex = _make_bg()
	_build_hud()

# ---------------- HUD ----------------
func _build_hud() -> void:
	var hud := VBoxContainer.new()
	hud.theme = main.theme
	hud.position = Vector2(10, H + 6)
	hud.size = Vector2(W - 20, 620 - H - 12)
	hud.add_theme_constant_override("separation", 6)
	add_child(hud)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	hud.add_child(row)
	mana_bar = ProgressBar.new()
	mana_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mana_bar.custom_minimum_size.y = 30
	mana_bar.show_percentage = false
	row.add_child(mana_bar)
	var ml := G.label("", 13, Color.WHITE)
	ml.name = "ManaText"
	ml.set_anchors_preset(Control.PRESET_FULL_RECT)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mana_bar.add_child(ml)
	spell_btn = G.button("冥王の裁き", cast_spell)
	spell_btn.custom_minimum_size.x = 150
	row.add_child(spell_btn)
	spd_btn = G.button("×1", func(): speed = 2 if speed == 1 else 1; spd_btn.text = "×%d" % speed)
	spd_btn.custom_minimum_size.x = 50
	row.add_child(spd_btn)
	row.add_child(G.button("撤退", func(): if not over: main.confirm("撤退しますか？", "敗北扱いになります（少量の魂貨は得られます）。", func(): end_battle(false)), G.C_RED))

	var hand := HBoxContainer.new()
	hand.add_theme_constant_override("separation", 6)
	hand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hud.add_child(hand)
	var deck: Array = G.S["deck"]
	for i in 6:
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 128
		b.clip_contents = true
		hand.add_child(b)
		if i >= deck.size():
			b.disabled = true
			b.modulate.a = 0.3
			continue
		var id: String = deck[i]
		var c: Dictionary = Data.CARDS[id]
		b.pressed.connect(func(): summon(id))
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 0)
		b.add_child(v)
		var key := G.label(str(i + 1), 10, G.C_DIM)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(key)
		var tr := TextureRect.new()
		tr.texture = Data.TEX[c["spr"]]["r"]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size.y = 52
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
		for txt in [[c["name"], 12, G.C_TEXT], [str(c["cost"]), 13, G.C_ACCENT]]:
			var l := G.label(txt[0], txt[1], txt[2])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(l)
		var cd := ColorRect.new()
		cd.color = Color(0, 0, 0, 0.65)
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cd)
		hand_btns.append(b)
		hand_cd.append(cd)

func _update_hud() -> void:
	var deck: Array = G.S["deck"]
	for i in hand_btns.size():
		var id: String = deck[i]
		var c: Dictionary = Data.CARDS[id]
		var st := G.unit_stats(id)
		var b: Button = hand_btns[i]
		var poor: bool = mana < c["cost"]
		b.modulate = Color(0.5, 0.5, 0.55) if poor else Color.WHITE
		var r: float = cds[id] / st["cd"] if cds[id] > 0 else 0.0
		var cd: ColorRect = hand_cd[i]
		cd.size = Vector2(b.size.x, b.size.y * r)
		cd.position = Vector2(0, b.size.y * (1.0 - r))
	var m := G.max_mana()
	mana_bar.max_value = m
	mana_bar.value = mana
	(mana_bar.get_node("ManaText") as Label).text = "魂力 %d / %d" % [int(mana), m]
	var ready := spell >= spell_max
	spell_btn.disabled = not ready
	spell_btn.text = "冥王の裁き ⚡" if ready else "冥王の裁き %d%%" % int(spell / spell_max * 100)

func _unhandled_input(e: InputEvent) -> void:
	if over or not (e is InputEventKey) or not e.pressed or e.echo:
		return
	var k: int = e.keycode
	if k >= KEY_1 and k <= KEY_6:
		var i := k - KEY_1
		if i < G.S["deck"].size():
			summon(G.S["deck"][i])
	elif k == KEY_SPACE or k == KEY_Q:
		cast_spell()

# ---------------- 召喚・戦闘 ----------------
func summon(id: String) -> void:
	if over:
		return
	var c: Dictionary = Data.CARDS[id]
	var st := G.unit_stats(id)
	if mana < c["cost"] or cds[id] > 0:
		return
	mana -= c["cost"]
	cds[id] = st["cd"]
	_add_unit(1, c, st["hp"], st["atk"], st["spd"], CASTLE_X + 30)

func _add_unit(side: int, d: Dictionary, hp: float, atk: float, spd: float, x: float) -> void:
	var u := Unit.new()
	u.side = side
	u.d = d
	u.hp = hp
	u.mx = hp
	u.atk = atk
	u.spd = spd
	u.x = x
	u.lane = randf() * 14.0
	u.tex = Data.TEX[d["spr"]]["r" if side > 0 else "l"]
	u.w = u.tex.get_width()
	u.h = u.tex.get_height()
	u.walk = randf() * 6.0
	units.append(u)

func _damage(u: Unit, dmg: float) -> void:
	if u.dead:
		return
	u.hp -= dmg
	u.hit = 0.12
	if u.hp <= 0 and u.side > 0 and G.T("undying") > 0 and not u.saved:
		u.saved = true
		u.hp = 1
		nums.append({"x": u.x, "y": GROUND - u.h - 18, "v": "執念", "t": 0.9, "c": G.C_ACCENT})
	nums.append({"x": u.x, "y": GROUND - u.h - 6, "v": str(roundi(dmg)), "t": 0.7, "c": Color("#ff8a8a") if u.side > 0 else Color("#ffe080")})
	var kb_n: int = u.d.get("kb", 1)
	var seg := int(floor((1.0 - max(0.0, u.hp) / u.mx) * kb_n))
	if u.hp <= 0:
		u.dead = true
		for i in 10:
			fx.append({"x": u.x, "y": GROUND - u.h / 2, "vx": randf_range(-60, 60), "vy": -randf() * 140, "t": 0.6, "c": G.C_ACCENT if u.side > 0 else Color("#e8e0c8")})
		if u.side < 0:
			kills += 1
			mana = min(G.max_mana(), mana + 8 * G.relic_n("eater"))
			soul_bonus += int(u.d.get("soul", 0))
	elif seg > u.kb_done:
		u.kb_done = seg
		u.kb = 0.35

func _hit_base(side: int, dmg: float) -> void:
	var b: Dictionary = ebase if side > 0 else castle
	if side < 0:
		dmg *= pow(0.9, G.T("fortress"))
	b["hp"] -= dmg
	shake = 0.15
	nums.append({"x": b["x"] + (-20 if side > 0 else 20), "y": GROUND - 160, "v": str(roundi(dmg)), "t": 0.7, "c": Color("#ffe080") if side > 0 else Color("#ff8a8a")})

func _foes(u: Unit) -> Array:
	return units.filter(func(o): return o.side != u.side and not o.dead)

func _apply_hit(u: Unit, tx: float, dmg: float, aoe: float) -> void:
	var base_x := EBASE_X - 40 if u.side > 0 else CASTLE_X + 40
	if aoe > 0:
		for f in _foes(u):
			if abs(f.x - tx) <= aoe:
				_damage(f, dmg)
				_drain(u, dmg)
		if abs(base_x - tx) <= aoe + 30:
			_hit_base(u.side, dmg)
		var col: Color = u.d.get("proj", Color("#ff8a20"))
		for i in 8:
			fx.append({"x": tx + randf_range(-aoe, aoe) / 2, "y": GROUND - 10 - randf() * 30, "vx": 0.0, "vy": -60.0, "t": 0.4, "c": col})
	else:
		var best: Unit = null
		var bd := 40.0
		for f in _foes(u):
			var d: float = abs(f.x - tx)
			if d < bd:
				bd = d
				best = f
		if best:
			_damage(best, dmg)
			_drain(u, dmg)
		elif abs(base_x - tx) < 50:
			_hit_base(u.side, dmg)

func _drain(u: Unit, dmg: float) -> void:
	var lv := G.T("drain")
	if u.side > 0 and lv > 0 and not u.dead:
		u.hp = min(u.mx, u.hp + dmg * 0.1 * lv)

func _step_unit(u: Unit, dt: float) -> void:
	if u.side > 0 and G.T("regen") > 0:
		u.hp = min(u.mx, u.hp + u.mx * 0.015 * G.T("regen") * dt)
	if u.kb > 0:
		u.kb -= dt
		u.x = clamp(u.x - u.side * 110 * dt, CASTLE_X + 10, EBASE_X - 10)
		return
	u.atk_t -= dt
	u.anim = max(0.0, u.anim - dt)
	u.hit = max(0.0, u.hit - dt)
	var d := u.d
	# 回復役
	if d.has("heal"):
		var hurt := units.filter(func(o): return o.side == u.side and not o.dead and o != u and not o.d.get("boss", false) and o.hp < o.mx * 0.85 and abs(o.x - u.x) <= d["range"])
		if hurt.size() > 0:
			if u.atk_t <= 0:
				hurt.sort_custom(func(a, b): return a.hp / a.mx < b.hp / b.mx)
				var tg: Unit = hurt[0]
				var amt: float = d["heal"] * sc["atk"]
				tg.hp = min(tg.mx, tg.hp + amt)
				nums.append({"x": tg.x, "y": GROUND - tg.h - 6, "v": "+" + str(roundi(amt)), "t": 0.7, "c": Color("#8aff9a")})
				u.atk_t = d["rate"]
				u.anim = 0.25
			return
	# 前方で最も近い敵
	var tgt: Unit = null
	var td := INF
	for f in _foes(u):
		var fd: float = (f.x - u.x) * u.side
		if fd >= -8 and fd < td:
			td = fd
			tgt = f
	var bx := EBASE_X - 40 if u.side > 0 else CASTLE_X + 40
	var bd := (bx - u.x) * u.side
	var target_x = null
	if tgt and td <= d["range"] and td <= bd:
		target_x = tgt.x
	elif bd <= d["range"]:
		target_x = bx
		tgt = null
	if target_x != null:
		if u.atk_t <= 0:
			u.atk_t = d["rate"]
			u.anim = 0.25
			if d.has("proj"):
				proj.append({"x": u.x + u.side * u.w * 0.3, "y": GROUND - u.h * 0.6, "tx": target_x, "ref": tgt, "side": u.side,
					"dmg": u.atk, "aoe": float(d.get("aoe", 0)), "c": d["proj"], "u": u, "big": d.has("aoe"), "done": false})
			else:
				_apply_hit(u, target_x, u.atk, float(d.get("aoe", 0)))
	else:
		var slow := 1.0
		if u.side < 0 and G.T("miasma") > 0 and u.x < CASTLE_X + 260:
			slow = max(0.25, 1.0 - 0.2 * G.T("miasma"))
		u.x += u.side * u.spd * dt * slow
		u.walk += dt * u.spd * 0.25

func _step_proj(p: Dictionary, dt: float) -> void:
	var ref = p["ref"]
	var tx: float = ref.x if ref != null and not ref.dead else p["tx"]
	p["tx"] = tx
	var dx: float = tx - p["x"]
	var sp := 420.0 * dt
	if abs(dx) <= sp:
		p["done"] = true
		_apply_hit(p["u"], tx, p["dmg"], p["aoe"])
	else:
		p["x"] += sign(dx) * sp

func _enemy_pool() -> Array:
	var s := stage
	var pool := [["foot", 5.0]]
	if s >= 2: pool.append(["spear", 3.0])
	if s >= 3: pool.append(["xbow", 3.0])
	if s >= 5: pool.append(["priest", 1.5])
	if s >= 6: pool.append(["paladin", 1.5 + s * 0.05])
	if s >= 8: pool.append(["inq", 1.5 + s * 0.05])
	return pool

func _pick_enemy() -> String:
	var pool := _enemy_pool()
	var tot := 0.0
	for p in pool:
		tot += p[1]
	var r := randf() * tot
	for p in pool:
		r -= p[1]
		if r <= 0:
			return p[0]
	return pool[0][0]

func _spawn_enemy(key: String) -> void:
	var e: Dictionary = Data.ENEMIES[key]
	_add_unit(-1, e, roundi(e["hp"] * sc["hp"]), roundi(e["atk"] * sc["atk"] * (1.0 - 0.07 * G.T("hex"))), e["spd"], EBASE_X - 30)

func _enemy_ai(dt: float) -> void:
	spawn_t -= dt
	if spawn_t <= 0:
		_spawn_enemy(_pick_enemy())
		var base: float = max(1.6, 4.8 - stage * 0.12)
		spawn_t = base * randf_range(0.7, 1.3) * (0.8 if t > 90 else 1.0)
	if not rushed and ebase["hp"] < ebase["max"] * 0.5:
		rushed = true
		rush_left = 4
		banner = {"t": 2.0, "txt": "砦の兵が打って出た！"}
	if rush_left > 0:
		rush_t -= dt
		if rush_t <= 0:
			rush_t = 0.35
			rush_left -= 1
			_spawn_enemy(_pick_enemy())
	if stage % 5 == 0 and not boss_spawned and t > 12:
		boss_spawned = true
		_spawn_enemy("seraph")
		banner = {"t": 2.5, "txt": "熾天使 降臨"}

func cast_spell() -> void:
	if over or spell < spell_max:
		return
	spell = 0
	var dmg := roundi(160.0 * pow(1.12, G.T("might")) * (1.0 + 0.3 * G.T("wrath")) * (1.0 + 0.2 * (G.S["max_stage"] - 1)))
	for f in units.filter(func(u): return u.side < 0 and not u.dead):
		pillars.append({"x": f.x, "t": 0.6})
		_damage(f, dmg)
		if G.T("doom") > 0:
			f.kb = 0.6
	if G.T("doom") > 0:
		pillars.append({"x": EBASE_X - 30, "t": 0.6})
		_hit_base(1, dmg)
	flash = 0.4
	shake = 0.3
	banner = {"t": 1.5, "txt": "冥王の裁き"}

func _legion_interval() -> float:
	return [0.0, 14.0, 10.0, 7.0][G.T("legion")]

## 死者の行進・玉座の呪砲
func _passive_tick(dt: float) -> void:
	if G.T("legion") > 0:
		legion_t -= dt
		if legion_t <= 0:
			legion_t = _legion_interval()
			var st := G.unit_stats("skel")
			_add_unit(1, Data.CARDS["skel"], st["hp"], st["atk"], st["spd"], CASTLE_X + 30)
	var cl := G.T("cannon")
	if cl > 0:
		cannon_t -= dt
		if cannon_t <= 0:
			var tgt: Unit = null
			for u in units:
				if u.side < 0 and not u.dead and u.x < CASTLE_X + 320 and (tgt == null or u.x < tgt.x):
					tgt = u
			if tgt:
				cannon_t = 1.6
				var dmg := 22.0 * cl * (1.0 + 0.25 * (stage - 1))
				_damage(tgt, dmg)
				bolts.append({"a": Vector2(CASTLE_X, GROUND - 195), "b": Vector2(tgt.x, GROUND - tgt.h / 2), "t": 0.25})
			else:
				cannon_t = 0.2

# ---------------- ループ ----------------
func _process(delta: float) -> void:
	var dt: float = min(0.05, delta) * speed
	if not over:
		var steps := 2 if speed > 1 else 1
		var sdt := dt / steps
		for s in steps:
			t += sdt
			mana = min(G.max_mana(), mana + G.regen_rate() * sdt)
			spell = min(spell_max, spell + sdt)
			for id in cds:
				cds[id] = max(0.0, cds[id] - sdt)
			_enemy_ai(sdt)
			_passive_tick(sdt)
			for u in units:
				if not u.dead:
					_step_unit(u, sdt)
			for p in proj:
				_step_proj(p, sdt)
			proj = proj.filter(func(p): return not p["done"])
			units = units.filter(func(u): return not u.dead)
		if ebase["hp"] <= 0:
			end_battle(true)
		elif castle["hp"] <= 0 or t >= TIME_LIMIT:
			end_battle(false)
		_update_hud()
	for f in fx:
		f["t"] -= dt
		f["x"] += f["vx"] * dt
		f["y"] += f["vy"] * dt
		f["vy"] += 300 * dt
	fx = fx.filter(func(f): return f["t"] > 0)
	for n in nums:
		n["t"] -= dt
		n["y"] -= 30 * dt
	nums = nums.filter(func(n): return n["t"] > 0)
	for bo in bolts:
		bo["t"] -= dt
	bolts = bolts.filter(func(b): return b["t"] > 0)
	for p in pillars:
		p["t"] -= dt
	pillars = pillars.filter(func(p): return p["t"] > 0)
	shake = max(0.0, shake - dt)
	flash = max(0.0, flash - dt)
	if banner.has("t"):
		banner["t"] -= dt
	queue_redraw()

# ---------------- 描画 ----------------
func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(round(x), round(y), w, h), c)

func _text(s: String, pos: Vector2, size: int, c: Color, align := HORIZONTAL_ALIGNMENT_CENTER, width := 300.0) -> void:
	var p := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		p.x -= width / 2
	draw_string(font, p + Vector2(1, 1), s, align, width, size, Color(0, 0, 0, c.a))
	draw_string(font, p, s, align, width, size, c)

func _draw() -> void:
	var off := Vector2.ZERO
	if shake > 0:
		off = Vector2(randf_range(-3, 3), randf_range(-2, 2))
	draw_set_transform(off)
	draw_texture(bg_tex, Vector2.ZERO)
	_draw_castle()
	_draw_ebase()
	var us := units.duplicate()
	us.sort_custom(func(a, b): return a.lane < b.lane)
	for u: Unit in us:
		var bob := 0.0 if u.anim > 0 else -absf(sin(u.walk)) * 3
		var lunge := u.side * 6.0 if u.anim > 0.12 else 0.0
		var fy := (-18.0 + sin(t * 3 + u.lane) * 4) if u.d.get("fly", false) else 0.0
		var x := roundf(u.x - u.w / 2 + lunge)
		var y := roundf(GROUND - u.h + bob + fy + u.lane * 0.6 - 6)
		_px(u.x - u.w * 0.35, GROUND + u.lane * 0.6 - 4, u.w * 0.7, 4, Color(0, 0, 0, 0.4))
		var mod := Color(1, 1, 1, 0.7 if u.kb > 0 else 1.0)
		if u.hit > 0:
			mod = Color(2, 2, 2, mod.a)
		draw_texture(u.tex, Vector2(x, y), mod)
		if u.hp < u.mx or u.d.get("boss", false):
			var bw: float = 80.0 if u.d.get("boss", false) else max(20.0, u.w * 0.7)
			_px(u.x - bw / 2, y - 6, bw, 3, Color.BLACK)
			_px(u.x - bw / 2, y - 6, round(bw * max(0.0, u.hp) / u.mx), 3, G.C_ACCENT if u.side > 0 else Color("#ffd060"))
	for p in proj:
		var s := 6.0 if p["big"] else 4.0
		_px(p["x"] - s / 2, p["y"] - s / 2, s, s, p["c"])
		_px(p["x"] - s / 2 - p["side"] * 6, p["y"] - s / 2, s, s, Color(p["c"], 0.4))
	if G.T("miasma") > 0:
		_px(CASTLE_X, GROUND - 40, 260, 40, Color(0.45, 0.2, 0.6, 0.12 + 0.05 * sin(t * 2)))
	for bo in bolts:
		draw_line(bo["a"], bo["b"], Color(G.C_ACCENT, bo["t"] * 4), 3)
	for pl in pillars:
		var a: float = min(1.0, pl["t"] * 2)
		_px(pl["x"] - 12, 0, 24, GROUND, Color(Color("#7a3cc0"), a))
		_px(pl["x"] - 4, 0, 8, GROUND, Color(Color("#e0c0ff"), a))
	for f in fx:
		_px(f["x"], f["y"], 3, 3, Color(f["c"], min(1.0, f["t"] * 2)))
	for n in nums:
		_text(n["v"], Vector2(n["x"], n["y"]), 13, Color(n["c"], min(1.0, n["t"] * 2)))
	if flash > 0:
		_px(0, 0, W, H, Color(0.69, 0.49, 1.0, flash))
	draw_set_transform(Vector2.ZERO)
	# HUD
	_bar(16, 12, 220, castle["hp"] / castle["max"], G.C_ACCENT, "骨の玉座 %d/%d" % [max(0, ceil(castle["hp"])), castle["max"]])
	_bar(W - 236, 12, 220, ebase["hp"] / ebase["max"], Color("#ffd060"), "白銀の砦 %d/%d" % [max(0, ceil(ebase["hp"])), ebase["max"]])
	var rem: float = max(0.0, TIME_LIMIT - t)
	_text("%d:%02d" % [int(rem / 60), int(rem) % 60], Vector2(W / 2, 30), 20, G.C_RED if rem < 30 else G.C_TEXT)
	_text("ステージ %d" % stage, Vector2(W / 2, 48), 12, G.C_DIM)
	if banner.has("t") and banner["t"] > 0:
		var a: float = min(1.0, banner["t"])
		_px(0, 110, W, 44, Color(0, 0, 0, 0.55 * a))
		_text(banner["txt"], Vector2(W / 2, 141), 24, Color(Color("#e0c0ff"), a), HORIZONTAL_ALIGNMENT_CENTER, 600)
	if over:
		_px(0, 0, W, H, Color(0, 0, 0, 0.6))
		_text("勝 利" if won else "敗 北", Vector2(W / 2, H / 2), 40, G.C_GOLD if won else G.C_RED)

func _bar(x: float, y: float, w: float, r: float, col: Color, lbl: String) -> void:
	_px(x - 2, y - 2, w + 4, 14, Color(0, 0, 0, 0.6))
	_px(x, y, w, 10, Color("#2a1a2a"))
	_px(x, y, round(w * clamp(r, 0.0, 1.0)), 10, col)
	_text(lbl, Vector2(x, y + 27), 11, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, w)

func _draw_castle() -> void:
	var bx := CASTLE_X - 45
	var hr: float = castle["hp"] / castle["max"]
	_px(bx, GROUND - 150, 90, 150, Color("#2a2036"))
	_px(bx + 6, GROUND - 150, 78, 150, Color("#3a2c4a"))
	for i in 5:
		_px(bx + 4 + i * 18, GROUND - 162, 12, 12, Color("#3a2c4a"))
	_px(bx + 20, GROUND - 210, 50, 62, Color("#2a2036"))
	_px(bx + 26, GROUND - 232, 38, 24, Color("#3a2c4a"))
	_px(bx + 38, GROUND - 252, 14, 20, Color("#3a2c4a"))
	var glow := 0.6 + 0.4 * sin(t * 3)
	var gc := Color(G.C_ACCENT, glow)
	_px(bx + 38, GROUND - 195, 14, 22, gc)
	_px(bx + 16, GROUND - 120, 10, 16, gc)
	_px(bx + 64, GROUND - 120, 10, 16, gc)
	_px(bx + 33, GROUND - 90, 24, 20, Color("#e8e0c8"))
	_px(bx + 37, GROUND - 84, 5, 5, Color("#1a1420"))
	_px(bx + 48, GROUND - 84, 5, 5, Color("#1a1420"))
	_px(bx + 39, GROUND - 70, 12, 6, Color("#e8e0c8"))
	_px(bx + 30, GROUND - 40, 30, 40, Color("#120a18"))
	if hr < 0.5:
		_px(bx + 10, GROUND - 140, 4, 30, Color("#0c0612"))
		_px(bx + 70, GROUND - 60, 4, 24, Color("#0c0612"))

func _draw_ebase() -> void:
	var bx := EBASE_X - 50
	var hr: float = ebase["hp"] / ebase["max"]
	_px(bx, GROUND - 140, 100, 140, Color("#8a8a9a"))
	_px(bx + 6, GROUND - 140, 88, 140, Color("#a8a8b8"))
	for i in 6:
		_px(bx + 2 + i * 17, GROUND - 152, 11, 12, Color("#a8a8b8"))
	_px(bx + 30, GROUND - 200, 40, 62, Color("#a8a8b8"))
	_px(bx + 26, GROUND - 212, 48, 12, G.C_GOLD)
	_px(bx + 46, GROUND - 245, 8, 34, G.C_GOLD)
	_px(bx + 38, GROUND - 235, 24, 8, G.C_GOLD)
	_px(bx + 54, GROUND - 245, 22, 14, Color("#f4f4f4"))
	_px(bx + 38, GROUND - 110, 24, 24, G.C_GOLD)
	_px(bx + 42, GROUND - 106, 16, 16, Color("#f4f0c0"))
	_px(bx + 35, GROUND - 45, 30, 45, Color("#4a3a2a"))
	_px(bx + 40, GROUND - 180, 20, 16, Color(Color("#fff0a0"), (0.5 + 0.5 * sin(t * 2)) * 0.5))
	if hr < 0.5:
		_px(bx + 15, GROUND - 130, 4, 40, Color("#5a5a6a"))
		_px(bx + 80, GROUND - 90, 4, 30, Color("#5a5a6a"))
		_px(bx + 60, GROUND - 60, 14, 4, Color("#5a5a6a"))
	if hr < 0.25:
		_px(bx + 70, GROUND - 150, 16, 12, Color("#1a1018"))
		_px(bx + 4, GROUND - 152, 11, 12, Color("#1a1018"))

func _make_bg() -> ImageTexture:
	var img := Image.create(int(W), int(H), false, Image.FORMAT_RGBA8)
	var top := Color("#07040c")
	var mid := Color("#24123a")
	var bot := Color("#4a1e3a")
	for y in int(GROUND):
		var r := y / GROUND
		var c := top.lerp(mid, r / 0.6) if r < 0.6 else mid.lerp(bot, (r - 0.6) / 0.4)
		img.fill_rect(Rect2i(0, y, int(W), 1), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		var c := G.C_ACCENT if rng.randf() > 0.8 else Color("#d8d0e8")
		img.fill_rect(Rect2i(rng.randi_range(0, int(W / 2)) * 2, rng.randi_range(0, int(GROUND * 0.55 / 2)) * 2, 2, 2), c)
	# 赤い月
	for yy in range(-30, 31, 3):
		for xx in range(-30, 31, 3):
			var d := xx * xx + yy * yy
			if d < 900:
				var c := Color("#d84a5a") if d < 500 else Color("#a8304a")
				if (xx + yy) % 9 == 0 and d < 600:
					c = Color("#b8384c")
				img.fill_rect(Rect2i(640 + xx, 80 + yy, 3, 3), c)
	# 山影
	for layer in [[Color("#1c1028"), 110.0, 30.0, 6, 1.0], [Color("#140a1e"), 70.0, 22.0, 4, 3.0]]:
		var step: int = layer[3]
		for i in range(0, int(W), step):
			var hh: float = layer[1] + sin(i * 0.012 + layer[4]) * layer[2] + sin(i * 0.037 + layer[4] * 2) * layer[2] * 0.4
			img.fill_rect(Rect2i(i, int(GROUND - hh), step, int(hh)), layer[0])
	# 枯れ木と墓標
	var dark := Color("#0c0612")
	var g := int(GROUND)
	for tx in [210, 470, 700]:
		for r in [[tx, g - 70, 6, 70], [tx - 14, g - 55, 14, 4], [tx + 6, g - 45, 16, 4], [tx - 18, g - 63, 4, 10], [tx + 20, g - 53, 4, 12]]:
			img.fill_rect(Rect2i(r[0], r[1], r[2], r[3]), dark)
	for tx in [160, 300, 380, 560, 620, 760]:
		img.fill_rect(Rect2i(tx, g - 14, 8, 14), dark)
		img.fill_rect(Rect2i(tx - 3, g - 10, 14, 3), dark)
	# 地面
	img.fill_rect(Rect2i(0, g, int(W), int(H) - g), Color("#1a1018"))
	for i in range(0, int(W), 4):
		img.fill_rect(Rect2i(i, g, 4, 4), Color("#2a1a24") if (i / 4) % 3 == 0 else Color("#22141e"))
	for i in 160:
		var c := Color("#2a1c26") if rng.randf() > 0.5 else Color("#120a10")
		img.fill_rect(Rect2i(rng.randi_range(0, int(W / 3)) * 3, g + 6 + rng.randi_range(0, int((H - GROUND - 8) / 3)) * 3, 3, 3), c)
	return ImageTexture.create_from_image(img)

# ---------------- 決着 ----------------
func end_battle(win: bool) -> void:
	if over:
		return
	over = true
	won = win
	var S := G.S
	var gain := int(floor(G.win_souls(stage) if win else G.win_souls(stage) * 0.35 * min(1.0, t / 60.0 + 0.3)))
	gain += int(floor(soul_bonus * G.soul_mult()))
	S["souls"] += gain
	var first: bool = win and stage == S["max_stage"]
	core_gain = 2 if first and stage % 5 == 0 else 0
	S["core"] += core_gain
	if win:
		if first:
			S["max_stage"] += 1
		S["stage"] = min(S["max_stage"], stage + 1)
		S["best"] = max(S["best"], S["max_stage"])
	G.save_game()
	_update_hud()
	await get_tree().create_timer(0.9).timeout
	if win:
		_show_reward(gain, int(t), first)
	else:
		var hint := "\nカードや玉座を強化して再挑戦しましょう。"
		if G.rebirth_gain() > 0:
			hint = "\n行き詰まったら「転生」で冥核 +%d を得て、パッシブスキルを解放しましょう。" % G.rebirth_gain()
		elif G.S["core"] > 0:
			hint = "\n冥核が %d あります。「パッシブスキル」タブで新しい力を解放しましょう。" % G.S["core"]
		main.open_modal("敗北…", "戦闘時間 %d秒・撃破 %d\n獲得魂貨 +%s%s" % [int(t), kills, G.fmt(gain), hint], [["玉座へ戻る", main.back_to_hub]])

func _show_reward(gain: int, time: int, first: bool) -> void:
	var S := G.S
	var unowned := []
	for k in Data.CARDS:
		if not S["cards"].has(k):
			unowned.append(k)
	var owned: Array = S["cards"].keys()
	owned.shuffle()
	var relic_keys: Array = Data.RELICS.keys()
	var pool := []
	if unowned.size() > 0:
		unowned.sort_custom(func(a, b): return Data.CARDS[a]["cost"] < Data.CARDS[b]["cost"])
		pool.append({"type": "card", "id": unowned[randi() % min(2, unowned.size())]})
	pool.append({"type": "lv", "id": owned[0]})
	pool.append({"type": "relic", "id": relic_keys.pick_random()})
	if owned.size() > 1:
		pool.append({"type": "lv", "id": owned[1]})
	pool.append({"type": "relic", "id": relic_keys.pick_random()})
	pool.append({"type": "souls", "id": "", "v": int(gain * 0.8)})
	var n := 3 if first else 2
	var opts := []
	var seen := {}
	for o in pool:
		var key: String = o["type"] + o["id"]
		if seen.has(key):
			continue
		seen[key] = true
		opts.append(o)
		if opts.size() >= n:
			break
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for o in opts:
		var b := Button.new()
		b.custom_minimum_size = Vector2(186, 190)
		b.pressed.connect(func(): _take_reward(o))
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var tag := ""
		var title := ""
		var desc := ""
		var tex: Texture2D = null
		match o["type"]:
			"card":
				var c: Dictionary = Data.CARDS[o["id"]]
				tag = "新カード"; title = c["name"]; desc = "%s\n魂力%d" % [c["desc"], c["cost"]]; tex = Data.TEX[c["spr"]]["r"]
			"lv":
				var c: Dictionary = Data.CARDS[o["id"]]
				tag = "カード強化"; title = "%s Lv%d→%d" % [c["name"], S["cards"][o["id"]], S["cards"][o["id"]] + 1]; desc = "無償でレベルアップ"; tex = Data.TEX[c["spr"]]["r"]
			"relic":
				var r: Dictionary = Data.RELICS[o["id"]]
				tag = "遺物"; title = r["name"]; desc = "%s\n（転生まで有効・重複可）" % r["desc"]
			_:
				tag = "魂貨"; title = "+%s 魂貨" % G.fmt(o["v"]); desc = "追加の魂貨"
		var lt := G.label(tag, 11, G.C_ACCENT)
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size.y = 60
		var big := G.label("" if tex else ("◆" if o["type"] == "relic" else "◎"), 34, G.C_GOLD)
		var lt2 := G.label(title, 14, G.C_TEXT)
		var ld := G.label(desc, 11, G.C_DIM)
		ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for c in [lt, tr if tex else big, lt2, ld]:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if c is Label:
				c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(c)
		row.add_child(b)
	main.open_modal("勝利！", "戦闘時間 %d秒・撃破 %d・獲得魂貨 +%s%s\n戦利品をひとつ選べ：" % [time, kills, G.fmt(gain), ("\n新たなステージが開放された。" if first else "") + ("\nボス初撃破！ 冥核 +%d（パッシブスキルの解放に使えます）" % core_gain if core_gain > 0 else "")], [], row)

func _take_reward(o: Dictionary) -> void:
	var S := G.S
	match o["type"]:
		"card":
			S["cards"][o["id"]] = 1
			if S["deck"].size() < 6:
				S["deck"].append(o["id"])
		"lv":
			S["cards"][o["id"]] += 1
		"relic":
			S["relics"].append(o["id"])
		_:
			S["souls"] += o["v"]
	G.save_game()
	main.close_modal()
	main.back_to_hub()
