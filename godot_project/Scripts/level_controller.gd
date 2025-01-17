extends Control
var page = ""
var level_type
signal return_signal
var page_folder_path = "res://Scenes/Levels/"
var story_name
var level_to_call
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func start_level(level_number):
	level_to_call = "Story" + level_number
	first_page(level_number)
		
func first_page(level_number):
	page = page_folder_path + "Story" + level_number + "/S" + level_number + "P1.tscn"
	story_name = "S" + level_number + "P1"
	var page_instance = load_scene(page)
	if page_instance != null:
		page_instance.name = story_name
		add_child(page_instance)
		page_instance.next_clicked.connect(next_page)
		page_instance.return_clicked.connect(return_page)
	
func next_page():
	var has_button = false
	var find_match = page.rfind("P")
	var find_name = story_name.rfind("P")
	page[find_match+1] = str(int(page[find_match+1]) + 1)
	story_name[find_name+1] = str(int(story_name[find_name+1]) + 1)
	var page_instance = load_scene(page)
	page_instance.name = story_name
	if page_instance != null:
		clear_level()
		add_child(page_instance)
		for child in page_instance.get_children():
			if child.is_in_group("buttons"):
				has_button = true
		if has_button == true:
			page_instance.next_clicked.connect(next_page)
			page_instance.previous_clicked.connect(previous_page)
			page_instance.return_clicked.connect(return_page)
		
func previous_page():
	var has_button = false
	var find_match = page.rfind("P")
	var find_name = story_name.rfind("P")
	page[find_match+1] = str(int(page[find_match+1]) - 1)
	story_name[find_name+1] = str(int(story_name[find_name+1]) - 1)
	var page_instance = load_scene(page)
	page_instance.name = story_name
	if page_instance != null:
		clear_level()
		add_child(page_instance)
		for child in page_instance.get_children():
			if child.is_in_group("buttons"):
				has_button = true
		if has_button == true:
			page_instance.next_clicked.connect(next_page)
			page_instance.previous_clicked.connect(previous_page)
			page_instance.return_clicked.connect(return_page)
		
func return_page():
	return_signal.emit()
	clear_level()
		
func clear_level():
	for child in get_children():
		child.queue_free()

func load_scene(file_path):
	# Load the scene from the given file path
	var packed_scene = load(file_path)
	if packed_scene and packed_scene is PackedScene:
		# Instantiate the scene
		var instance = packed_scene.instantiate()
		return instance
	else:
		print("Failed to load the scene at: " + file_path)
		return null
