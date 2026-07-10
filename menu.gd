extends Control
# ハブ: 開発ADV、通常プレイ、直近の痕跡譜面プレイを選ぶ

const AdvScene := preload("res://adv.gd")   # 台本キーの受け渡し(static var)
const GameScene := preload("res://main.gd") # プレイモードの受け渡し(static var)
const MENU_BACKGROUND := preload("res://assets/menu_techno_background.png")
const W := 720.0
const H := 1280.0
const OPTIONS := [
	{ "label": "このゲームの開発の考え方", "action": "adv:philosophy" },
	{ "label": "Claudeとの実際のやり取り", "action": "adv:dialogue" },
	{ "label": "ChatGPTとの実際のやり取り", "action": "adv:chatgpt" },
	{ "label": "ゲームをプレイ", "action": "game" },
	{ "label": "痕跡譜面で遊ぶ", "action": "trace" },
	{ "label": "おわり", "action": "quit" },
]


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = MENU_BACKGROUND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.48)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var title := _label(Vector2(0, 210), "開発ノート", 64, HORIZONTAL_ALIGNMENT_CENTER)
	title.size = Vector2(W, 90)
	var sub := _label(Vector2(0, 310), "レーン防衛リズム — 制作の記録", 26, HORIZONTAL_ALIGNMENT_CENTER)
	sub.size = Vector2(W, 40)
	sub.modulate = Color(1, 1, 1, 0.55)
	var y := 470.0
	for opt in OPTIONS:
		var b := Button.new()
		b.text = opt["label"]
		b.position = Vector2(90, y)
		b.size = Vector2(W - 180, 86)
		b.add_theme_font_size_override("font_size", 29)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_stylebox_override("normal", _button_style(Color(0.02, 0.03, 0.05, 0.78), Color(0.25, 0.9, 1.0, 0.38)))
		b.add_theme_stylebox_override("hover", _button_style(Color(0.04, 0.08, 0.12, 0.9), Color(0.35, 0.95, 1.0, 0.8)))
		b.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.02, 0.09, 0.94), Color(1.0, 0.3, 0.85, 0.9)))
		b.pressed.connect(_on_pick.bind(opt["action"]))
		add_child(b)
		y += 108


func _on_pick(action: String) -> void:
	if action == "quit":
		if OS.has_feature("web"):
			# Web版はタブを強制的に閉じられないため、作品紹介のトップへ戻す。
			JavaScriptBridge.eval("window.location.href = '../';")
		else:
			get_tree().quit()
	elif action == "game":
		GameScene.play_mode = "base"
		get_tree().change_scene_to_file("res://main.tscn")
	elif action == "trace":
		GameScene.play_mode = "trace"
		get_tree().change_scene_to_file("res://main.tscn")
	elif action.begins_with("adv:"):
		AdvScene.script_key = action.substr(4)
		get_tree().change_scene_to_file("res://adv.tscn")


func _label(pos: Vector2, text: String, fsize: int, align: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	return style
