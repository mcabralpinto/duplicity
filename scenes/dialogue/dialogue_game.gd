extends Node2D

@onready var minigame = get_parent()
@onready var left_label = $left_label
@onready var right_label = $right_label
@onready var left_lock = $left_lock
@onready var right_lock = $right_lock
@onready var right_lock_button = $right_lock/lock
@onready var right_arrows = $right_arrows
@onready var top_arrow = $right_arrows/top_arrow
@onready var bottom_arrow = $right_arrows/bottom_arrow

var variant = 1
var l1 = ["I think it's going well.", "It's going well.", "I don't know.", "Not great.", "What do you think?"]
var r1 = ["*in a confident tone*", "*in a cautious tone*", "*in a neutral tone*", "*in a mocking voice*"]
var l2 = ["No, not at all.", "I literally just answered a question.", "Sorry, I'm a little nervous.", "Sorry, a lot on my mind.", "Family issues. My bad."]
var r2 = ["*in a confident tone*", "*in a cautious tone*", "*in a neutral tone*", "*in a mocking voice*"]

var left_list := []
var right_list := []
var left_index := 0
var right_index := 0

var left_locked := false
var right_locked := false
var _left_backup_list := []
var _right_backup_list := []
var _left_backup_index := 0
var _right_backup_index := 0

func set_visibility(visibility: bool) -> void:
	self.visible = visibility

func run_game() -> void:
	set_visibility(true)
	#print(minigame.question[minigame.section])
	set_variant(minigame.question[minigame.section])
	_apply_variant()
	

func _ready() -> void:
	var font = load("res://assets/PixelatedElegance.ttf")

	left_label.z_index = 41
	left_label.add_theme_font_size_override("font_size", 28)
	left_label.add_theme_color_override("font_color", Color.WHITE)
	left_label.add_theme_font_override("font", font)

	right_label.z_index = 41
	right_label.add_theme_font_size_override("font_size", 28)
	right_label.add_theme_color_override("font_color", Color.WHITE)
	right_label.add_theme_font_override("font", font)

	left_lock.z_index = 41
	left_lock.add_theme_font_size_override("font_size", 20)
	left_lock.add_theme_color_override("font_color", Color.WHITE)
	left_lock.add_theme_font_override("font", font)
	left_lock.visible = true

	right_lock.z_index = 41
	right_lock.add_theme_font_size_override("font_size", 20)
	right_lock.add_theme_color_override("font_color", Color.WHITE)
	right_lock.add_theme_font_override("font", font)
	right_lock.visible = true

	# ensure labels show initial values
	if left_list.size() > 0:
		left_label.text = str(left_list[left_index])
	if right_list.size() > 0:
		right_label.text = str(right_list[right_index])

func _input(event: InputEvent) -> void:
	if self.visible:
		if event.is_action_pressed("ui_up"):
			_change_left_index(-1)
		elif event.is_action_pressed("ui_down"):
			_change_left_index(1)
		elif event is InputEventKey and event.pressed and (event.unicode == ord("y") or event.unicode == ord("Y")):
			_toggle_left_lock()

		# simpler mouse click detection against arrow nodes
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var pos = get_global_mouse_position()
			if _is_point_over(top_arrow, pos):
				_change_right_index(-1)
				return
			if _is_point_over(bottom_arrow, pos):
				_change_right_index(1)
				return
			if _is_point_over(right_lock_button, pos):
				_toggle_right_lock()

func _is_point_over(node: Node, global_point: Vector2) -> bool:
	if not node:
		return false

	# If node or child has a Sprite2D, use its rect test
	var sprite = node if node is Sprite2D else node.get_node_or_null("Sprite2D")
	if sprite:
		var local_point = sprite.to_local(global_point)
		return sprite.get_rect().has_point(local_point)

	# Fallback: if node is Area2D (or has one), do a lightweight point query
	var area = node if node is Area2D else node.get_node_or_null("Area2D")
	if area:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_point
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var results = space_state.intersect_point(query)
		for r in results:
			if r.collider == area:
				return true

	return false

func set_variant(v: int) -> void:
	variant = v

func _apply_variant() -> void:
	match variant:
		1:
			left_list = l1
			right_list = r1
		2:
			left_list = l2
			right_list = r2
		_:
			left_list = l1
			right_list = r1

func _change_left_index(delta: int) -> void:
	var max_i = left_list.size()
	if max_i == 0:
		return
	left_index = (left_index + delta) % max_i
	if left_index < 0:
		left_index = max_i - 1
	left_label.text = str(left_list[left_index])

func _change_right_index(delta: int) -> void:
	var max_i = right_list.size()
	if max_i == 0:
		return
	right_index = (right_index + delta) % max_i
	if right_index < 0:
		right_index = max_i - 1
	print(right_index)
	right_label.text = str(right_list[right_index])

func _toggle_left_lock() -> void:
	if not left_label or left_label.text.strip_edges() == "":
		return
	left_locked = true
	_left_backup_list = left_list.duplicate()
	_left_backup_index = left_index
	# replace list with single current value so indices can't change the visible text
	left_list = [left_list[left_index]]
	left_lock.text = "LOCKED"
	left_lock.add_theme_color_override("font_color", Color.GREEN)

	_check_both_locked()

func _toggle_right_lock() -> void:
	if not right_label or right_label.text.strip_edges() == "":
		return
	right_locked = true
	_right_backup_list = right_list.duplicate()
	_right_backup_index = right_index
	right_list = [right_list[right_index]]
	right_lock.text = "LOCKED"
	right_lock.add_theme_color_override("font_color", Color.GREEN)

	_check_both_locked()

func _check_both_locked() -> void:
	if left_locked and right_locked:
		print(left_index, right_index)
		set_visibility(false)
		if variant == 1:
			if right_index == 3:
				minigame.end_game("a", 20)
			elif right_index in [0] or left_index in [1, 3]:
				minigame.end_game("b", -5)
			else: 
				minigame.end_game("c", 0)
		if variant == 2:
			if right_index == 3:
				minigame.end_game("a", 20)
			elif left_index in [4]:
				minigame.end_game("b", 1)
			elif left_index in [0] and right_index in [0, 2]:
				minigame.end_game("c", -1)
			elif left_index in [1]:
				minigame.end_game("d", 5)
			else:
				minigame.end_game("e", -5)
