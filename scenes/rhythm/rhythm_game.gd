extends Node2D

@onready var minigame = get_parent()
@onready var right_game = $right
@onready var left_game = $left

var change = 0
var variant = ""
var game_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_visibility(false)
	
	game_timer = Timer.new()
	game_timer.wait_time = 30.0
	game_timer.one_shot = true
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)

func set_visibility(visibility: bool) -> void:
	self.visible = visibility

func run_game() -> void:
	set_visibility(true)
	game_timer.start()

func _on_game_timer_timeout() -> void:
	if left_game.score > 100 and right_game.score > 100:
		change = 5
		variant = "a"
		if left_game.score + right_game.score > 350:
			change = 10
			variant = "b"
	else:
		change = -5
		variant = "c"
	set_visibility(false)
	minigame.end_game(variant, change)	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
