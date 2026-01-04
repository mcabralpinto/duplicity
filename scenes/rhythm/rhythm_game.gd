extends Node2D

@onready var minigame = get_parent()
@onready var right_game = $right
@onready var left_game = $left

var change = 0
var variant = ""
var game_timer: Timer
var _running: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_visibility(false)
	
	game_timer = Timer.new()
	game_timer.wait_time = 45.0
	game_timer.one_shot = true
	game_timer.timeout.connect(Callable(self, "_on_game_timer_timeout"))
	left_game.set_widen_duration(40.0)
	add_child(game_timer)

func set_visibility(visibility: bool) -> void:
	self.visible = visibility

func run_game() -> void:
	print("Game started")
	# prevent multiple concurrent runs/starts
	if _running:
		return
	print("(s) passed running")
	_running = true
	set_visibility(true)
	game_timer.start()

func _on_game_timer_timeout() -> void:
	print("Game ended")
	# guard so this path only runs once per run_game
	if not _running:
		return
	_running = false
	print("(e) passed running")

	if left_game.score > 100 and right_game.score > 100:
		change = 5
		variant = "a"
		if left_game.score + right_game.score > 350:
			change = 10
			variant = "b"
	else:
		change = -5
		variant = "c"
	
	game_timer.stop()
	print("visibility: " + str(self.visible))
	set_visibility(false)
	print("called_minigame")
	minigame.end_game(variant, change)

func _process(_delta: float) -> void:
	pass
