extends Node2D

@onready var rhythm_game = get_parent()
@onready var background = $background
@onready var static_dot = $dot
@onready var score_label = $score_label

# Game parameters (base values)
var spawn_interval = 0.4
var score_per_hit = 10
var score_penalty = 5
var min_speed = 100.0
var max_speed = 300.0
var min_scale = 0.9
var max_scale = 2.1

# Widening (chaos) parameters
var widen_delay = 5.0
var widen_duration = 40.0 # seconds to reach final targets

# Spawn-interval targets (the window will move toward these)
var spawn_interval_min_target = 0.1
var spawn_interval_max_target = 0.3

# Speed targets (window will widen: min decreases, max increases)
var speed_min_target = 50.0
var speed_max_target = 600.0

# Current dynamic ranges (computed each frame)
var current_spawn_min = spawn_interval
var current_spawn_max = spawn_interval
var current_min_speed = min_speed
var current_max_speed = max_speed

# State
var spawn_timer = 0.0
var active_dots = []
var score = 0
var screen_size = Vector2.ZERO
var elapsed_time = 0.0

func _ready() -> void:
	randomize()
	# Hide the template dot
	if static_dot:
		static_dot.visible = false
	
	if score_label:
		score_label.visible = true
		score_label.modulate = Color.BLACK
	
	screen_size = get_viewport_rect().size
	# initialize dynamic ranges
	current_spawn_min = spawn_interval
	current_spawn_max = spawn_interval
	current_min_speed = min_speed
	current_max_speed = max_speed
	update_score_label()

func _process(delta: float) -> void:
	if not rhythm_game.visible:
		return

	elapsed_time += delta
	_update_dynamic_windows()

	# 1. Spawn dots
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_dot()
		# use current dynamic spawn range
		spawn_timer = randf_range(current_spawn_min, current_spawn_max)

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

func _update_dynamic_windows() -> void:
	# Keep base values until delay elapsed
	if elapsed_time <= widen_delay:
		current_spawn_min = spawn_interval
		current_spawn_max = spawn_interval
		current_min_speed = min_speed
		current_max_speed = max_speed
		return

	var t = clamp((elapsed_time - widen_delay) / max(widen_duration, 0.0001), 0.0, 1.0)
	# For spawn interval we lerp from base spawn_interval to the target min/max (moving toward faster spawn)
	current_spawn_min = lerp(spawn_interval, spawn_interval_min_target, t)
	current_spawn_max = lerp(spawn_interval, spawn_interval_max_target, t)
	# For speed we lerp from base min/max to the targets (min down, max up -> wider)
	current_min_speed = lerp(min_speed, speed_min_target, t)
	current_max_speed = lerp(max_speed, speed_max_target, t)

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
	
	# Random velocity and direction, sample speed from current dynamic speed window
	var random_angle = randf() * TAU # TAU is 2*PI
	var random_speed = randf_range(current_min_speed, current_max_speed)
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
