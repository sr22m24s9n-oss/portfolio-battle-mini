extends Control
# レーン防衛リズム — 遊べる音ゲー（通常譜面＋直近プレイの痕跡譜面）
# プレイ中のタップをそのまま保存し、次回用の「痕跡譜面」にする。
# 間引き・拍寄せ・範囲制限は掛けない＝タップの痕跡そのものが譜面（エディット譜面として使える）。
# 玉のレーンをタイミングよく叩く: ライン近く=GOOD / 少し外れ=BAD / 取り逃し=MISS(HP減)。
# 曲を守り抜けばCLEAR、HP0でGAME OVER。

static var play_mode := "base"
const TechnoNoteScene := preload("res://techno_note.gd")

# --- 調律ノブ ---
const W := 720.0
const H := 1280.0
const LANES := 3
const BASE_Y := 1120.0
const SPAWN_Y := -80.0
const BPM := 140.0
const OFFSET := 0.08
const TOTAL_BEATS := 180
const BASE_APPROACH_TIME := 3.6
const SPEED_SLOW_PREVIEW := 150.0 # previous base speed: 1200px / 150px = 8.0s.
const SPEED := (BASE_Y - SPAWN_Y) / BASE_APPROACH_TIME
const CAST_CD := 0.08         # 連打の最小間隔
const START_HP := 10
const GOOD_WINDOW := 50.0     # 判定ラインからの距離(px): これ以内=GOOD
const BAD_WINDOW := 110.0     # これ以内=BAD、超えて通過=MISS
const SCORE_GOOD := 100
const SCORE_BAD := 40
# 生成ルール（人の設計則をルール化）
const GAP_THRESHOLD := 1.1    # 間隔がこれ超=別レーンへ移動 / 以下=同レーン保持
const MAX_BURST := 4          # 同レーン保持はこの数で打ち切り(一本道防止)
const MODE_BASE := "base"
const MODE_TRACE := "trace"
const TRACE_RUN_PATH := "user://trace_run_latest.json"
const TRACE_CHART_PATH := "user://trace_chart_latest.json"
const TRACE_APPROACH_TIME_FAST_PREVIEW := 1.8 # previous quick preview value; keep for easy revert.
const TRACE_APPROACH_TIME_SLOW_PREVIEW := 8.0
const TRACE_APPROACH_TIME := BASE_APPROACH_TIME

# --- 状態 ---
var beat_interval := 60.0 / BPM
var beats := 0
var lane_x: Array[float] = []
var enemies: Array = []          # [{ rect, lane }]
var cast_cd := 0.0
var playing := true
var hp := START_HP
var score := 0
var combo := 0
var max_combo := 0
var last_spawn_t := -100.0
var last_gen_lane := -1
var gen_burst := 0
var chart_mode := MODE_BASE
var using_trace_chart := false
var trace_missing := false
var chart_notes: Array = []
var next_chart_index := 0
var run_notes: Array = []
var run_taps: Array = []
var run_note_id := 0
var trace_chart_written := false

# --- ノード ---
var beat_dot: ColorRect
var progress: ColorRect
var hp_label: Label
var score_label: Label
var combo_label: Label
var end_label: Label
var audio: AudioStreamPlayer
var song_length := 0.0


func _ready() -> void:
	seed(20260709)                     # 生成チャートを固定（毎回同じ譜面＝覚えて上達できる）
	chart_mode = play_mode
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in LANES:
		lane_x.append(W * (i * 2 + 1) / float(LANES * 2))
	_load_selected_chart()
	_build_field()
	_start_music()


func _load_selected_chart() -> void:
	using_trace_chart = false
	trace_missing = false
	chart_notes.clear()
	next_chart_index = 0
	if chart_mode != MODE_TRACE:
		return
	var f := FileAccess.open(TRACE_CHART_PATH, FileAccess.READ)
	if f == null:
		trace_missing = true
		chart_mode = MODE_BASE
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY or not data.has("notes"):
		trace_missing = true
		chart_mode = MODE_BASE
		return
	var raw_notes: Variant = data["notes"]
	if typeof(raw_notes) != TYPE_ARRAY or raw_notes.is_empty():
		trace_missing = true
		chart_mode = MODE_BASE
		return
	chart_notes = raw_notes.duplicate(true)
	chart_notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("spawn_time", a.get("target_time", 0.0))) < float(b.get("spawn_time", b.get("target_time", 0.0)))
	)
	using_trace_chart = true


func _start_music() -> void:
	audio = AudioStreamPlayer.new()
	audio.stream = load("res://audio/kyrgyz_techno_anthem.ogg")
	add_child(audio)
	if audio.stream != null:
		song_length = audio.stream.get_length()
		audio.finished.connect(_on_song_end)
		audio.play()


func _song_time() -> float:
	return audio.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()


func _build_field() -> void:
	_rect(Vector2.ZERO, Vector2(W, H), Color.BLACK)
	for i in range(1, LANES):
		_rect(Vector2(W * i / LANES - 1, 0), Vector2(2, H), Color(1, 1, 1, 0.05))
	_rect(Vector2(0, BASE_Y), Vector2(W, 4), Color(0.3, 0.9, 0.9, 0.85))         # 判定ライン
	progress = _rect(Vector2.ZERO, Vector2(0, 6), Color(0.9, 0.8, 0.4))
	beat_dot = _rect(Vector2(W / 2 - 10, 16), Vector2(20, 20), Color(1, 1, 1, 0.2))
	hp_label = _label(Vector2(16, 20), "HP %d" % hp, 28)
	score_label = _label(Vector2(W - 216, 20), "0", 28)
	score_label.size = Vector2(200, 34)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label = _label(Vector2(0, BASE_Y - 280), "", 40)
	combo_label.size = Vector2(W, 50)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.modulate = Color(1, 1, 1, 0.85)
	end_label = _label(Vector2(0, H / 2 - 90), "", 44)
	end_label.size = Vector2(W, 200)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.visible = false
	var mode_text := "痕跡譜面" if using_trace_chart else "通常譜面"
	if trace_missing:
		mode_text = "通常譜面（痕跡なし）"
	var mode_label := _label(Vector2(0, 62), mode_text, 20)
	mode_label.size = Vector2(W, 28)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.modulate = Color(1, 1, 1, 0.48)
	var hint := _label(Vector2(0, H - 44), "玉のレーンをタイミングよく叩く   R=やり直し   P=撮影", 22)
	hint.size = Vector2(W, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.4)


func _process(delta: float) -> void:
	if not playing:
		return
	cast_cd = maxf(0.0, cast_cd - delta)
	beat_dot.modulate.a = maxf(0.2, beat_dot.modulate.a - delta * 3.0)
	# 拍を曲の再生位置に同期（湧きと拍脈のTier0）
	var t: float = _song_time()
	var target_beat := int((t - OFFSET) / beat_interval)
	while beats < target_beat:
		_on_beat()
	if using_trace_chart:
		_spawn_due_chart_notes(t)
	# 玉を連続で降ろす ＋ 通過(Miss)判定
	for e in enemies:
		if e.has("hit_t"):
			e.rect.position.y = _chart_note_y(e, t)
		else:
			e.rect.position.y += SPEED * delta
	for e in enemies.duplicate():
		if not playing:
			break
		if e.rect.position.y - BASE_Y > BAD_WINDOW:
			_miss(e)
	if song_length > 0.0:
		progress.size.x = W * clampf(t / song_length, 0.0, 1.0)


func _on_beat() -> void:
	beats += 1
	beat_dot.modulate.a = 1.0
	if using_trace_chart:
		return
	var cadence := maxi(2, 5 - beats / 30)
	if beats < TOTAL_BEATS and beats % cadence == 0:
		_spawn_generated()


func _spawn_due_chart_notes(t: float) -> void:
	while next_chart_index < chart_notes.size():
		var note: Dictionary = chart_notes[next_chart_index]
		var spawn_t := float(note.get("spawn_time", float(note.get("target_time", 0.0)) - TRACE_APPROACH_TIME))
		if t < spawn_t:
			return
		_spawn_chart_note(note)
		next_chart_index += 1


func _chart_note_y(e: Dictionary, t: float) -> float:
	var spawn_t := float(e.get("spawn_t", t))
	var hit_t := float(e.get("hit_t", spawn_t + TRACE_APPROACH_TIME))
	if t <= hit_t:
		var span := maxf(0.001, hit_t - spawn_t)
		var p := clampf((t - spawn_t) / span, 0.0, 1.0)
		return lerpf(SPAWN_Y, BASE_Y, p)
	return BASE_Y + (t - hit_t) * SPEED


func _spawn_generated() -> void:
	# 間隔が広い(移動できる)=別レーンへランダム / 狭い(密集)=同レーン保持。保持はMAX_BURSTで打切り。
	var st := _song_time()
	var lane: int
	if last_gen_lane < 0 or (st - last_spawn_t) > GAP_THRESHOLD or gen_burst >= MAX_BURST:
		lane = randi() % LANES
		while lane == last_gen_lane:
			lane = randi() % LANES
		gen_burst = 1
	else:
		lane = last_gen_lane
		gen_burst += 1
	last_gen_lane = lane
	last_spawn_t = st
	_spawn(lane)


func _spawn(lane: int) -> void:
	var spawn_t := _song_time()
	var hit_t := spawn_t + ((BASE_Y - SPAWN_Y) / SPEED)
	var r := _techno_note(lane, Vector2(lane_x[lane] - 85, SPAWN_Y))
	enemies.append({ "rect": r, "lane": lane })
	_record_note(lane, spawn_t, hit_t)


func _spawn_chart_note(note: Dictionary) -> void:
	var lane := clampi(int(note.get("lane", 1)), 0, LANES - 1)
	var hit_t := float(note.get("target_time", note.get("t", 0.0)))
	var spawn_t := float(note.get("spawn_time", hit_t - TRACE_APPROACH_TIME))
	var r := _techno_note(lane, Vector2(lane_x[lane] - 85, SPAWN_Y))
	enemies.append({ "rect": r, "lane": lane, "hit_t": hit_t, "spawn_t": spawn_t })
	_record_note(lane, spawn_t, hit_t)


func _record_note(lane: int, spawn_t: float, hit_t: float) -> void:
	run_note_id += 1
	run_notes.append({
		"id": run_note_id,
		"lane": lane,
		"locked": false,
		"spawn_time": spawn_t,
		"target_time": hit_t
	})


func _record_tap(lane: int) -> void:
	run_taps.append({
		"lane": lane,
		"time": _song_time()
	})


func _cast(lane: int) -> void:
	if cast_cd > 0.0:
		return
	cast_cd = CAST_CD
	_flash(lane)
	# そのレーンで判定ラインに一番近い玉を狙う
	var target: Variant = null
	for e in enemies:
		if e.lane == lane and (target == null or abs(e.rect.position.y - BASE_Y) < abs(target.rect.position.y - BASE_Y)):
			target = e
	if target == null:
		return
	var dist: float = abs(target.rect.position.y - BASE_Y)
	if dist > BAD_WINDOW:
		return  # 遠すぎ＝空振り（ペナルティなし）
	var good := dist <= GOOD_WINDOW
	enemies.erase(target)
	target.rect.queue_free()
	score += SCORE_GOOD if good else SCORE_BAD
	combo += 1
	max_combo = maxi(max_combo, combo)
	_popup(lane_x[lane], "GOOD" if good else "BAD", Color(0.4, 0.95, 0.6) if good else Color(0.95, 0.75, 0.35))
	_update_hud()


func _miss(e: Dictionary) -> void:
	enemies.erase(e)
	e.rect.queue_free()
	hp -= 1
	combo = 0
	_popup(lane_x[e.lane], "MISS", Color(0.95, 0.4, 0.4))
	_update_hud()
	if hp <= 0:
		_finish(false)


func _update_hud() -> void:
	hp_label.text = "HP %d" % maxi(hp, 0)
	score_label.text = str(score)
	combo_label.text = ("%d COMBO" % combo) if combo >= 3 else ""


func _popup(x: float, text: String, col: Color) -> void:
	var l := _label(Vector2(x - 70, BASE_Y - 110), text, 34)
	l.size = Vector2(140, 44)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.modulate = col
	var tw := create_tween()
	tw.parallel().tween_property(l, "position:y", BASE_Y - 175, 0.45)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.45)
	tw.tween_callback(l.queue_free)


func _flash(lane: int) -> void:
	var f := _rect(Vector2(W * lane / LANES, 0), Vector2(W / LANES, BASE_Y), Color(0.4, 0.9, 1.0, 0.20))
	var tw := create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.2)
	tw.tween_callback(f.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_R:
		get_tree().reload_current_scene()
		return
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_P:
		_capture()
		return
	var pos := Vector2.INF
	if event is InputEventMouseButton and event.pressed:
		pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and event.pressed:
		pos = (event as InputEventScreenTouch).position
	if pos == Vector2.INF:
		return
	if not playing:
		get_tree().change_scene_to_file("res://menu.tscn")   # 結果画面のタップ＝メニューへ戻る
		return
	var lane := clampi(int(pos.x / (W / LANES)), 0, LANES - 1)
	_record_tap(lane)
	_cast(lane)


func _on_song_end() -> void:
	if playing:
		_finish(true)


func _finish(win: bool) -> void:
	playing = false
	_save_trace_run(win)
	trace_chart_written = _build_trace_chart_from_taps()
	for e in enemies:
		e.rect.queue_free()
	enemies.clear()
	combo_label.visible = false            # 終了時はコンボ表示を消す（結果画面を綺麗に）
	end_label.visible = true
	if win:
		end_label.text = "CLEAR\n\nスコア %d\n最大コンボ %d\n%s\n\nタップでメニュー" % [score, max_combo, _trace_result_text()]
		end_label.modulate = Color(0.4, 0.92, 0.92)
	else:
		end_label.text = "GAME OVER\n\nスコア %d\n%s\n\nタップでメニュー" % [score, _trace_result_text()]
		end_label.modulate = Color(0.95, 0.45, 0.45)


func _trace_result_text() -> String:
	if trace_chart_written:
		return "痕跡譜面を更新"
	return "痕跡なし"


func _save_trace_run(win: bool) -> void:
	var data := {
		"song": "kyrgyz_techno_anthem",
		"mode": chart_mode,
		"bpm": BPM,
		"offset": OFFSET,
		"duration": song_length,
		"score": score,
		"max_combo": max_combo,
		"clear": win,
		"notes": run_notes,
		"taps": run_taps
	}
	_save_json(TRACE_RUN_PATH, data)


func _build_trace_chart_from_taps() -> bool:
	# タップを一切加工せず全件を譜面化する（間引き・拍寄せ・開始終了の除外なし）。
	var notes: Array = []
	for tap in run_taps:
		var target_t := maxf(0.0, float((tap as Dictionary).get("time", 0.0)))
		notes.append({
			"id": notes.size() + 1,
			"lane": clampi(int((tap as Dictionary).get("lane", 1)), 0, LANES - 1),
			"spawn_time": maxf(0.0, target_t - TRACE_APPROACH_TIME),
			"target_time": target_t
		})
	if notes.is_empty():
		return false
	var chart := {
		"song": "kyrgyz_techno_anthem",
		"audio": "res://audio/kyrgyz_techno_anthem.ogg",
		"source": TRACE_RUN_PATH,
		"method": "raw tap trace (no filter, no snap)",
		"bpm": BPM,
		"offset": OFFSET,
		"approach_time": TRACE_APPROACH_TIME,
		"tap_count": run_taps.size(),
		"note_count": notes.size(),
		"notes": notes
	}
	_save_json(TRACE_CHART_PATH, chart)
	return true


func _save_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("trace save failed: %s" % path)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var dir_abs := ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_recursive_absolute(dir_abs)
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir_abs + "/shot_%d.png" % int(Time.get_unix_time_from_system()))


# --- helpers ---
func _rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _techno_note(lane: int, pos: Vector2) -> TechnoNote:
	var note := TechnoNoteScene.new() as TechnoNote
	note.position = pos
	note.size = Vector2(170, 54)
	note.setup(lane)
	add_child(note)
	return note


func _label(pos: Vector2, text: String, fsize: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l
