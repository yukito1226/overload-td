extends MarginContainer
## 拠点（強化シーン）：カード編成・玉座強化・転生

var main
var lbl_res: Label
var idle_btn: Button
var go_btn: Button
var minus_btn: Button
var plus_btn: Button
var stage_info: Label
var tabs: TabContainer
var deck_box: VBoxContainer
var up_box: VBoxContainer
var reb_box: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, 14)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := HBoxContainer.new()
	root.add_child(title)
	title.add_child(G.label("骸王の行軍", 22, G.C_ACCENT))
	var sub := G.label("　冥王ザルヴァスの亡者軍を率い、白銀教団の砦を落とせ。", 12, G.C_DIM)
	title.add_child(sub)

	# 資源バー
	var bar1 := _bar()
	root.add_child(bar1)
	lbl_res = G.label("", 14)
	lbl_res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar1.get_child(0).add_child(lbl_res)
	idle_btn = G.button("放置収穫", _collect_idle, G.C_GOLD)
	bar1.get_child(0).add_child(idle_btn)

	# 出撃バー
	var bar2 := _bar()
	root.add_child(bar2)
	var h2: HBoxContainer = bar2.get_child(0)
	minus_btn = G.button("◀", func(): G.S["stage"] = max(1, G.S["stage"] - 1); refresh())
	plus_btn = G.button("▶", func(): G.S["stage"] = min(G.S["max_stage"], G.S["stage"] + 1); refresh())
	go_btn = G.button("出撃", _go)
	go_btn.add_theme_font_size_override("font_size", 17)
	go_btn.add_theme_stylebox_override("normal", G.sb(Color("#4a2280"), G.C_ACCENT, 5, 1, 10))
	go_btn.add_theme_stylebox_override("hover", G.sb(Color("#5a2a9a"), Color.WHITE, 5, 1, 10))
	h2.add_child(minus_btn)
	h2.add_child(go_btn)
	h2.add_child(plus_btn)
	stage_info = G.label("", 12, G.C_DIM)
	stage_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h2.add_child(stage_info)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	deck_box = _tab("軍勢（カード）")
	up_box = _tab("玉座の強化")
	reb_box = _tab("転生・冥王の遺志")

	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(func(): if visible: _refresh_bar())
	add_child(t)

func _bar() -> PanelContainer:
	var p := PanelContainer.new()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	return p

func _tab(name_: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = name_
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	sc.add_child(v)
	return v

func _clear(c: Node) -> void:
	for ch in c.get_children():
		ch.queue_free()

# ---------------- 更新 ----------------
func refresh() -> void:
	_refresh_bar()
	_build_deck()
	_build_up()
	_build_reb()

func _refresh_bar() -> void:
	var S := G.S
	lbl_res.text = "魂貨 %s　　冥核 %s　　ステージ %d（今周の最高 %d ／ 歴代 %d）" % [G.fmt(S["souls"]), G.fmt(S["core"]), S["stage"], S["max_stage"], S["best"]]
	idle_btn.text = "放置収穫 +" + G.fmt(G.idle_pending())
	go_btn.text = "出撃：ステージ %d%s" % [S["stage"], "（ボス）" if S["stage"] % 5 == 0 else ""]
	minus_btn.disabled = S["stage"] <= 1
	plus_btn.disabled = S["stage"] >= S["max_stage"]
	stage_info.text = "勝利報酬 約%s魂貨%s" % [G.fmt(G.win_souls(S["stage"])), "（周回）" if S["stage"] < S["max_stage"] else ""]

func _collect_idle() -> void:
	var g := G.idle_pending()
	G.S["souls"] += g
	G.S["last_idle"] = Time.get_unix_time_from_system()
	G.save_game()
	refresh()
	main.toast("放置収穫 +%s 魂貨" % G.fmt(g))

func _go() -> void:
	if G.S["deck"].is_empty():
		main.toast("デッキにカードを入れてください")
		return
	main.start_battle(G.S["stage"])

func _build_deck() -> void:
	_clear(deck_box)
	var S := G.S
	deck_box.add_child(G.label("デッキ %d/6。紫枠がデッキ入り。勝利時の報酬で新しいカードが手に入ります。" % S["deck"].size(), 12, G.C_DIM))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	deck_box.add_child(grid)
	for id in Data.CARDS:
		grid.add_child(_card_widget(id))
	if S["relics"].size() > 0:
		var names := []
		for r in S["relics"]:
			names.append(Data.RELICS[r]["name"])
		var l := G.label("所持遺物（転生でリセット）： " + "、".join(names), 12, G.C_GOLD)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		deck_box.add_child(l)

func _card_widget(id: String) -> Control:
	var S := G.S
	var c: Dictionary = Data.CARDS[id]
	var owned: bool = S["cards"].has(id)
	var in_deck: bool = S["deck"].has(id)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(212, 0)
	p.add_theme_stylebox_override("panel", G.sb(G.C_PANEL, G.C_ACCENT if in_deck else G.C_LINE, 6, 2 if in_deck else 1, 6))
	var v := VBoxContainer.new()
	p.add_child(v)
	var tr := TextureRect.new()
	tr.texture = Data.TEX[c["spr"]]["r"]
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(0, 56)
	v.add_child(tr)
	if not owned:
		tr.modulate = Color(0, 0, 0, 0.6)
		var l := G.label("？？？ 未入手", 13, G.C_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		return p
	var lv: int = S["cards"][id]
	var st := G.unit_stats(id)
	var nm := G.label("%s  Lv%d" % [c["name"], lv], 14, G.C_TEXT)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var cost_col := G.C_RED if c["cost"] > G.max_mana() else G.C_ACCENT
	var cl := G.label("魂力%d　再召喚%.1fs" % [c["cost"], st["cd"]] + ("（魂の器が不足）" if c["cost"] > G.max_mana() else ""), 11, cost_col)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cl)
	var sl := G.label("体力%d 攻撃%d%s\n%s" % [st["hp"], st["atk"], " 範囲" if c.has("aoe") else "", c["desc"]], 11, G.C_DIM)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sl)
	var h := HBoxContainer.new()
	v.add_child(h)
	var b1 := G.button("外す" if in_deck else "編成", func(): _toggle_deck(id))
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(b1)
	var cost := G.card_lv_cost(lv)
	var b2 := G.button("強化 " + G.fmt(cost), func(): _level(id), G.C_GOLD)
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.disabled = S["souls"] < cost
	h.add_child(b2)
	return p

func _toggle_deck(id: String) -> void:
	var d: Array = G.S["deck"]
	if d.has(id):
		d.erase(id)
	elif d.size() < 6:
		d.append(id)
	else:
		main.toast("デッキは6枚まで")
		return
	G.save_game()
	refresh()

func _level(id: String) -> void:
	var c := G.card_lv_cost(G.S["cards"][id])
	if G.S["souls"] < c:
		return
	G.S["souls"] -= c
	G.S["cards"][id] += 1
	G.save_game()
	refresh()

func _row(title: String, desc: String, btn: Button, border := G.C_LINE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", G.sb(G.C_PANEL, border, 6, 1, 8))
	var h := HBoxContainer.new()
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(G.label(title, 14))
	var d := G.label(desc, 12, G.C_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	btn.custom_minimum_size.x = 130
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	return p

func _build_up() -> void:
	_clear(up_box)
	up_box.add_child(G.label("魂貨で玉座を強化します（転生でリセット）。", 12, G.C_DIM))
	for k in Data.UPS:
		var u: Dictionary = Data.UPS[k]
		var cost := G.up_cost(k)
		var b := G.button(G.fmt(cost) + " 魂貨", func(): _buy_up(k), G.C_GOLD)
		b.disabled = G.S["souls"] < cost
		up_box.add_child(_row("%s  Lv%d" % [u["name"], G.S["up"][k]], u["desc"], b))
	up_box.add_child(G.label("現在：魂力回復 %d/秒・上限 %d・玉座耐久 %d・魂貨倍率 ×%.2f" % [G.regen_rate(), G.max_mana(), G.castle_hp(), G.soul_mult()], 12, G.C_DIM))

func _buy_up(k: String) -> void:
	var cost := G.up_cost(k)
	if G.S["souls"] < cost:
		return
	G.S["souls"] -= cost
	G.S["up"][k] += 1
	G.save_game()
	refresh()

func _build_reb() -> void:
	_clear(reb_box)
	var g := G.rebirth_gain()
	var rb := G.button("転生 +%d 冥核" % g, _rebirth, G.C_ACCENT)
	rb.disabled = g <= 0
	reb_box.add_child(_row("転生の儀",
		"魂貨・ステージ・カード・強化・遺物をすべて失い、冥核を得て最初からやり直します。今周の最高ステージが高いほど多く得られます（ステージ6到達で解放）。転生回数：%d" % G.S["rebirths"],
		rb, G.C_ACCENT))
	reb_box.add_child(G.label("冥王の遺志：冥核で獲得する永続強化（転生しても失われません）。", 12, G.C_DIM))
	for k in Data.TALENTS:
		var t: Dictionary = Data.TALENTS[k]
		var cost := G.T(k) + 1
		var b := G.button("%d 冥核" % cost, func(): _buy_talent(k))
		b.disabled = G.S["core"] < cost
		reb_box.add_child(_row("%s  Lv%d" % [t["name"], G.T(k)], t["desc"], b))
	var wipe := G.button("セーブデータを消去", func(): main.confirm("本当に消去しますか？", "すべての進行状況（冥核・遺志を含む）が消えます。", func(): G.wipe(); refresh()), G.C_RED)
	wipe.size_flags_horizontal = Control.SIZE_SHRINK_END
	reb_box.add_child(wipe)

func _rebirth() -> void:
	var g := G.rebirth_gain()
	main.confirm("転生しますか？", "冥核 +%d を得て、ステージ1からやり直します。カード・強化・遺物・魂貨は失われます。" % g, func():
		G.S["core"] += g
		G.S["rebirths"] += 1
		G.fresh_run(G.S)
		G.S["last_idle"] = Time.get_unix_time_from_system()
		G.save_game()
		refresh()
		main.toast("転生した。冥核 +%d" % g))

func _buy_talent(k: String) -> void:
	var c := G.T(k) + 1
	if G.S["core"] < c:
		return
	G.S["core"] -= c
	G.S["talents"][k] = G.T(k) + 1
	G.save_game()
	refresh()
