extends Node2D

@onready var rhythm_game = get_parent()
@onready var static_dot = $dot
@onready var score_label = $score_label
@onready var bg = $bg
@onready var player = $player

# Game parameters (base values)
var speed = 200.0
var spawn_interval = 0.75 # base/spawn at start
var hit_window = 50.0
var failure_point = -30.0 # X position where a ball is considered missed
var score_per_hit = 10
var score_penalty = 5

# Widening (chaos) parameters
var widen_delay = 5.0 # seconds before widening starts
var widen_duration = 40.0 # seconds to reach final targets (t in [0,1]); increase to stretch time-to-target

# Define final target ranges (these are the min/max the windows will widen to)
var spawn_interval_min_target = 0.2
var spawn_interval_max_target = 0.6
var speed_min_target = 100.0
var speed_max_target = 750.0

# Current dynamic ranges (computed each frame)
var current_spawn_min = spawn_interval
var current_spawn_max = spawn_interval
var current_speed_min = speed
var current_speed_max = speed

# State
var spawn_timer = 0.0
var active_dots = []
var score = 0
var elapsed_time = 0.0

func set_widen_duration(duration: float) -> void:
	widen_duration = duration

func _ready() -> void:
	randomize()
	bg.z_index = -19.1
	# Hide the template dot
	static_dot.visible = false
	score_label.visible = true
	update_score_label()
	# initialize current ranges to base values
	current_spawn_min = spawn_interval
	current_spawn_max = spawn_interval
	current_speed_min = speed
	current_speed_max = speed

func _process(delta: float) -> void:
	if not rhythm_game.visible:
		return

	elapsed_time += delta
	_update_dynamic_windows()

	# 1. Spawn dots (spawn timer uses current dynamic spawn range)
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_dot()
		spawn_timer = randf_range(current_spawn_min, current_spawn_max)

	# 2. Move dots and handle misses
	# Iterate backwards to safely remove items
	for i in range(active_dots.size() - 1, -1, -1):
		var dot = active_dots[i]
		var dot_speed = dot.get_meta("speed", speed)
		dot.position.x -= dot_speed * delta

		# Check if dot passed the failure point without being hit
		if not dot.get_meta("failed", false) and dot.position.x < static_dot.position.x + failure_point:
			dot.set_meta("failed", true)
			dot.get_node("sprite").texture = load("res://assets/rhythm2/left_ball_" + dot.get_meta("required_key") + "_press.png")
			change_score(-score_penalty)
			# Start falling: set vertical velocity and acceleration
			dot.set_meta("falling", true)
			dot.set_meta("fall_velocity", 0.0)

		# If dot is falling, apply vertical acceleration
		if dot.get_meta("falling", false):
			var v = dot.get_meta("fall_velocity", 0.0)
			v += 1200.0 * delta # gravity
			dot.set_meta("fall_velocity", v)
			dot.position.y += v * delta

		# Remove if it goes too far left off-screen or falls below screen
		if dot.position.x < -200 or dot.position.y > 1200:
			active_dots.remove_at(i)
			dot.queue_free()

func _update_dynamic_windows() -> void:
	# If we haven't reached the delay, keep base ranges
	if elapsed_time <= widen_delay:
		current_spawn_min = spawn_interval
		current_spawn_max = spawn_interval
		current_speed_min = speed
		current_speed_max = speed
		return

	# compute normalized progress t in [0,1]
	var t = clamp((elapsed_time - widen_delay) / max(widen_duration, 0.0001), 0.0, 1.0)

	# Linearly interpolate from base (spawn_interval/speed) to the target min/max ranges
	current_spawn_min = lerp(spawn_interval, spawn_interval_min_target, t)
	current_spawn_max = lerp(spawn_interval, spawn_interval_max_target, t)
	current_speed_min = lerp(speed, speed_min_target, t)
	current_speed_max = lerp(speed, speed_max_target, t)

func spawn_dot() -> void:
	var lane_index = randi() % 5 # Random integer between 0 and 4
	var dot_instance = static_dot.duplicate()
	dot_instance.visible = true

	# Using the same vertical spacing logic: i * 51.25
	dot_instance.position = Vector2(955, static_dot.position.y + (lane_index * 54.85))

	dot_instance.get_node("sprite").texture = load("res://assets/rhythm2/left_ball_" + str(lane_index + 1) + ".png")

	# Store the required key on the dot for easy access
	dot_instance.set_meta("required_key", str(lane_index + 1))
	dot_instance.set_meta("failed", false)

	# Assign a per-dot speed sampled from the current speed window
	var chosen_speed = randf_range(current_speed_min, current_speed_max)
	dot_instance.set_meta("speed", chosen_speed)

	add_child(dot_instance)
	#dot_instance.get_node("label").text = str(lane_index + 1)
	active_dots.append(dot_instance)

func _input(event: InputEvent) -> void:
	if not rhythm_game.visible:
		return
	var already_discounted = false
	var d_dot

	if event is InputEventKey and event.pressed:
		var key_pressed = event.as_text_key_label() # Gets "1", "2", etc.

		# Check if we hit a dot
		for i in range(active_dots.size() - 1, -1, -1):
			var dot = active_dots[i]

			# Skip if already failed
			if dot.get_meta("failed", false):
				continue

			# Check if the key matches the lane
			if dot.get_meta("required_key") == key_pressed:
				# Check hit window
				if abs(dot.position.x - static_dot.position.x) < hit_window:
					var stream = load("res://sounds/sfx/rhythm/a_major/" + dot.get_meta("required_key") + ".mp3")
					print(dot.get_node("player").get_class())
					dot.get_node("player").stream = stream
					dot.get_node("player").volume_db = 10
					dot.get_node("player").play()
					active_dots.remove_at(i)
					dot.visible = false
					await get_tree().create_timer(1).timeout
					dot.queue_free()
					change_score(score_per_hit)
					print("Played sound for key: " + dot.get_meta("required_key"))
					
					return # Only destroy one dot per key press
				elif not already_discounted:
					already_discounted = true
					d_dot = dot
		if already_discounted:
			var stream = load("res://sounds/sfx/rhythm/a_major/" + d_dot.get_meta("required_key") + ".mp3")
			d_dot.get_node("player").stream = stream
			d_dot.get_node("player").volume_db = 10
			d_dot.get_node("player").pitch_scale = randf_range(0.9, 1.1) # random pitch correction
			d_dot.get_node("player").play()
			change_score(-1)

func change_score(amount: int) -> void:
	score += amount
	update_score_label()

func update_score_label() -> void:
	score_label.text = str(score)
