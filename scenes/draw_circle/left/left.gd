extends Node2D

@onready var draw_circle_game = get_parent()
@onready var letter_display = $Label
var success_timer: Timer

func _ready():
	letter_display.visible = false
	
	# Center alignment
	letter_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Style the label (adjust values as needed)
	letter_display.add_theme_font_size_override("font_size", 75)
	letter_display.add_theme_color_override("font_color", Color.WHITE)
	
	# Center in screen
	var viewport_size = get_viewport_rect().size
	letter_display.position = viewport_size / 2
	
	# Create the success timer
	success_timer = Timer.new()
	success_timer.wait_time = 2.0
	success_timer.one_shot = true
	success_timer.timeout.connect(_on_success_timer_timeout)
	add_child(success_timer)

func _input(event):
	if not draw_circle_game.visible:
		return
		
	if event is InputEventKey:
		if event.pressed:
			var typed_char = char(event.unicode).to_lower()
			
			if typed_char in "abcdefghijklmnopqrstuvwxyz":
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

func _on_success_timer_timeout():
	draw_circle_game.end_game("a", 0)
