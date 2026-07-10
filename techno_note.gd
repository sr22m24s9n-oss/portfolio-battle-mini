extends Control
class_name TechnoNote

# 軽量なテクノ風ノーツ。譜面側はレーン番号だけ渡し、見た目はこの部品に集約する。
const LANE_COLORS := [
	Color("43e7ff"),
	Color("ff4fd8"),
	Color("9dff57"),
]

var note_color := LANE_COLORS[0]


func setup(lane: int) -> void:
	note_color = LANE_COLORS[clampi(lane, 0, LANE_COLORS.size() - 1)]
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var pulse := 0.74 + sin(Time.get_ticks_msec() * 0.009) * 0.12
	var glow := Rect2(2, 8, size.x - 4, size.y - 16)
	var body := Rect2(8, 14, size.x - 16, size.y - 28)
	var core := Rect2(18, 23, size.x - 36, 6)

	# 判定線とは異なる厚みを持つ、横長の電子パルスバー。
	draw_rect(glow, Color(note_color, 0.18 * pulse), true)
	draw_rect(body, Color(0.01, 0.02, 0.03, 0.94), true)
	draw_rect(body, Color(note_color, 0.95), false, 4.0, true)
	draw_rect(core, Color(note_color, pulse), true)
	draw_rect(Rect2(size.x * 0.5 - 18, 18, 36, 16), Color(1.0, 1.0, 1.0, 0.88), true)
	draw_line(Vector2(18, size.y * 0.5), Vector2(4, size.y * 0.5), note_color, 4.0, true)
	draw_line(Vector2(size.x - 18, size.y * 0.5), Vector2(size.x - 4, size.y * 0.5), note_color, 4.0, true)


func _process(_delta: float) -> void:
	queue_redraw()
