extends Node2D

var lines = {
	"prelude":[
		"Hey! You! Come on in!..."
	],
	"intro": [
		"Greetings, participant in ongoing procedures.",
		"Your transit appears acceptable - minor distortions, nothing reportable." ,
		"I am ~~ Sr. Dr. Dokterr ~~, Chief Bourgeois Officer,", 
		"responsible for maintaining the illusion of structure." ,
		"My name - Sirrr - Dokterr - Dokterrrrrrrr -", 
		"it moves gently through the air ducts for administrative purposes."
	],
	"pre1": [
		"FIRST QUESTION!",
		"You know, sometimes, something whirls inside of my body, a buzz",
		"like the scatter of a thousand bugs, and all I want to do",
		"is dance to the sweet rhythm... will you assist in these occasions?",
		"(keep up with the rhythm)"
	],
	"post1a": [
		"I've heard enough.",
		"I found that to be... somewhat... moving on..."
	],
	"post1b": [
		"Astonishing! Bravo! I see we'd make a pompous pair.",
		"It would be like uniting a frail little monkey with a banana...",
		"It's a shame, but we must finish conducting this interview."
	],
	"post1c": [
		"Stop! Stop! I've heard enough...",
		"It pains me to see such discomfort when wielding one's own body.",
		"Anyway..."
	],
	"pre2": [
		"Let me ask you something else, more addequate to your level.",
		"Could you kindly and circularly explain how history has managed",
		"to loop back into itself like a misplaced file, reapproved without review,",
		"reflecting its cyclical nature?",
		"(draw a perfect circle)"
	],
	"post2a": [
		"That's quite an analytical way to phrase it!...",
		"An... interesting... response nonetheless..."
	],
	"pre3": [
		"Let's talk hunger. Drive. Power. But mostly hunger.",
		"Here at ~~ Company™ ~~ we are hungry for hungry individuals...",
		"Hungry for work, hungry for paperwork, hungry for life.",
		"My brazillian bird Coxinha, for example, is always starving.",
		"What I ask you, my dear, is how you will saciate our hunger.",
		"(feed the egg)"
	],
	"post3a": [
		"Wonderful! That got me really egged on.",
		"I can see you perform all sorts of hunger-related tasks. Anyway..."
	],
	"post3b": [
		"You just can't seem to deal with the most simple of problems.",
		"Such a lack of mental coordination. Moving on."
	],
	"post3c": [
		"This was truly a spectacle to see. You started off well,",
		"but it's like you lost your creativity midway through.",
		"Such a lack of mental coordination. Moving on."
	],
	"pre4": [
		"Let me let you in on a little secret, my dear.",
		"I miss the old days, where we'd stay at home all day in our pajamas...",
		"Our home was our world! We'd forgotten about anything else.",
		"But now everything's open again... anyway... my question is...",
		"Would you work online for half the pay?",
		"(handle the online meeting professionally)"
	],
	"post4a": [
		"You're a great listener... maybe too great... anyway..."
	],
	"post4b": [
		"You know these meetings are recorded, right???",
		"I'll have to send one of my minions to edit the footage... embarassing!"
	],
	"preq1": [
		"By the way, how do you think you're doing?"
	],
	"postq1a": [
		"That's a good one! Oh... you're serious?",
		"Hmmm..."
	],
	"postq1b": [
		"Well, I can't tell you that! Moving on!"
	],
	"preq2": [
		"You seem a little distracted... are you taking this seriously?"
	],
	"postq2a": [
		"Wow... I... wasn't expecting that... anyway..."
	],
	"postq2b": [
		"Well get your head in the game. This is the real world now.",
		"Moving on."
	],
	"predelib": [
		"I've collected all the information I need.",
		"Now I need to ponder on your case...",
		"Excuse me for a second. Coxinha will keep you company.",
	],
	"delib":[
		"You better not take my job."
	],
	"outroa": [
		"Now for your final verdict...",
		"You looked like a pigman at times, others you were dumb as a sphynx.",
		"Sometimes rude and sometimes naive in your behaviour.",
		"Beast. Unappealing.",
		"Please go back to 4th grade...",
		"REJECTED!!!"
	],
	"outrob": [
		"Now for your final verdict...",
		"I am quite surprised by your behaviour.",
		"You were both emotionally and rationally intelligent.",
		"AMAZING!!!",
		"I want you to be on our team!",
		"HIRED!!!"
	]
}

var caption_map = {
	1: "intro",
	2: "pre1",
	3: "post1",
	4: "pre2",
	5: "post2",
	6: "pre3",
	7: "post3",
	8: "outro"
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
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.YELLOW)
	
	var font = load("res://assets/PixelatedElegance.ttf")
	if font:
		label.add_theme_font_override("font", font)

func set_text(section: int, line: int) -> void:
	var key = caption_map[section]
	if lines.has(key):
		display_text_slowly(lines[key][line])
	else:
		print("ERROR: Key '%s' not found in lines dictionary." % key)
		print("Available keys: ", lines.keys())

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
