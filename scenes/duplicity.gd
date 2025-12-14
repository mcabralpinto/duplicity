extends Node2D

@onready var caption = $caption
@onready var minigame = $minigame
@onready var logger = $logger

var section := 0
var line := 0
var score := 0

func _ready() -> void:
	if section != 0:
		caption.set_visibility(true)
		caption.set_text(section, line)

func process_minigame_end(change: int) -> void:
	section += 1
	logger.log_custom([section, line, score], "state", "section", str(section))
	line = 0
	score += change
	logger.log_custom([section, line, score], "state", "line", str(line))
	caption.caption_map[section] += minigame.result
	caption.set_text(section, line)
	caption.set_visibility(true)

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
							caption.set_visibility(false)
						else:
							line = 0
							logger.log_custom([section, line, score], "state", "line", str(line))
							caption.set_text(section, line)
					else:
						caption.set_visibility(false)
						minigame.run_game(section)
	
	# Helper to track mouse state for "just pressed" logic in _process
	was_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

var was_mouse_pressed = false
	
func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed and not (event is InputEventKey and event.echo):
		logger.log_custom([section, line, score], "action", "press", event.as_text())
