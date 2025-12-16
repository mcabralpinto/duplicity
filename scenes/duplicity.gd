extends Node2D

@onready var caption = $caption
@onready var minigame = $minigame
@onready var logger = $logger
@onready var interview_scene = $interview_scene
@onready var main_frame = $main_frame
@onready var minigame_bg = $minigame_bg

var section := 0
var line := 0
var score := 0

func _ready() -> void:
	interview_scene.z_index = 10
	main_frame.z_index = 20
	minigame_bg.z_index = -20
	
	if section != 0:
		caption.set_visibility(true)
		caption.set_text(section, line)

func process_minigame_end(change: int) -> void:
	section += 1
	logger.log_custom([section, line, score], "state", "section", str(section))
	line = 0
	logger.log_custom([section, line, score], "state", "line", str(line))
	score += change
	logger.log_custom([section, line, score], "state", "score_change", str(change))
	logger.log_custom([section, line, score], "state", "score", str(score))
	caption.caption_map[section] += minigame.result
	logger.log_custom([section, line, score], "state", "chat_variant", str(minigame.result))
	caption.set_text(section, line)
	#caption.set_visibility(true)

func _process(_delta: float) -> void:
	if section == 0 and Input.is_action_pressed("ui_accept") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and caption.visible:
		section = 1
		logger.log_custom([section, line, score], "state", "section", str(section))
		logger.log_custom([section, line, score], "event", "game_start", "")
		caption.set_visibility(true)
		caption.set_text(section, line)
	if Input.is_action_pressed("ui_accept") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and caption.visible:
		if Input.is_action_just_pressed("ui_accept") or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not was_mouse_pressed):
			if not caption.full_display:
				caption.finish_animation()
			else:
				line += 1
				logger.log_custom([section, line, score], "state", "line", str(line))
				if line < caption.lines[caption.caption_map[section]].size():
					caption.set_text(section, line)
				else:
					if section not in minigame.game_map: 
						section += 1
						logger.log_custom([section, line, score], "state", "section", str(section))
						if section > caption.caption_map.size():
							print(section)
							# implement game end logic here
							logger.log_custom([section, line, score], "event", "game_end", "")
							get_tree().quit()
							#caption.set_visibility(false)
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
						#caption.set_visibility(false)
						minigame.run_game(section)
	
	# Helper to track mouse state for "just pressed" logic in _process
	was_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

var was_mouse_pressed = false
	
func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed and not (event is InputEventKey and event.echo):
		logger.log_custom([section, line, score], "action", "press", event.as_text())
