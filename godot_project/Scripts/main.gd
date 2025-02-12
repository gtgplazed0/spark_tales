extends Node
@onready var SCREENS = $Screens
func _ready():
	var save_path = "user://TextModification.txt"
		# Now open the file for writing
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		print(file.get_path())
		print("File opened successfully at " + str(save_path))
	else:
		print("Failed to open file! Error code: " + str(FileAccess.get_open_error()))
