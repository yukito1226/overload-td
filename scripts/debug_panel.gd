extends CanvasLayer
## デバッグパネル（F1で開閉）。--debug 起動時かエディタ実行時だけ有効。
## 通常とは別のセーブ（user://necrothrone_save_debug.json）を使うので、遊びのデータは壊れない。

var main
var panel: PanelContainer
var stage_spin: SpinBox

func _ready() -> void:
	layer = 15
	var tag := G.label("DEBUG  F1：パネル", 11, Color("#ffd060"))
	tag.position = Vector2(480 - 55, 62)
	add_child(tag)

	panel = PanelContainer.new()
	panel.theme = main.theme
	panel.add_theme_stylebox_override("panel", G.sb(Color(0.05, 0.03, 0.08, 0.95), Color("#ffd060"), 6, 1, 8))
	panel.position = Vector2(960 - 430, 70)
	panel.visible = false
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	v.add_child(G.label("デバッグ", 15, Color("#ffd060")))

	var g := _section(v, "― 資源・進行 ―")
	_btn(g, "魂貨 ×100（+1万）", func(): G.S["souls"] = max(10000.0, G.S["souls"] * 100.0))
	_btn(g, "冥核 +50", func(): G.S["core"] += 50)
	_btn(g, "欠片 ×100（+1000）", func(): G.S["shards"] = max(1000.0, G.S["shards"] * 100.0))
	_btn(g, "全遺物を発見", func():
		for k in Data.RELICS:
			if G.rl(k) == 0:
				G.S["relic_lv"][k] = 1)
	_btn(g, "全カード入手", _all_cards)
	_btn(g, "全カード Lv+5", func():
		for k in G.S["cards"]:
			G.S["cards"][k] += 5)
	_btn(g, "パッシブを全て最大に", func():
		for k in Data.PASSIVES:
			G.S["talents"][k] = int(Data.PASSIVES[k]["max"]))
	_btn(g, "パッシブを全てリセット", func(): G.S["talents"] = {})

	v.add_child(G.label("― ステージ ―", 11, G.C_DIM))
	var h := HBoxContainer.new()
	v.add_child(h)
	stage_spin = SpinBox.new()
	stage_spin.min_value = 1
	stage_spin.max_value = 200
	stage_spin.value = G.S["stage"]
	stage_spin.custom_minimum_size.x = 90
	h.add_child(stage_spin)
	var go := G.button("で出撃", _go_stage)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(go)

	g = _section(v, "― バトル中 ―")
	_btn(g, "即勝利", func(): _battle(func(b): b.ebase["hp"] = 0))
	_btn(g, "即敗北", func(): _battle(func(b): b.castle["hp"] = 0))
	_btn(g, "魂力を満タン", func(): _battle(func(b): b.mana = G.max_mana()))
	_btn(g, "再召喚の待ち時間を0に", func(): _battle(func(b):
		for id in b.cds:
			b.cds[id] = 0.0))
	_btn(g, "冥王の裁きをチャージ", func(): _battle(func(b): b.spell = b.spell_max))
	_btn(g, "速度 ×4", func(): _battle(func(b): b.speed = 4))

	g = _section(v, "― その他 ―")
	_btn(g, "デバッグ用セーブを初期化", func(): G.wipe(); G.S["intro"] = true)

func _section(v: VBoxContainer, title: String) -> GridContainer:
	v.add_child(G.label(title, 11, G.C_DIM))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	v.add_child(g)
	return g

func _btn(parent: Control, text: String, cb: Callable) -> void:
	var b := G.button(text, func():
		cb.call()
		G.save_game()
		_refresh())
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size.x = 196
	parent.add_child(b)

func _refresh() -> void:
	if main.hub.visible:
		main.hub.refresh()

func _battle(cb: Callable) -> void:
	if main.battle and not main.battle.over:
		cb.call(main.battle)

func _all_cards() -> void:
	for k in Data.CARDS:
		if not G.S["cards"].has(k):
			G.S["cards"][k] = 1

func _go_stage() -> void:
	var s := int(stage_spin.value)
	G.S["max_stage"] = max(G.S["max_stage"], s)
	G.S["stage"] = s
	G.save_game()
	panel.visible = false
	main.close_modal()
	if main.battle:
		main.back_to_hub()
	main.start_battle(s)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F1:
		panel.visible = not panel.visible
		stage_spin.value = G.S["stage"]
		get_viewport().set_input_as_handled()
