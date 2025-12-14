extends Node2D

@onready var rhythm_game = get_parent()
@onready var background = $background
@onready var static_dot = $dot
@onready var score_label = $score_label

# Game parameters
var spawn_interval = 0.4
var score_per_hit = 10
var score_penalty = 5
var min_speed = 100.0
var max_speed = 300.0
var min_scale = 0.9
var max_scale = 2.1

# State
var spawn_timer = 0.0
var active_dots = []
var score = 0
var screen_size = Vector2.ZERO

func _ready() -> void:
	# Hide the template dot
	if static_dot:
		static_dot.visible = false
	
	if score_label:
		score_label.visible = true
		score_label.modulate = Color.BLACK
	
	screen_size = get_viewport_rect().size
	update_score_label()

func _process(delta: float) -> void:
	if not rhythm_game.visible:
		return

	# 1. Spawn dots
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_dot()
		spawn_timer = spawn_interval

	# 2. Move dots and handle borders
	# Iterate backwards to safely remove items
	for i in range(active_dots.size() - 1, -1, -1):
		var dot = active_dots[i]
		var velocity = dot.get_meta("velocity", Vector2.ZERO)
		
		dot.position += velocity * delta
		
		# Check if dot is outside screen bounds
		if not get_viewport_rect().has_point(dot.position):
			active_dots.remove_at(i)
			dot.queue_free()
			change_score(-score_penalty)

func spawn_dot() -> void:
	if not static_dot:
		return

	var dot_instance = static_dot.duplicate()
	dot_instance.visible = true
	
	# Calculate spawn area based on background (top quarter)
	# Assuming background is a ColorRect or Sprite covering the top area
	var bg_rect = background.get_rect()
	
	# Random position within the background bounds with padding
	var min_x = bg_rect.end.x - 200
	var max_x = bg_rect.end.x + 300
	var min_y = bg_rect.end.y - 200
	var max_y = bg_rect.end.y + 300
	
	var random_x = randf_range(min_x, max_x)
	var random_y = randf_range(min_y, max_y)
	dot_instance.position = Vector2(random_x, random_y)
	
	# Random velocity and direction
	var random_angle = randf() * TAU # TAU is 2*PI
	var random_speed = randf_range(min_speed, max_speed)
	var velocity = Vector2(cos(random_angle), sin(random_angle)) * random_speed
	
	dot_instance.set_meta("velocity", velocity)
	
	# Random color
	dot_instance.modulate = Color(randf(), randf(), randf())
	
	# Random scale
	var random_scale = randf_range(min_scale, max_scale)
	dot_instance.scale = Vector2(random_scale, random_scale)
	
	add_child(dot_instance)
	active_dots.append(dot_instance)

func _input(event: InputEvent) -> void:
	if not rhythm_game.visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		background.modulate = Color(randf(), randf(), randf()) 
		var mouse_pos = get_global_mouse_position()
		
		# Check if we clicked a dot
		for i in range(active_dots.size() - 1, -1, -1):
			var dot = active_dots[i]
			
			# Simple distance check for clicking (assuming dot radius approx 30px)
			# Adjust hit radius based on scale
			var hit_radius = 30.0 * dot.scale.x
			if dot.global_position.distance_to(mouse_pos) < hit_radius:
				active_dots.remove_at(i)
				dot.queue_free()
				change_score(score_per_hit)
				return # Only click one at a time
		
		change_score(-score_penalty)

func change_score(amount: int) -> void:
	score += amount
	update_score_label()

func update_score_label() -> void:
	score_label.text = str(score)
