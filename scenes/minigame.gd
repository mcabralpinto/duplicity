extends Node2D

@onready var duplicity = get_parent()
@onready var draw_circle_game = $draw_circle_game

var game = null
var game_map = {}
var result = 0 # 1 -> left brain, 2 -> right brain, 3 -> both
	
func _ready() -> void:
	game_map = {
		2: draw_circle_game
		# add more as we implement them
	}

func run_game(section: int) -> void:
	if section in game_map:
		game = game_map[section]
		game.run_game()

func end_game(result_val: int) -> void:
	result = result_val
	game = null
	duplicity.process_minigame_end()

func _process(_delta: float) -> void:
	pass
