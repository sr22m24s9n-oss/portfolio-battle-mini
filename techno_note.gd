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
	var center := size * 0.5
	var pulse := 0.94 + sin(Time.get_ticks_msec() * 0.009) * 0.04
	var outer_radius := minf(size.x, size.y) * 0.44 * pulse
	var ring_radius := outer_radius * 0.72
	var core_radius := outer_radius * 0.34

	# 黒背景でも輪郭が沈まない、薄い発光層。
	draw_circle(center, outer_radius, Color(note_color, 0.14))
	draw_arc(center, outer_radius * 0.88, 0.0, TAU, 48, Color(note_color, 0.72), 4.0, true)
	draw_arc(center, ring_radius, 0.0, TAU, 48, Color.WHITE, 3.0, true)
	draw_circle(center, core_radius, note_color)
	draw_circle(center, core_radius * 0.43, Color(1.0, 1.0, 1.0, 0.92))

	# 電子パルスを思わせる4本の短い目盛り。
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var from := center + Vector2.from_angle(angle) * outer_radius * 0.91
		var to := center + Vector2.from_angle(angle) * outer_radius * 1.08
		draw_line(from, to, Color(note_color, 0.9), 3.0, true)


func _process(_delta: float) -> void:
	queue_redraw()
