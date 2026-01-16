extends Node2D

var animations = {
	"prelude": [
		"speaking",
		"speaking",
		"speaking"
	],
	"intro": [
		"greeting_speaking",
		"greeting_speaking",
		"greeting_speaking",
		"greeting_speaking",
		"greeting_speaking",
		"greeting_speaking"
	],
	"pre1": [
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"idle"
	],
	"post1a": [
		"speaking",
		"speaking"
	],
	"post1b": [
		"happy_speaking",
		"happy_speaking",
		"speaking"
	],
	"post1c": [
		"upset_speaking",
		"upset_speaking",
		"speaking"
	],
	"pre2": [
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"idle"
	],
	"post2a": [
		"speaking",
		"happy_speaking",
	],
	"post2b": [
		"upset_speaking",
		"upset_speaking",
	],
	"pre3": [
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"idle"
	],
	"post3a": [
		"happy_speaking",
		"upset_speaking",
	],
	"post3b": [
		"upset_speaking",
		"upset_speaking",
		"upset_speaking",
		"upset_speaking"
	],
	"post3c": [
		"upset_speaking",
		"upset_speaking"
	],
	"post3d": [
		"speaking",
		"happy_speaking"
	],
	"pre4": [
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"speaking",
		"idle"
	],
	"post4a": [
		"happy_speaking",
		"happy_speaking"
	],
	"post4b": [
		"upset_speaking",
		"upset_speaking"
	],
	"post4c": [
		"speaking",
		"speaking",
		"upset_speaking"
	],
	"preq1": [
		"idle",
		"speaking"
	],
	"postq1a1": [
		"happy_speaking"
	],
	"postq1a2": [
		"upset_speaking"
	],
	"postq1b": [
		"happy_speaking" ,
		"speaking",
		"speaking"
	],
	"postq1c": [
		"speaking"
	],
	"preq2": [
		"idle",
		"speaking"
	],
	"postq2a1": [
		"happy_speaking",
	],
	"postq2b": [
		"speaking",
		"speaking"
	],
	"postq2c": [
		"speaking"
	],
	"postq2d": [
		"idle",
		"speaking"
	],
	"postq2e": [
		"speaking"
	],
	"predelib": [
		"speaking",
		"speaking",
		"speaking",
		"speaking",
	],
	"delib": [
		"gone",
		"idle",
	],
	"outroa": [
		"speaking",
		"upset_speaking",
		"upset_speaking",
		"upset_speaking",
		"upset_speaking",
	],
	"outrob": [
		"speaking",
		"speaking",
		"speaking",
		"happy_speaking",
		"happy_speaking",
		"happy_speaking"
	]
}

var animation_map = {
	0: "prelude",
	1: "intro",
	2: "pre1",
	3: "post1",
	4: "pre2",
	5: "post2",
	6: "preq2",
	7: "postq2",
	8: "pre3",
	9: "post3",
	10: "pre4",
	11: "post4",
	12: "preq1",
	13: "postq1",
	14: "predelib",
	15: "delib",
	16: "outro"
}

@onready var anim: AnimatedSprite2D = $animation

# Optional per-animation loop segments in seconds: Vector2(start, end)
var _current_animation: String = ""

func _ready() -> void:
	set_process(true)
	anim.z_index = -30
	set_animation("idle")

func section_animation(section: int, line: int) -> void:
	if section > 16:
		return
	var key = animation_map[section]
	if key in animations:
		var animation = animations[key][line]
		var frames = anim.sprite_frames
		if animation.begins_with("happy") and not _current_animation.begins_with("happy"):
			var pre_name = "happy_pre_speak"
			var prev_loop = false
			if frames and frames.has_animation(pre_name):
				prev_loop = frames.get_animation_loop(pre_name)
				frames.set_animation_loop(pre_name, false)
			set_animation(pre_name)
			await anim.animation_finished
			if frames and frames.has_animation(pre_name):
				frames.set_animation_loop(pre_name, prev_loop)
		if animation.begins_with("upset") and not _current_animation.begins_with("upset"):
			var pre_name2 = "upset_pre_speak"
			var prev_loop2 = false
			if frames and frames.has_animation(pre_name2):
				prev_loop2 = frames.get_animation_loop(pre_name2)
				frames.set_animation_loop(pre_name2, false)
			set_animation(pre_name2)
			await anim.animation_finished
			if frames and frames.has_animation(pre_name2):
				frames.set_animation_loop(pre_name2, prev_loop2)
		if animation.begins_with("greeting") and not _current_animation.begins_with("greeting"):
			var pre_name2 = "greeting"
			var prev_loop2 = false
			if frames and frames.has_animation(pre_name2):
				prev_loop2 = frames.get_animation_loop(pre_name2)
				frames.set_animation_loop(pre_name2, false)
			set_animation(pre_name2)
			await anim.animation_finished
			if frames and frames.has_animation(pre_name2):
				frames.set_animation_loop(pre_name2, prev_loop2)
		if section == 10 and line == 4:
			var pre_name = "introducing_coxinha"
			var prev_loop = false
			if frames and frames.has_animation(pre_name):
				prev_loop = frames.get_animation_loop(pre_name)
				frames.set_animation_loop(pre_name, false)
			set_animation(pre_name)
			await anim.animation_finished
			if frames and frames.has_animation(pre_name):
				frames.set_animation_loop(pre_name, prev_loop)
			animation = "coxinha"
		if section == 15 and line == 0:
			var pre_name = "getting_up"
			var prev_loop = false
			if frames and frames.has_animation(pre_name):
				prev_loop = frames.get_animation_loop(pre_name)
				frames.set_animation_loop(pre_name, false)
			set_animation(pre_name)
			await anim.animation_finished
			if frames and frames.has_animation(pre_name):
				frames.set_animation_loop(pre_name, prev_loop)
		if section == 15 and line == 1:
			var pre_name = "getting_down"
			var prev_loop = false
			if frames and frames.has_animation(pre_name):
				prev_loop = frames.get_animation_loop(pre_name)
				frames.set_animation_loop(pre_name, false)
			set_animation(pre_name)
			await anim.animation_finished
			if frames and frames.has_animation(pre_name):
				frames.set_animation_loop(pre_name, prev_loop)
		set_animation(animation)

func set_animation(animation: String) -> void:
	print(animation, " ", _current_animation)
	if animation == _current_animation:
		return
	if animation == "idle":
		if _current_animation.begins_with("greeting"):
			animation = "greeting_idle"
		elif _current_animation.begins_with("happy"):
			animation = "happy_idle"
		elif _current_animation.begins_with("upset"):
			animation = "upset_idle"
	_current_animation = animation
	anim.play(animation)
