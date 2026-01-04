extends Node2D

@onready var duplicity = get_parent()
@onready var logger = get_node("../logger")
@onready var draw_circle_game = $draw_circle_game
@onready var rhythm_game = $rhythm_game
@onready var egg_game = $egg_game
@onready var call_game = $call_game
@onready var q1 = $q1
@onready var q2 = $q2

var game = null
var game_map := {}
var question := {}
var result = 0
var section = 0
var already_joked = false
	
func _ready() -> void:
	game_map = {
		2: rhythm_game,
		4: draw_circle_game,
		6: q2,
		8: call_game,
		10: egg_game,
		12: q1
	}
	question = {
		6: 2,
		12: 1
	}

func run_game(_section: int) -> void:
	section = _section
	if section in game_map:
		game = game_map[section]
		print(game)
		logger.log_custom([], "event", "minigame_start", game)
		# mark the start of this run so end_game can correlate duplicates
		game.run_game()

func end_game(variant: String, change: int) -> void:
	# guard so end logic only runs once per run

	result = variant
	if section in [6, 12]:
		if result == "a" and not already_joked:
			result = "a1"
			already_joked = true
		elif result == "a" and already_joked:
			result = "a2"
			change = -20
	game = null
	logger.log_custom([], "event", "minigame_end", "")
	duplicity.process_minigame_end(change)

func _process(_delta: float) -> void:
	pass
