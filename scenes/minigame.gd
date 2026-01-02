extends Node2D

@onready var duplicity = get_parent()
@onready var logger = get_node("../logger")
@onready var draw_circle_game = $draw_circle_game
@onready var rhythm_game = $rhythm_game
@onready var egg_game = $egg_game

var game = null
var game_map := {}
var result_map := {}
var result = 0 # 1 -> left brain, 2 -> right brain, 3 -> both
	
func _ready() -> void:
	game_map = {
		2: rhythm_game,
		4: draw_circle_game,
		6: egg_game
		# add more as we implement them
	}
	result_map = {
		0: "none",
		1: "left",
		2: "right",
		3: "both"
	}

func run_game(section: int) -> void:
	if section in game_map:
		game = game_map[section]
		logger.log_custom([], "event", "minigame_start", game)
		game.run_game()

func end_game(variant: String, change: int) -> void:
	result = variant
	game = null
	logger.log_custom([], "event", "minigame_end", "")
	duplicity.process_minigame_end(change)

func _process(_delta: float) -> void:
	pass
