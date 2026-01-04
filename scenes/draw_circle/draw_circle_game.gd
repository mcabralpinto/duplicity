extends Node2D

@onready var minigame = get_parent()
@onready var left = $draw_circle_left

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_visibility(false)

func set_visibility(visibility: bool) -> void:
	self.visible = visibility

func run_game() -> void:
	set_visibility(true)
	left.start_game()

func end_game(variant: String, change: int) -> void:
	set_visibility(false)
	# ensure the child stops its timers to avoid stray callbacks
	if left and left.has_method("stop_game"):
		left.stop_game()
	minigame.end_game(variant, change)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
