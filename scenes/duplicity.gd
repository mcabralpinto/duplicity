extends Node2D

@onready var caption = $caption
@onready var minigame = $minigame
@onready var logger = $logger
@onready var interview = $interview_scene
@onready var main_frame = $main_frame
@onready var minigame_bg = $minigame_bg
@onready var left_label = $left_label
@onready var right_label = $right_label
@onready var coxinha = $coxinha
@onready var waiting_room = $waiting_room
@onready var player = $player
@onready var player2 = $player2
@onready var open_door = $open_door

var section := 10
var line := 0
var score := 0
var player2_saved_pos: float = 0.0

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
	interview.z_index = -1
	main_frame.z_index = 21
	minigame_bg.z_index = -20
	left_label.z_index = -19
	right_label.z_index = -19
	coxinha.z_index = -21
	waiting_room.z_index = 11
	coxinha.play("idle")

	var font = load("res://assets/PixelatedElegance.ttf")

	left_label.add_theme_font_size_override("font_size", 20)
	left_label.add_theme_font_override("font", font)

	# connect caption finished signal to set interview to idle via duplicity
	if caption.has_method("connect"):
		caption.connect("finished_caption", Callable(self, "_on_caption_finished"))

	minigame.call_game.connect("started_caption", Callable(self, "_on_caption_started"))
	minigame.call_game.connect("finished_caption", Callable(self, "_on_caption_finished"))

	right_label.z_index = 41
	right_label.add_theme_font_size_override("font_size", 20)
	right_label.add_theme_font_override("font", font)
	
	# start: caption hidden, labels show initial confirm instructions (both active/white)
	if section == 0:
		caption.set_visibility(false)
		left_label.visible = true
		right_label.visible = true
		left_label.text = "Left Player uses the keyboard\n[Y] to confirm"
		right_label.text = "Right Player uses the mouse\n[LMOUSE] to confirm"
		waiting_room.visible = true
		var white = Color(1, 1, 1)
		left_label.modulate = white
		right_label.modulate = white

	update_turn_visuals()

	# start background intro music if an AudioPlayer2d named "player" exists
	if player:
		if section == 0:
			var intro_stream = load("res://sounds/music/intro.mp3")
			if intro_stream:
				player.connect("finished", Callable(self,"_on_loop_sound").bind(player))
				player.stream = intro_stream
				player.volume_db = -2
				player.play()
		else:
			var stream = load("res://sounds/music/interview.wav")
			if stream:
				player2.connect("finished", Callable(self,"_on_loop_sound").bind(player2))
				player2.stream = stream
				player2.volume_db = 5
				player2.play()

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
	#waiting_room.visible = true
	var start_scale = waiting_room.scale
	var target_scale = start_scale * 500

	var stream = load("res://sounds/music/interview.wav")
	if stream:
		player2.connect("finished", Callable(self,"_on_loop_sound").bind(player2))
		player2.stream = stream
		player2.play()

	var tween = get_tree().create_tween()
	# first phase: slow start (ease in) to mid point
	var mid_scale = start_scale + (target_scale - start_scale) * 1
	tween.tween_property(waiting_room, "scale", mid_scale, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var tween2 = get_tree().create_tween()
	var target_pos = interview.position - Vector2(450, 115)
	tween2.tween_property(interview, "position", target_pos, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
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
	interview.section_animation(section, line)
	# stop intro music when waiting_room sequence ends
	if player:
		player.stop()

	update_turn_visuals()

# pre-start: after both confirmations, wait 2s then change labels to skip messages and show caption for section 0
func start_prestart_sequence() -> void:
	prestart_waiting = true
	await get_tree().create_timer(1.0).timeout
	# Animate interview node sliding right by 100 units
	var start_pos = interview.position
	var target_pos = start_pos + Vector2(550, 115)
	var tween = get_tree().create_tween()
	tween.tween_property(interview, "position", target_pos, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# After 1 second, switch waiting_room sprite to waiting3.png
	await get_tree().create_timer(1.0).timeout
	var door = load("res://sounds/sfx/intro/open_door.mp3")
	if door:
		open_door.stream = door
		open_door.volume_db = 10
		open_door.play()
	var tex = load("res://assets/waiting_n2.png")
	if tex:
		waiting_room.texture = tex

	# After another 1 second, start prelude (show skip labels, caption, etc)
	await get_tree().create_timer(1.0).timeout
	left_label.text = "[SPACEBAR] to skip"
	right_label.text = "[LMOUSE] to skip"
	var white = Color(1, 1, 1)
	left_label.modulate = white
	right_label.modulate = white
	caption.set_visibility(true)
	caption.set_text(section, line)
	interview.section_animation(section, line)
	# reset confirmation flags so normal turn logic applies
	left_confirmed = false
	right_confirmed = false
	prestart_waiting = false
	update_turn_visuals()

func process_minigame_end(change: int) -> void:
	section += 1
	#print(section)
	logger.log_custom([section, line, score], "state", "section", str(section))
	line = 0
	logger.log_custom([section, line, score], "state", "line", str(line))
	score += change
	logger.log_custom([section, line, score], "state", "score_change", str(change))
	logger.log_custom([section, line, score], "state", "score", str(score))
	caption.caption_map[section] += minigame.result
	interview.animation_map[section] += minigame.result
	logger.log_custom([section, line, score], "state", "chat_variant", str(minigame.result))
	caption.set_text(section, line)
	interview.section_animation(section, line)
	caption.set_visibility(true)
	left_label.visible = true
	right_label.visible = true
	game_on = false

	# resume background interview music (if any) from saved position
	var random_offset = randf() * player2.stream.get_length()
	player2.play(random_offset)

	update_turn_visuals()

func _process(_delta: float) -> void:
	interview.z_index = -1
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

	if active_pressed:
		if was_just_pressed:
			if not caption.full_display:
				caption.finish_animation()
			else:
				line += 1
				print(section, " ", line, " ", caption.caption_map.size())
				if line < caption.lines[caption.caption_map[section]].size():
					caption.set_text(section, line)
					interview.section_animation(section, line)
					#print(section, line, caption.caption_map[section])
					logger.log_custom([section, line, score], "state", "line", str(line))
				else:
					if section not in minigame.game_map:
						if section == 0:
							start_waiting_room_sequence()
						section += 1
						if section == caption.caption_map.size():
							logger.log_custom([section, line, score], "event", "game_end", "")
							get_tree().quit()
						logger.log_custom([section, line, score], "state", "section", str(section))							
						# Special sequence for section 15: play interview getting_up/gone, show caption, then getting_down
						if section == 15:
							game_on = true
							left_label.modulate = Color(0.4, 0.4, 0.4)
							right_label.modulate = Color(0.4, 0.4, 0.4)
							caption.label.text = ""
							caption.shadow_label.text = ""
							# play getting_up and wait, then set gone
							interview.section_animation(15, 0)
							await get_tree().create_timer(6.0).timeout
							coxinha.play("speaking")
							caption.set_text(15, 0)
							await get_tree().create_timer(2.0).timeout
							caption.label.text = ""
							caption.shadow_label.text = ""
							await get_tree().create_timer(2.8).timeout
							var start_pos = coxinha.position
							var target_pos = start_pos - Vector2(400, 0)
							var tween = get_tree().create_tween()
							tween.tween_property(coxinha, "position", target_pos, 4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
							await tween.finished
							await get_tree().create_timer(0.8).timeout
							coxinha.play("speaking")
							caption.set_text(15, 1)
							await get_tree().create_timer(3.0).timeout
							coxinha.play("speaking")
							caption.set_text(15, 2)
							await get_tree().create_timer(3.0).timeout
							coxinha.play("speaking_int")
							caption.set_text(15, 3)
							await get_tree().create_timer(3.0).timeout
							coxinha.play("speaking_int")
							caption.set_text(15, 4)
							await get_tree().create_timer(5.0).timeout
							coxinha.play("idle")
							caption.label.text = ""
							caption.shadow_label.text = ""
							await get_tree().create_timer(5.4).timeout
							target_pos = start_pos
							start_pos = coxinha.position
							tween = get_tree().create_tween()
							tween.tween_property(coxinha, "position", target_pos, 4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
							await tween.finished
							await get_tree().create_timer(2.1).timeout
							interview.section_animation(15, 1)
							await get_tree().create_timer(2.0).timeout
							section += 1
							line = 0
							logger.log_custom([section, line, score], "state", "section", str(section))
							update_turn_visuals()
							game_on = false
							if score >= 0:
								caption.caption_map[section] += "b"
								interview.animation_map[section] += "b"
							else:
								caption.caption_map[section] += "a"
								interview.animation_map[section] += "a"
							caption.set_text(section, line)
						else:
							line = 0
							logger.log_custom([section, line, score], "state", "line", str(line))
							caption.set_text(section, line)
							if section != 1:
								interview.section_animation(section, line)
								
					else:
						left_label.visible = false
						right_label.visible = false
						if section == 8:
							caption.set_visibility(false)
						# stop background interview music and save its playback position
						if section not in [6, 12]:
							player2.stop()
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

func _on_caption_started() -> void:
	interview.set_animation("speaking")

func _on_caption_finished() -> void:
	if section != 15:
		if interview.has_method("set_animation"):
			interview.set_animation("idle")
		if caption.caption_map[section] == "pre4" and line == 4:
			coxinha.visible = true
	else:
		if coxinha.animation == "speaking_int":
			coxinha.play("idle_int")
		else:
			coxinha.play("idle")

func get_score() -> int:
	return score

func _on_loop_sound(p):
	p.play()
