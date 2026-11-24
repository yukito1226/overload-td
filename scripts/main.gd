extends Control
## 画面遷移（拠点 ⇄ バトル）とモーダル表示

const HubScript := preload("res://scripts/hub.gd")
const BattleScript := preload("res://scripts/battle.gd")

var hub: Control
var battle: Node2D
var modal_layer: CanvasLayer
var modal_root: Control

func _ready() -> void:
	theme = G.make_theme()
	var bg := ColorRect.new()
	bg.color = G.C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	hub = HubScript.new()
	hub.main = self
	add_child(hub)

	modal_layer = CanvasLayer.new()
	modal_layer.layer = 10
	add_child(modal_layer)

	hub.refresh()
	if not G.S.get("intro", false):
		G.S["intro"] = true
		G.save_game()
		open_modal("骸王の行軍",
			"冥王ザルヴァスよ、白銀教団が墓所を焼き払いに来る。\n\n"
			+ "・出撃：カードで亡者を召喚し、敵の砦を落とす（1戦30秒〜3分）\n"
			+ "・強化：戦いで得た魂貨でカードと玉座を強化\n"
			+ "・戦利品：勝利ごとに新カード・遺物・強化から選択\n"
			+ "・放置収穫：離れている間も魂貨が溜まる（最大8時間）\n"
			+ "・転生：行き詰まったらすべてを捨て、冥核で永続強化",
			[["始める", Callable()]])

func start_battle(stage: int) -> void:
	hub.visible = false
	battle = BattleScript.new()
	battle.main = self
	battle.stage = stage
	add_child(battle)
	move_child(battle, hub.get_index() + 1)

func back_to_hub() -> void:
	if battle:
		battle.queue_free()
		battle = null
	hub.visible = true
	hub.refresh()

# ---------------- モーダル ----------------
## buttons: [[ラベル, Callable], ...]  Callableが空なら閉じるだけ
func open_modal(title: String, body: String, buttons: Array, extra: Control = null) -> void:
	close_modal()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.theme = theme
	modal_layer.add_child(dim)
	modal_root = dim

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", G.sb(G.C_PANEL2, G.C_ACCENT, 8, 1, 16))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(G.label(title, 20, G.C_ACCENT))
	if body != "":
		var b := G.label(body, 13, G.C_DIM)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = 580
		v.add_child(b)
	if extra:
		v.add_child(extra)
	if buttons.size() > 0:
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_END
		h.add_theme_constant_override("separation", 8)
		v.add_child(h)
		for pair in buttons:
			var cb: Callable = pair[1]
			var btn := G.button(pair[0], func():
				close_modal()
				if cb.is_valid():
					cb.call())
			h.add_child(btn)

func close_modal() -> void:
	if modal_root and is_instance_valid(modal_root):
		modal_root.queue_free()
	modal_root = null

func confirm(title: String, body: String, yes: Callable) -> void:
	open_modal(title, body, [["やめる", Callable()], ["実行", yes]])

var _toast: Label
func toast(msg: String) -> void:
	if not _toast or not is_instance_valid(_toast):
		_toast = G.label("", 14, Color.WHITE)
		_toast.add_theme_stylebox_override("normal", G.sb(Color("#2a1840"), G.C_ACCENT, 6, 1, 8))
		_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var layer := CanvasLayer.new()
		layer.layer = 20
		add_child(layer)
		layer.add_child(_toast)
	_toast.text = msg
	_toast.reset_size()
	_toast.position = Vector2((960 - _toast.size.x) / 2.0, 560)
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.3)
