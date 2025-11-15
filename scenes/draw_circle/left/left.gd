extends Node2D

@onready var letter_display = $Label

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

func _input(event):
	if event is InputEventKey and event.pressed:
		var typed_char = char(event.unicode)
		
		#if typed_char.is_alpha():
		display_letter(typed_char.to_lower())

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
