extends Node2D

@onready var area_2d = $Area2D
@onready var pencil = $pencil
@onready var collision_shape = $Area2D/CollisionShape2D

var canvas_rect: Rect2
var is_mouse_in_canvas = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pencil.visible = true
	
	# Calculate canvas boundaries
	var shape = collision_shape.shape as RectangleShape2D
	var area_pos = area_2d.global_position
	canvas_rect = Rect2(area_pos - shape.size / 2, shape.size)
	
	# Connect Area2D signals
	area_2d.mouse_entered.connect(_on_mouse_entered)
	area_2d.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	is_mouse_in_canvas = true

func _on_mouse_exited():
	is_mouse_in_canvas = false
	# Warp mouse back to canvas when it tries to leave
	var mouse_pos = get_global_mouse_position()
	var constrained_pos = Vector2(
		clamp(mouse_pos.x, canvas_rect.position.x, canvas_rect.end.x),
		clamp(mouse_pos.y, canvas_rect.position.y, canvas_rect.end.y)
	)
	warp_mouse(constrained_pos)


func warp_mouse(target_position: Vector2):
	var viewport = get_viewport()
	var local_pos = viewport.get_screen_transform().affine_inverse() * target_position
	viewport.warp_mouse(local_pos)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
