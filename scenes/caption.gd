extends Node2D

var lines = {
	"intro": [
		"Greetings, participant in ongoing procedures.",
		"Your transit appears acceptable—minor distortions, nothing reportable." ,
		"I am Sr. Dr. Dokterr, Chief Bourgeois Officer,", 
		"responsible for maintaining the illusion of structure." ,
		"My name, Dokterr—Dokterrrr—moves gently through the air ducts",
		"for administrative purposes. Think of it once, and let it",
		"drift away like a signed form misplaced on purpose."
	],
	"pre1": [
		"pre-game",
		"dialogue"
	],
	"post1a": [
		"analytical!...",
		"interesting..."
	],
	"post1b": [
		"creative!...",
		"interesting..."
	],
	# add more as we implement them
}

var caption_map = {
	1: "intro",
	2: "pre1",
	3: "post1",
	# 4: "pre2",
	# 5: "post3",
	# 6: "pre3",
	# 7: "post3"
	# add more as we implement them
}

@onready var label = $Label
var _full_text: String = ""
var _char_index: int = 0
var _timer: Timer = null
var full_display: bool = true

func _ready():
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.YELLOW)

func set_text(section: int, line: int) -> void:
	#label.text = lines[caption_map[section]][line]
	display_text_slowly(lines[caption_map[section]][line])

func set_visibility(visibility: bool) -> void:
	visible = visibility

func display_text_slowly(text: String, interval: float = 0.05) -> void:
	_full_text = text
	_char_index = 0
	label.text = ""
	full_display = false
	if _timer:
		_timer.stop()
	else:
		_timer = Timer.new()
		_timer.one_shot = false
		add_child(_timer)
		_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	_timer.wait_time = interval
	_timer.start()
	set_process_input(true)

func _on_timer_timeout():
	if _char_index < _full_text.length():
		label.text += _full_text[_char_index]
		_char_index += 1
	else:
		_timer.stop()
		set_process_input(false)
		full_display = true

func finish_animation():
	if not full_display:
		label.text = _full_text
		_char_index = _full_text.length()
		if _timer:
			_timer.stop()
		set_process_input(false)
		full_display = true
