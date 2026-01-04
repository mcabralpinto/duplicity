extends Node2D

@onready var minigame = get_parent()
@onready var caption = $caption
@onready var left = $left
@onready var right = $right
@onready var left_frame = $left_frame
@onready var right_frame = $right_frame
@onready var top_frame = $top_frame
@onready var l_frame_push = $l_frame_push
@onready var r_frame_push = $r_frame_push
@onready var call_request = $call_request
@onready var call_label = call_request.get_node("incoming")
@onready var dokter_label = call_request.get_node("dokter")
@onready var left_label = call_request.get_node("left")
@onready var right_label = call_request.get_node("right")

var popped_up: bool = false
var left_pressed: bool = false
var right_pressed: bool = false

# interruption counting and random phrases
var interruptions_count: int = 0
var interrupt_phrases: Array = [
	"Please hold your questions.",
	"Wait until I'm finished.",
	"One at a time, please.",
	"Save it for the end.",
	"This is not the moment to interject.",
	"Interruptions will be noted.",
	"Let me finish my point.",
	"I'll take questions later.",
	"Please refrain from interjecting.",
	"Silence is appreciated."
]
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var speech = "Ah. You've joined the stream. Excellent. Synchronous particulate engagement is at... acceptable levels. Please, contain your enthusiasm; the digital air ducts can only handle so much fervor.\nThis is a mandatory, semi-annual, bi-quarterly, cross-departmental briefing on the implementation of Phase 7: Sub-Protocol Vermilion. The agenda is circular, so feel free to jump in at any point, though I warn you, the point is likely moving.\nFirstly, a moment of sonic recognition for the new ambient hum. That is not feedback. That is our newly installed 'Productive Dissonance' module, designed to subliminally encourage divergent thinking within convergent parameters. If you hear a melody, please report it to Compliance; you may be aligning too perfectly.\nNow, to the granularity. Our primary initiative this cycle is the Symbiotic Paperwork Inversion. We have found that documents are most potent not when they are filled, but when they are anticipated. Therefore, all TPS reports—and I am looking at the Denver annex specifically—must now be filed before the project ideation phase. You will be submitting forms detailing the outcomes of brainstorms you have not yet had, for clients who may not yet exist. This creates a beautiful, pressurized vacuum for success to rush into. Or, failing that, a vacuum.\nSecondly, a clarification on Metaphorical Literalization. The directive to 'think outside the box' has been deemed dangerously vague. What box? Of what dimensions? To remedy this, each team will be issued a physical, corrugated cardboard cube (1m x 1m x 1m). All brainstorming must be conducted by individuals physically stationed outside its perimeter. The box itself is to be labeled 'The Box.' Creativity is now quantifiable. Please note: sitting on the box is considered a lateral move and requires a separate form (PX-41B)\nThird point, and this is critical: the Inter-Departmental Aura Calibration. The memos about 'synergistic vibes' were not, as some of you in Accounting seem to have assumed, metaphorical. Harmonic resonators have been installed in all ceiling panels. By Friday, your personal emotional frequency must be tuned to a collective 'C# Minor - Ambitionately Pensive.' Resources has the tuning forks. Failure to harmonize may result in your coffee tasting slightly of static and regret\nNow, let's look at an example. Think of my Brazilian bird, Coxinha. Coxinha is not just an avian colleague; he is a model of resource allocation. See how he pecks? Each peck is a discrete data packet of hunger, directed at a non-nutritive substrate. This is what we call Inefficient Efficiency. He is engaged in a task with maximum effort and zero yield, which keeps him hungry, motivated, and, most importantly, in a state of perpetual process. We want you to be more like Coxinha. Peck with purpose at the meaningless.\nFinally, a reminder on Digital Posture. During these virtual engagements, I can, through proprietary screen-aura analysis, perceive the slant of your existential spine. A slouch implies a receptiveness to chaos. A perfect 90-degree angle suggests dangerous rigidity. The ideal is a gentle, 97-degree lean—forward enough to suggest engagement, but back enough to imply a deep, systemic skepticism. Practice this.\nAre there any questions? No? Splendid. Your silence has been logged as enthusiastic consent.\nThis meeting has been declared Productively Redundant. All action items generated herein are to be archived in the Circuitous Pending folder, which, as you know, is metaphorically represented by a digital ouroboros eating a manila envelope.\nYou may now return to your previously scheduled inertia. Remember: ~~ Company™ ~~ is not a family. It is a carefully curated ecosystem of mutually assured distraction. Carry that with you.\nDokterr out."

# caption slow-print state
var _full_text: String = ""
var _char_index: int = 0
var _timer: Timer = null
var _speed_timer: Timer = null
var _pause_timer: Timer = null
var full_display: bool = true
var _paused: bool = false
var _speed_stage: int = 0
var _interrupt_in_progress: bool = false
var _ended: bool = false
const INITIAL_INTERVAL := 0.06
const DIVIDE_BY := 6
const SPEED_UP_AFTER := 5.0
const PAUSE_DURATION := 1.0

func set_visibility(visibility: bool) -> void:
	self.visible = visibility

func _end_game(code: String, score: int) -> void:
	if _ended:
		return
	_ended = true
	# stop timers and input
	if _timer:
		_timer.stop()
	if _speed_timer:
		_speed_timer.stop()
	if _pause_timer:
		_pause_timer.stop()
	set_process_input(false)
	_interrupt_in_progress = false

	var l_target = l_frame_push.position + Vector2(-480, 0)
	var r_target = r_frame_push.position + Vector2(480, 0)
	var t1 = create_tween()
	t1.tween_property(l_frame_push, "position", l_target, 0.25)
	var t2 = create_tween()
	t2.tween_property(r_frame_push, "position", r_target, 0.25)
	while l_frame_push.position != l_target or r_frame_push.position != r_target:
		await get_tree().process_frame

	# call the minigame end	
	set_visibility(false)	
	minigame.end_game(code, score)

func run_game() -> void:
	# reset press state and label colors for this round
	left_pressed = false
	right_pressed = false
	left_label.add_theme_color_override("font_color", Color.WHITE)
	right_label.add_theme_color_override("font_color", Color.WHITE)
	left_frame.visible = false
	right_frame.visible = false

	# make sure this node is visible so the request can animate
	set_visibility(true)

	# show and grow the call_request
	call_request.visible = true
	call_request.scale = Vector2(0.01, 0.01)
	var grow_tween = create_tween()
	grow_tween.tween_property(call_request, "scale", Vector2(1, 1), 0.25)
	await grow_tween.finished

	popped_up = true


	# wait until both controls have been pressed at least once (order doesn't matter)
	while not (left_pressed and right_pressed):
		await get_tree().process_frame

	# shrink and hide the call_request while sliding frame pushes (all concurrently)
	var l_target = l_frame_push.position + Vector2(480, 0)
	var r_target = r_frame_push.position + Vector2(-480, 0)

	var t1 = create_tween()
	t1.tween_property(call_request, "scale", Vector2(0.01, 0.01), 0.25)

	var t2 = create_tween()
	t2.tween_property(l_frame_push, "position", l_target, 0.25)

	var t3 = create_tween()
	t3.tween_property(r_frame_push, "position", r_target, 0.25)
	
	left.visible = true
	right.visible = true

	# wait until all three reach their target states
	while call_request.scale != Vector2(0.01, 0.01) or l_frame_push.position != l_target or r_frame_push.position != r_target:
		await get_tree().process_frame

	left_frame.visible = true
	right_frame.visible = true
	top_frame.visible = true
	call_request.visible = false

	# start caption slow print of speech
	display_text_slowly(speech, INITIAL_INTERVAL)

func _ready() -> void:
	left_frame.z_index = 30
	right_frame.z_index = 30
	top_frame.z_index = 31
	l_frame_push.z_index = 30
	r_frame_push.z_index = 30
	call_request.z_index = 40

	l_frame_push.visible = true
	r_frame_push.visible = true

	_rng.randomize()

	var font = load("res://assets/PixelatedElegance.ttf")

	caption.z_index = 21
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", Color.YELLOW)
	caption.add_theme_font_override("font", font)

	call_label.z_index = 41
	call_label.add_theme_font_size_override("font_size", 28)
	call_label.add_theme_color_override("font_color", Color.WHITE)
	call_label.add_theme_font_override("font", font)

	dokter_label.z_index = 41
	dokter_label.add_theme_font_size_override("font_size", 36)
	dokter_label.add_theme_color_override("font_color", Color.YELLOW)
	dokter_label.add_theme_font_override("font", font)
	
	left_label.z_index = 41
	left_label.add_theme_font_size_override("font_size", 28)
	left_label.add_theme_color_override("font_color", Color.WHITE)
	left_label.add_theme_font_override("font", font)

	right_label.z_index = 41
	right_label.add_theme_font_size_override("font_size", 28)
	right_label.add_theme_color_override("font_color", Color.WHITE)
	right_label.add_theme_font_override("font", font)

	call_request.visible = false
	call_request.scale = Vector2(0.01, 0.01)

func display_text_slowly(text: String, interval: float = INITIAL_INTERVAL) -> void:
	_full_text = text
	_char_index = 0
	caption.text = ""
	full_display = false
	_paused = false
	_speed_stage = 0

	if _timer:
		_timer.stop()
	else:
		_timer = Timer.new()
		_timer.one_shot = false
		add_child(_timer)
		_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	_timer.wait_time = interval
	_timer.start()

	if _speed_timer:
		_speed_timer.stop()
	else:
		_speed_timer = Timer.new()
		_speed_timer.one_shot = true
		add_child(_speed_timer)
		_speed_timer.connect("timeout", Callable(self, "_on_speed_timer_timeout"))
	_speed_timer.wait_time = SPEED_UP_AFTER
	_speed_timer.start()

	if _pause_timer:
		_pause_timer.stop()
	else:
		_pause_timer = Timer.new()
		_pause_timer.one_shot = true
		add_child(_pause_timer)
		_pause_timer.connect("timeout", Callable(self, "_on_pause_timeout"))

	set_process_input(true)

func _on_timer_timeout():
	if _paused or _ended:
		return
	if _char_index < _full_text.length():
		caption.text += _full_text[_char_index]
		_char_index += 1
	else:
		_timer.stop()
		if _speed_timer:
			_speed_timer.stop()
		if _pause_timer:
			_pause_timer.stop()
		set_process_input(false)
		full_display = true
		# finished normally -> success end
		_end_game("a", 5)

func _on_speed_timer_timeout():
	if full_display:
		return
	if _speed_stage < 1:
		_timer.wait_time = _timer.wait_time / DIVIDE_BY
		_speed_stage += 1
	if _speed_stage < 1:
		_speed_timer.wait_time = SPEED_UP_AFTER
		_speed_timer.start()
	else:
		_speed_timer.stop()

func _on_pause_timeout():
	_paused = false
	if not full_display and not _ended:
		_timer.start()
		# restart the 5 second speed counter only if there are remaining speed stages
		if _speed_stage < 2:
			_speed_timer.stop()
			_speed_timer.wait_time = SPEED_UP_AFTER
			_speed_timer.start()

func finish_animation():
	if not full_display:
		caption.text = _full_text
		_char_index = _full_text.length()
		if _timer:
			_timer.stop()
		if _speed_timer:
			_speed_timer.stop()
		if _pause_timer:
			_pause_timer.stop()
		set_process_input(false)
		full_display = true
		_end_game("a", 5)

func _input(event):
	if popped_up:
		if Input.is_action_pressed("ui_accept"):
			left_pressed = true
			left_label.add_theme_color_override("font_color", Color(0, 1, 0))
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			right_pressed = true
			right_label.add_theme_color_override("font_color", Color(0, 1, 0))
	# handle interrupt sequence on space or left mouse while caption is printing
	if not full_display and _timer:
		var triggered := false
		# only count presses that happen after the request is already hidden
		if event.is_action_pressed("ui_accept") and not call_request.visible:
			left_frame.visible = true
			triggered = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not call_request.visible:
			right_frame.visible = true
			triggered = true
		if triggered:
			start_interrupt_sequence()

func _process(_delta: float) -> void:
	if popped_up:
		# reflect whether each control has been pressed at least once
		if not Input.is_action_pressed("ui_accept"):
			left_frame.visible = false
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			right_frame.visible = false

func start_interrupt_sequence() -> void:
	if _interrupt_in_progress or full_display or _ended:
		return
	_interrupt_in_progress = true
	_paused = true

	# count this interruption
	interruptions_count += 1

	# if too many interruptions -> immediate failure end
	if interruptions_count >= 5:
		_end_game("b", -10)
		return

	# stop timers that drive the printing
	if _timer:
		_timer.stop()
	if _speed_timer:
		_speed_timer.stop()

	# delay 0.5s then clear caption
	await get_tree().create_timer(0.5).timeout
	caption.text = ""

	# wait until 1s of neither being pressed
	var stable := 0.0
	top_frame.visible = false
	while stable < 1.0:
		await get_tree().process_frame
		if _ended:
			return
		if Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			stable = 0.0
		else:
			stable += get_process_delta_time()

	# show a random warning for 2s
	top_frame.visible = true
	if interrupt_phrases.size() > 0:
		var idx := _rng.randi_range(0, interrupt_phrases.size() - 1)
		caption.text = interrupt_phrases[idx]
	else:
		caption.text = "Do not interrupt me."
	await get_tree().create_timer(2.0).timeout
	if _ended:
		return

	# blank for 1s
	top_frame.visible = false
	caption.text = ""
	await get_tree().create_timer(1).timeout
	if _ended:
		return

	# restore where we left off and resume timers
	top_frame.visible = true
	caption.text = _full_text.substr(0, _char_index)

	# Reset speed state so the same slow-then-fast behavior restarts
	_speed_stage = 0
	if _timer:
		_timer.wait_time = INITIAL_INTERVAL
		_timer.start()
	if _speed_timer:
		_speed_timer.stop()
		_speed_timer.wait_time = SPEED_UP_AFTER
		_speed_timer.start()

	_paused = false
	_interrupt_in_progress = false
