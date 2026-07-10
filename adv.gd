extends Control
# 薄いビジュアルノベル・プレイヤー（素材無し・名前＋テキストのみ）。
# 台本は res://adv/<script_key>.json（{ "lines": [{ "name":.., "text":.. }, ...] }）。
# タップで進み、最後まで行くとメニューへ戻る。

static var script_key := "philosophy"

const W := 720.0
const H := 1280.0
var lines: Array = []
var idx := 0
var name_label: Label
var text_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := _rect(Vector2.ZERO, Vector2(W, H), Color(0.07, 0.07, 0.10))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect(Vector2(40, H - 430), Vector2(W - 80, 370), Color(0, 0, 0, 0.55))    # テキスト窓
	name_label = _label(Vector2(70, H - 410), "", 30)
	name_label.modulate = Color(0.5, 0.85, 1.0)
	text_label = _label(Vector2(70, H - 350), "", 30)
	text_label.size = Vector2(W - 140, 270)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hint := _label(Vector2(0, H - 44), "タップで進む   R=メニュー", 20)
	hint.size = Vector2(W, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.4)
	_load()
	_show()


func _load() -> void:
	var f := FileAccess.open("res://adv/%s.json" % script_key, FileAccess.READ)
	if f == null:
		lines = [{ "name": "", "text": "(台本が読めませんでした: %s)" % script_key }]
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY and data.has("lines"):
		lines = data["lines"]


func _show() -> void:
	if idx >= lines.size():
		get_tree().change_scene_to_file("res://menu.tscn")
		return
	var ln: Dictionary = lines[idx]
	name_label.text = ln.get("name", "")
	text_label.text = ln.get("text", "")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_R:
		get_tree().change_scene_to_file("res://menu.tscn")
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed:
		advance = true
	elif event is InputEventScreenTouch and event.pressed:
		advance = true
	elif event is InputEventKey and event.pressed:
		advance = true
	if advance:
		idx += 1
		_show()


func _rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _label(pos: Vector2, text: String, fsize: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l
