# Canvas scene script
extends Node2D

@onready var area_2d = $Area2D
@onready var pencil = $pencil  # Your pencil node

var is_hovering = false
var original_mouse_mode: int
var is_drawing = false

# Drawing variables
var line_points = []  # Store points for the current line
var current_line: Line2D  # Reference to the current line being drawn

func _ready():
	# Connect the Area2D signals
	area_2d.mouse_entered.connect(_on_mouse_entered)
	area_2d.mouse_exited.connect(_on_mouse_exited)
	
	# Store original mouse mode
	original_mouse_mode = Input.get_mouse_mode()
	
	# Initially hide the pencil
	pencil.visible = false
	
	pencil.z_index = 1

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

func _process(delta):
	if is_hovering:
		# Make pencil follow mouse position precisely
		pencil.position = get_local_mouse_position()
		
		# If drawing, add points to the current line
		if is_drawing:
			add_drawing_point(pencil.position)

func _input(event):
	if is_hovering and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drawing
				start_drawing()
			else:
				# Stop drawing and clear the drawing
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
	
	print("Started drawing at: ", start_pos)

func add_drawing_point(position: Vector2):
	if current_line and is_drawing:
		# Add the new point to our line
		line_points.append(position)
		current_line.points = line_points

func clear_current_drawing():
	is_drawing = false
	
	# Remove the current line from the scene
	if current_line:
		current_line.queue_free()
		current_line = null
	
	line_points = []
	print("Cleared drawing")

func _exit_tree():
	# Always restore mouse mode when exiting
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
