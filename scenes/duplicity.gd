extends Node2D

@onready var caption = $caption
@onready var minigame = $minigame
@onready var logger = $logger
@onready var interview_scene = $interview_scene
@onready var main_frame = $main_frame
@onready var minigame_bg = $minigame_bg
@onready var left_label = $left_label
@onready var right_label = $right_label
@onready var coxinha = $coxinha
@onready var waiting_room = $waiting_room


var section := 0
var line := 0
var score := 0

# false = space turn, true = mouse turn
var mouse_turn := false
var was_mouse_pressed := false
var was_y_pressed := false
var game_on = false

# pre-start confirmations
var left_confirmed := false
var right_confirmed := false
var prestart_waiting := false

func _ready() -> void:
	game_on = false
	interview_scene.z_index = 10
	main_frame.z_index = 21
	minigame_bg.z_index = -20
	left_label.z_index = -19
	right_label.z_index = -19
	coxinha.z_index = 11
	waiting_room.z_index = 11

	var font = load("res://assets/PixelatedElegance.ttf")

	left_label.add_theme_font_size_override("font_size", 20)
	left_label.add_theme_font_override("font", font)

	right_label.z_index = 41
	right_label.add_theme_font_size_override("font_size", 20)
	right_label.add_theme_font_override("font", font)
	
	# start: caption hidden, labels show initial confirm instructions (both active/white)
	caption.set_visibility(false)
	left_label.visible = true
	right_label.visible = true
	left_label.text = "Left Player uses the keyboard\n[Y] to confirm"
	right_label.text = "Right Player uses the mouse\n[LMOUSE] to confirm"
	var white = Color(1, 1, 1)
	left_label.modulate = white
	right_label.modulate = white

	update_turn_visuals()

func update_turn_visuals() -> void:
	var white = Color(1, 1, 1)
	var gray = Color(0.4, 0.4, 0.4)
	# during normal dialogue, indicate active side; if both labels are meant to be white (pre-start), they are set elsewhere
	if caption.visible:
		if mouse_turn:
			# mouse turn: left gray, right white
			left_label.modulate = gray
			right_label.modulate = white
		else:
			# space turn: left white, right gray
			left_label.modulate = white
			right_label.modulate = gray

func toggle_turn() -> void:
	mouse_turn = not mouse_turn
	update_turn_visuals()

# Animate waiting_room scale up over 5s then hide it.
func animate_waiting_room() -> void:
	minigame_bg.z_index = 20
	left_label.z_index = 21
	right_label.z_index = 21
	waiting_room.visible = true
	var start_scale = waiting_room.scale
	var target_scale = start_scale * 500

	var tween = get_tree().create_tween()
	# first phase: slow start (ease in) to mid point
	var mid_scale = start_scale + (target_scale - start_scale) * 0.8
	tween.tween_property(waiting_room, "scale", mid_scale, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# second phase: speed up to full target (continues accelerating)
	#tween.tween_property(waiting_room, "scale", target_scale, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await tween.finished
	waiting_room.visible = false
	waiting_room.scale = start_scale
	minigame_bg.z_index = -20
	left_label.z_index = -19
	right_label.z_index = -19

# Start the waiting_room sequence: caption hidden, animate immediately,
# after 1s show section (dialogue begins), animation runs for 5s total.
func start_waiting_room_sequence() -> void:
	caption.set_visibility(false)
	# start animation asynchronously
	animate_waiting_room()
	# after 1s, start section dialogue
	await get_tree().create_timer(3).timeout
	caption.set_visibility(true)
	caption.set_text(section, line)

# pre-start: after both confirmations, wait 2s then change labels to skip messages and show caption for section 0
func start_prestart_sequence() -> void:
	prestart_waiting = true
	await get_tree().create_timer(2).timeout
	# restore skip texts and visuals, start section 0 dialogue
	left_label.text = "[SPACEBAR] to skip"
	right_label.text = "[LMOUSE] to skip"
	var white = Color(1, 1, 1)
	left_label.modulate = white
	right_label.modulate = white
	caption.set_visibility(true)
	caption.set_text(section, line)
	# reset confirmation flags so normal turn logic applies
	left_confirmed = false
	right_confirmed = false
	prestart_waiting = false
	update_turn_visuals()

func process_minigame_end(change: int) -> void:
	section += 1
	print(section)
	logger.log_custom([section, line, score], "state", "section", str(section))
	line = 0
	logger.log_custom([section, line, score], "state", "line", str(line))
	score += change
	logger.log_custom([section, line, score], "state", "score_change", str(change))
	logger.log_custom([section, line, score], "state", "score", str(score))
	caption.caption_map[section] += minigame.result
	logger.log_custom([section, line, score], "state", "chat_variant", str(minigame.result))
	caption.set_text(section, line)
	caption.set_visibility(true)
	left_label.visible = true
	right_label.visible = true
	game_on = false
	update_turn_visuals()

func _process(_delta: float) -> void:
	if game_on:
		return 

	# update mouse pressed helper early so "just pressed" detection works
	var mouse_pressed_now = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var y_pressed_now = Input.is_key_pressed(KEY_Y)
	
	# pre-start confirmations (section 0, caption hidden)
	if section == 0 and not caption.visible and not prestart_waiting:
		# left confirm via Y (detect just-press by comparing previous state)
		if not left_confirmed and y_pressed_now and not was_y_pressed:
			left_confirmed = true
			left_label.modulate = Color(0.4, 0.4, 0.4)
		# right confirm via mouse left
		if not right_confirmed and mouse_pressed_now and not was_mouse_pressed:
			right_confirmed = true
			right_label.modulate = Color(0.4, 0.4, 0.4)
		if left_confirmed and right_confirmed:
			start_prestart_sequence()
		# update helper and continue
		was_mouse_pressed = mouse_pressed_now
		was_y_pressed = y_pressed_now
		return

	# update mouse pressed helper early so "just pressed" detection works
	# mouse_pressed_now already set above; keep current value

	if not caption.visible:
		was_mouse_pressed = mouse_pressed_now
		return

	# determine active input type for this turn
	var active_pressed := false
	var was_just_pressed := false
	if mouse_turn:
		active_pressed = mouse_pressed_now
		was_just_pressed = active_pressed and not was_mouse_pressed
	else:
		active_pressed = Input.is_action_pressed("ui_accept")
		was_just_pressed = Input.is_action_just_pressed("ui_accept")

	# remember previous line to decide whether to toggle turn
	var prev_line := line

	# (removed old special-start behavior; section 0 now begins after prestart sequence)

	if active_pressed:
		if was_just_pressed:
			if not caption.full_display:
				caption.finish_animation()
			else:
				line += 1
				if line < caption.lines[caption.caption_map[section]].size():
					caption.set_text(section, line)
					print(section, line, caption.caption_map[section])
					if caption.caption_map[section] == "pre4" and line == 4:
						coxinha.visible = true
					logger.log_custom([section, line, score], "state", "line", str(line))
				else:
					if section not in minigame.game_map:
						if section == 0:
							start_waiting_room_sequence()
						section += 1
						logger.log_custom([section, line, score], "state", "section", str(section))
						if section > caption.caption_map.size():
							print(section)
							# implement game end logic here
							logger.log_custom([section, line, score], "event", "game_end", "")
							get_tree().quit()
						else:
							if caption.caption_map[section] == "outro":
								if score > 0:
									caption.caption_map[section] += "b"
								else:
									caption.caption_map[section] += "a"
							line = 0
							logger.log_custom([section, line, score], "state", "line", str(line))
							caption.set_text(section, line)
					else:
						left_label.visible = false
						right_label.visible = false
						if section == 8:
							caption.set_visibility(false)
						game_on = true
						minigame.run_game(section)
		# toggle only if the line actually changed
		if was_just_pressed and prev_line != line:
			toggle_turn()

	# update was_mouse_pressed for next frame
	was_mouse_pressed = mouse_pressed_now
	was_y_pressed = y_pressed_now

func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed and not (event is InputEventKey and event.echo):
		logger.log_custom([section, line, score], "action", "press", event.as_text())

func get_score() -> int:
	return score
