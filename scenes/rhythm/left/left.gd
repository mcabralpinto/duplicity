extends Node2D

@onready var rhythm_game = get_parent()
@onready var static_dot = $dot
@onready var score_label = $score_label

# Game parameters
var speed = 200.0
var spawn_interval = 0.75 # Decreased for more balls
var hit_window = 50.0
var failure_point = -30.0 # X position where a ball is considered missed
var score_per_hit = 10
var score_penalty = 5

# State
var spawn_timer = 0.0
var active_dots = []
var score = 0

func _ready() -> void:
	# Hide the template dot
	static_dot.visible = false
	score_label.visible = true
	score_label.modulate = Color.BLACK
	update_score_label()

func _process(delta: float) -> void:
	if not rhythm_game.visible:
		return
		
	# 1. Spawn dots
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_dot()
		spawn_timer = spawn_interval

	# 2. Move dots and handle misses
	# Iterate backwards to safely remove items
	for i in range(active_dots.size() - 1, -1, -1):
		var dot = active_dots[i]
		dot.position.x -= speed * delta
		
		# Check if dot passed the failure point without being hit
		if not dot.get_meta("failed", false) and dot.position.x < static_dot.position.x + failure_point:
			dot.set_meta("failed", true)
			dot.get_node("sprite").modulate = Color.RED
			change_score(-score_penalty)
		
		# Remove if it goes too far left off-screen
		if dot.position.x < -200:
			active_dots.remove_at(i)
			dot.queue_free()

func spawn_dot() -> void:
	var lane_index = randi() % 5 # Random integer between 0 and 4
	var dot_instance = static_dot.duplicate()
	dot_instance.visible = true
	
	# Using the same vertical spacing logic: i * 51.25
	dot_instance.position = Vector2(955, static_dot.position.y + (lane_index * 51.25))
	
	# Store the required key on the dot for easy access
	dot_instance.set_meta("required_key", str(lane_index + 1))
	dot_instance.set_meta("failed", false)
	dot_instance.get_node("sprite").modulate = Color.BLACK
	
	add_child(dot_instance)
	dot_instance.get_node("label").text = str(lane_index + 1)
	active_dots.append(dot_instance)

func _input(event: InputEvent) -> void:
	if not rhythm_game.visible:
		return

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
					active_dots.remove_at(i)
					dot.queue_free()
					change_score(score_per_hit)
					break # Only destroy one dot per key press
				else:
					change_score(-score_penalty)
					pass

func change_score(amount: int) -> void:
	score += amount
	update_score_label()

func update_score_label() -> void:
	score_label.text = str(score)
