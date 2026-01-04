extends Node2D

@onready var draw_circle_game = get_parent()
@onready var letter_display = $Label
@onready var marker = $marker
var success_timer: Timer
var cursor_timer: Timer
var game_timer: Timer
var game_ended: bool = false

func _ready():
	letter_display.visible = false
	
	# Center alignment
	letter_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Style the label (adjust values as needed)
	var font = load("res://assets/FuturaCyrillicLight.ttf")
	letter_display.add_theme_font_override("font", font)
	letter_display.add_theme_font_size_override("font_size", 150)
	letter_display.add_theme_color_override("font_color", Color.BLACK)
	
	# Center in screen
	var viewport_size = get_viewport_rect().size
	letter_display.position = viewport_size / 2
	
	# Create the success timer
	success_timer = Timer.new()
	success_timer.wait_time = 2.0
	success_timer.one_shot = true
	success_timer.timeout.connect(_on_success_timer_timeout)
	add_child(success_timer)
	
	# Create cursor blink timer
	cursor_timer = Timer.new()
	cursor_timer.wait_time = 0.5
	cursor_timer.one_shot = false
	cursor_timer.timeout.connect(_on_cursor_timer_timeout)
	add_child(cursor_timer)
	
	# Create game timer (30 seconds)
	game_timer = Timer.new()
	game_timer.wait_time = 30.0
	game_timer.one_shot = true
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	# do NOT start here; draw_circle_game will start/stop this timer via start_game()/stop_game()
	
	# Start with blinking marker when no letter
	marker.visible = true
	if not letter_display.visible:
		cursor_timer.start()

func _input(event):
	if not draw_circle_game.visible:
		return
		
	if event is InputEventKey:
		if event.pressed:
			var typed_char = char(event.unicode).to_lower()
			
			if typed_char in "abcdefghijklmnopqrstuvwxyz1234567890":
				display_letter(typed_char)

			if typed_char == "o":
				if success_timer.is_stopped():
					success_timer.start()
			else:
				# If any other key is pressed, stop the success timer
				success_timer.stop()

func display_letter(letter: String):
	letter_display.text = letter
	letter_display.visible = true
	
	# Hide marker fully while a letter is shown and stop blinking
	marker.visible = false
	if cursor_timer and not cursor_timer.is_stopped():
		cursor_timer.stop()
	
	letter_display.position = Vector2.ZERO
	
	# Reset and start disappear timer
	if has_node("DisappearTimer"):
		$DisappearTimer.start()
	else:
		create_disappear_timer()

func create_disappear_timer():
	var timer = Timer.new()
	timer.name = "DisappearTimer"
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func _on_timer_timeout():
	letter_display.visible = false
	# Resume cursor blinking when letter disappears
	marker.visible = true
	if cursor_timer:
		cursor_timer.start()

func _on_success_timer_timeout():
	if game_ended:
		return
	game_ended = true
	if game_timer and not game_timer.is_stopped():
		game_timer.stop()
	draw_circle_game.end_game("a", 5)

func _on_game_timer_timeout():
	if game_ended:
		return
	game_ended = true
	draw_circle_game.end_game("b", -10)

func start_game():
	# Called by draw_circle_game to start a play session
	game_ended = false
	# ensure timers are running appropriately
	if success_timer and not success_timer.is_stopped():
		success_timer.stop()
	if cursor_timer and cursor_timer.is_stopped():
		cursor_timer.start()
	# ensure marker/label state
	letter_display.visible = false
	marker.visible = true
	# start the main game timer
	if game_timer:
		game_timer.start()

func stop_game():
	# Stop any running timers to prevent stray end callbacks
	game_ended = true
	if game_timer and not game_timer.is_stopped():
		game_timer.stop()
	if success_timer and not success_timer.is_stopped():
		success_timer.stop()
	if cursor_timer and not cursor_timer.is_stopped():
		cursor_timer.stop()

func _on_cursor_timer_timeout():
	# Only blink when there is no letter visible
	if not letter_display.visible:
		marker.visible = not marker.visible
	else:
		marker.visible = false
