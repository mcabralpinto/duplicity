extends Node2D

var log_path := "res://logs/%s.csv" % Time.get_datetime_string_from_system().replace(":", "-")
var user_id := DirAccess.get_files_at("res://logs/").size()
var log := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func log_custom(vars, category, type, detail) -> void:
	if not log:
		return
	var file
	var vars_str = ""
	
	if FileAccess.file_exists(log_path):
		file = FileAccess.open(log_path, FileAccess.READ_WRITE)
		
		# If vars is empty, try to fetch the last vars_str from the file
		if vars.is_empty():
			var content = file.get_as_text()
			if content != "":
				var lines = content.strip_edges().split("\n")
				if lines.size() > 0:
					var last_line = lines[lines.size() - 1]
					var columns = last_line.split(",")
					# Assuming the CSV structure is: user_id, "(v1, v2, v3)", timestamp, category, type, detail
					# The vars_str is the second column (index 1), but since it contains commas inside quotes or parens, 
					# simple splitting might be fragile if not careful. 
					# Based on your previous format "(%s, %s, %s)", it likely gets split into multiple columns by a simple comma split.
					# Let's reconstruct it or grab the specific indices if the format is rigid.
					# Format: user_id, (v1, v2, v3), timestamp...
					# Split by comma: [0]=id, [1]="(v1", [2]=" v2", [3]=" v3)", [4]=timestamp...
					if columns.size() >= 4:
						vars_str = "%s,%s,%s" % [columns[1], columns[2], columns[3]]
		
		file.seek_end()
	else:
		file = FileAccess.open(log_path, FileAccess.WRITE)
		
	if file:
		if not vars.is_empty():
			vars_str = '"(%s, %s, %s)"' % vars
			
		var timestamp = Time.get_datetime_string_from_system()
		file.store_line("%s,%s,%s,%s,%s,%s" % [user_id, vars_str, timestamp, category, type, detail])
		file.close()
