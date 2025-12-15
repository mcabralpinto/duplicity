extends Node2D

@onready var minigame = get_parent()
@onready var egg = $egg
@onready var basket = $basket
@onready var small_egg = $small_egg
@onready var droppable_area = $droppable_area
@onready var score_label = $score_label
@onready var egg_label = $egg_label
@onready var speech_bubble = $speech_bubble
@onready var speech_label = $speech_bubble/speech_label
@onready var instruction_label = $instruction_label
@onready var instruction2_label = $instruction2_label

var score = 0
var eat_chance = 0.3
var eggs_left = 55
var needed_eggs = eggs_left - 5
var holding_egg = false
var held_egg_instance = null
var dropped_eggs = []
var selected_egg_index = -1
var speech_timer: Timer = null
var egg_sayings = ["mmm", "mmmmm", "oh boy", "yum", "yummy", "more please", "more plz", "oh yes", "delicious", "tasty", "oh mamma", "scrumptious", "excellent", "good", "what a treat", ":3", "more", "that was so good"]

func set_visibility(visibility: bool) -> void:
	self.visible = visibility

func run_game() -> void:
	set_visibility(true)

func _ready() -> void:
	small_egg.visible = false
	score_label.add_theme_color_override("font_color", Color.BLACK)
	egg_label.add_theme_color_override("font_color", Color.BLACK)
	instruction_label.add_theme_color_override("font_color", Color.BLACK)
	instruction2_label.add_theme_color_override("font_color", Color.BLACK)
	update_score_label()
	update_egg_label()
	play_egg_anim("idle")
	
	# Setup speech bubble
	speech_bubble.visible = false
	var font = load("res://assets/PixelatedElegance.ttf")
	if font and speech_label:
		speech_label.add_theme_font_override("font", font)
		speech_label.add_theme_color_override("font_color", Color.BLACK)
	
	# Setup speech timer
	speech_timer = Timer.new()
	speech_timer.one_shot = true
	speech_timer.connect("timeout", Callable(self, "_on_speech_timer_timeout"))
	add_child(speech_timer)

func _process(delta: float) -> void:
	if mouse_hidden:
		return 

	if holding_egg and held_egg_instance:
		held_egg_instance.global_position = get_global_mouse_position()

	# Move dropped eggs with arrow keys
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	
	if velocity != Vector2.ZERO:
		for i in range(dropped_eggs.size() - 1, -1, -1):
			var dropped_egg = dropped_eggs[i]
			dropped_egg.position += velocity * 200 * delta
			
			# Check if egg touches big egg
			var egg_collision = egg.get_node("collision")
			if egg_collision.global_position.distance_to(dropped_egg.global_position) < 100:
				eat_dropped_egg(i)
				continue # Skip boundary check if eaten

			# Check if egg is still in droppable area
			if not is_point_in_droppable_area(dropped_egg.global_position):
				dropped_eggs.remove_at(i)
				dropped_egg.queue_free()
				check_game_over()

	# Update animation based on dropped eggs presence
	var sprite = egg.get_node_or_null("AnimatedSprite2D")
	if sprite:
		if dropped_eggs.size() > 0 and sprite.animation == "idle":
			play_egg_anim("eager")
		elif dropped_eggs.size() == 0 and not holding_egg and sprite.animation == "eager":
			play_egg_anim("idle")

func _input(event: InputEvent) -> void:
	if (not self.visible) or mouse_hidden:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Try to pick up from basket
			var clicked_basket = false
			
			# Check collision area (Area2D)
			var basket_area = basket.get_node_or_null("collision")
			if basket_area:
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new()
				query.position = get_global_mouse_position()
				query.collide_with_areas = true
				query.collide_with_bodies = false
				var results = space_state.intersect_point(query)
				for result in results:
					if result.collider == basket_area:
						clicked_basket = true
						break
			
			# Fallback to sprite check
			if not clicked_basket:
				var basket_sprite = basket if basket is Sprite2D else basket.get_node_or_null("Sprite2D")
				if basket_sprite and basket_sprite.get_rect().has_point(basket_sprite.to_local(event.position)):
					clicked_basket = true

			if clicked_basket:
				spawn_held_egg()
			# Try to pick up dropped egg from droppable area
			elif not holding_egg:
				var mouse_pos = get_global_mouse_position()
				for i in range(dropped_eggs.size() - 1, -1, -1):
					var dropped_egg = dropped_eggs[i]
					if dropped_egg.global_position.distance_to(mouse_pos) < 30:
						pickup_dropped_egg(i)
						break
		elif not event.pressed and holding_egg:
			drop_egg()

var mouse_hidden = false

func spawn_held_egg():
	if eggs_left <= 0:
		return

	if held_egg_instance:
		held_egg_instance.queue_free()
	
	eggs_left -= 1
	update_egg_label()
	
	held_egg_instance = small_egg.duplicate()
	held_egg_instance.visible = true
	held_egg_instance.global_position = get_global_mouse_position()
	add_child(held_egg_instance)
	holding_egg = true
	play_egg_anim("eager")

func is_point_in_droppable_area(point: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results = space_state.intersect_point(query)
	for result in results:
		if result.collider == droppable_area:
			return true
	return false

func drop_egg():
	holding_egg = false
	
	if not held_egg_instance:
		play_egg_anim("idle")
		return

	# Check collision with big egg
	var egg_collision = egg.get_node("collision")
	
	if egg_collision.global_position.distance_to(held_egg_instance.global_position) < 100: # Approximate radius check
		feed_egg()
		return

	# Check if dropped in droppable area
	if is_point_in_droppable_area(held_egg_instance.global_position):
		# Keep egg in droppable area
		dropped_eggs.append(held_egg_instance)
		held_egg_instance = null
		# Animation update handled in _process
	else:
		held_egg_instance.queue_free()
		held_egg_instance = null
		play_egg_anim("idle")
		check_game_over()

func feed_egg():
	# Force restart of animation
	var sprite = egg.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.stop()
		sprite.frame = 0
	play_egg_anim("munching")
	
	if randf() < eat_chance:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		mouse_hidden = true
		show_speech("yuck... this one tasted like mouse")
	else:
		score += 1
		update_score_label()
		show_speech(egg_sayings[randi() % egg_sayings.size()])
	
	if held_egg_instance:
		held_egg_instance.queue_free()
		held_egg_instance = null
	
	check_game_over()
	
	await get_tree().create_timer(0.5).timeout
	if not holding_egg:
		# Animation state will be corrected in _process if eggs exist
		play_egg_anim("idle")

func update_score_label():
	score_label.text = "leave eggs here. eaten eggs: " + str(score)

func update_egg_label():
	egg_label.text = "DON'T leave eggs here. eggs left: " + str(eggs_left)

func play_egg_anim(anim: String) -> void:
	var sprite = egg.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play(anim)

func pickup_dropped_egg(index: int) -> void:
	if index < 0 or index >= dropped_eggs.size():
		return
	
	if held_egg_instance:
		held_egg_instance.queue_free()
	
	held_egg_instance = dropped_eggs[index]
	dropped_eggs.remove_at(index)
	holding_egg = true
	play_egg_anim("eager")

func eat_dropped_egg(index: int) -> void:
	if index < 0 or index >= dropped_eggs.size():
		return
	
	var dropped_egg = dropped_eggs[index]
	dropped_eggs.remove_at(index)
	dropped_egg.queue_free()
	
	# Force restart of animation
	var sprite = egg.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.stop()
		sprite.frame = 0
	play_egg_anim("munching")
	
	if randf() < eat_chance:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		mouse_hidden = true
		show_speech("yuck... this one tasted like mouse")
	else:
		score += 1
		update_score_label()
		show_speech(egg_sayings[randi() % egg_sayings.size()])
	
	check_game_over()
	
	await get_tree().create_timer(0.5).timeout
	if not holding_egg:
		# Animation state will be corrected in _process if eggs exist
		play_egg_anim("idle")

func show_speech(text: String) -> void:
	if speech_label:
		speech_label.text = text
	speech_bubble.visible = true
	
	# Reset timer
	if speech_timer:
		speech_timer.stop()
		speech_timer.start(5.0)

func _on_speech_timer_timeout() -> void:
	speech_bubble.visible = false
	if mouse_hidden:
		self.set_visibility(false)
		minigame.end_game("c", -10)

func check_game_over() -> void:
	if mouse_hidden:
		return

	if eggs_left <= 0 and dropped_eggs.is_empty() and not holding_egg:
		self.set_visibility(false)
		if score >= needed_eggs:
			minigame.end_game("a", 10)
		else:
			minigame.end_game("b", -5)
