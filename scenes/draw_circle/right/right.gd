# Canvas scene script
extends Node2D

@onready var draw_circle_game = get_parent()
@onready var area_2d = $Area2D
@onready var pencil = $pencil
@onready var feedback = $feedback

var is_hovering = false
var original_mouse_mode: int
var is_drawing = false

# Drawing variables
var line_points = []  # Store points for the current line
var current_line: Line2D  # Reference to the current line being drawn

var font = load("res://assets/PixelatedElegance.ttf")

# Feedback sayings
var feedback_sayings = [
	"Almost!",
	"So close!",
	"Nice try!",
	"Try again!",
	"Almost a perfect circle!",
	"Close enough!",
	"Nearly perfect!",
	"Good effort!",
	"Almost there!",
	"Keep going!",
	"Sorry, wasn't looking"
]

func _ready():
	randomize()
	# Connect the Area2D signals
	area_2d.mouse_entered.connect(_on_mouse_entered)
	area_2d.mouse_exited.connect(_on_mouse_exited)
	
	# Store original mouse mode
	original_mouse_mode = Input.get_mouse_mode()
	
	# Initially hide the pencil
	pencil.visible = false
	
	pencil.z_index = 40

func _on_mouse_entered():
	is_hovering = true
	pencil.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_mouse_exited():
	is_hovering = false
	pencil.visible = false
	Input.set_mouse_mode(original_mouse_mode)
	
	# If drawing when exiting, cancel the drawing
	if is_drawing:
		clear_current_drawing()

func _process(_delta):
	if is_hovering:
		# Make pencil follow mouse position precisely
		pencil.position = get_local_mouse_position()
		
		# If drawing, add points to the current line
		if is_drawing:
			add_drawing_point(pencil.position)

func _input(event):
	if not draw_circle_game.visible:
		return
	if is_hovering and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drawing
				start_drawing()
			else:
				# Stop drawing and clear the drawing, show feedback popup
				clear_current_drawing()

func start_drawing():
	is_drawing = true
	
	# Create a new Line2D for the drawing
	current_line = Line2D.new()
	
	# Configure the line appearance
	current_line.width = 3.0  # Line thickness
	current_line.default_color = Color.BLACK  # Drawing color
	current_line.antialiased = true  # Smooth lines
	
	# Add the line to the scene
	add_child(current_line)
	
	# Start with the current mouse position
	var start_pos = get_local_mouse_position()
	line_points = [start_pos]
	current_line.points = line_points

func add_drawing_point(point: Vector2):
	if current_line and is_drawing:
		# Add the new point to our line
		line_points.append(point)
		current_line.points = line_points

func clear_current_drawing():
	# Stop drawing
	is_drawing = false
	
	# Remove the current line from the scene
	if current_line:
		current_line.queue_free()
		current_line = null
	
	line_points = []
	
	# Create feedback popup at mouse release
	create_feedback_popup()

func create_feedback_popup():
	if not feedback:
		return
	# Duplicate the feedback label (deep copy)
	var copy = feedback.duplicate(true)
	if not copy:
		return
	# Ensure visible and set text
	copy.visible = true
	copy.text = feedback_sayings[randi() % feedback_sayings.size()]
	# Add to same parent so coordinates match canvas
	get_parent().add_child(copy)
	# Position so the label's center is at the mouse position
	var mouse_pos = get_global_mouse_position()
	var size = copy.get_minimum_size()
	print(size)
	copy.global_position = mouse_pos - size * 0.5
	# Make text/label black and fully opaque initially
	if copy.has_method("set_modulate"):
		copy.add_theme_font_override("font", font)
		copy.modulate = Color(0, 0, 0, 1)
	else:
		copy.self_modulate = Color(0, 0, 0, 1)
	# Animate upward movement and fade out, then free
	var up_amount = 60.0
	var duration = 1.5
	var tween = copy.create_tween()
	tween.tween_property(copy, "global_position:y", copy.global_position.y - up_amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(copy, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(copy, "queue_free"))

func _exit_tree():
	# Always restore mouse mode when exiting
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
