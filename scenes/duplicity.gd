extends Node2D

@onready var caption = $caption
@onready var minigame = $minigame

var section := 1
var line := 0

func _ready() -> void:
	caption.set_visibility(true)
	caption.set_text(section, line)

func process_minigame_end() -> void:
	section += 1
	line = 0
	caption.caption_map[section] += char(ord('a') - 1 + minigame.result)
	caption.set_text(section, line)
	caption.set_visibility(true)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and caption.visible:
		#print(not caption.full_display, line < caption.lines[caption.caption_map[section]].size(), section not in minigame.game_map, not minigame.game)
		if not caption.full_display:
			caption.finish_animation()
		else:
			line += 1
			if line < caption.lines[caption.caption_map[section]].size():
				caption.set_text(section, line)
			else:
				if section not in minigame.game_map:
					section += 1
					if section > caption.caption_map.size():
						print(section)
						# implement game end logic here
						caption.set_visibility(false)
					else:
						line = 0
						caption.set_text(section, line)
				else:
					caption.set_visibility(false)
					minigame.run_game(section)
