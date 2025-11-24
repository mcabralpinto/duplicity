extends Node2D

@onready var minigame = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_visibility(false)

func set_visibility(visibility: bool) -> void:
	self.visible = visibility

func run_game() -> void:
	set_visibility(true)

func end_game(result_val: int) -> void:
	set_visibility(false)
	minigame.end_game(result_val)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
