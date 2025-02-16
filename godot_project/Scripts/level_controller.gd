extends Control
@onready var file_dialoge = $FileDialog
var page = ""
var level_type
signal return_signal
signal finished_signal(editing)
const PAGE_FOLDER_PATH = "res://Scenes/Levels/"
var story_name
var level_to_call
var correct_answer_to_pass = true
var editing = false
var level_number
var page_instance
var text_size = 100
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func start_level(level_number_param, editing_param):
	level_number = level_number_param
	editing = editing_param
	level_to_call = "Story" + level_number
	first_page(level_number)
		
func first_page(level_number):
	page = PAGE_FOLDER_PATH + "Story" + level_number + "/S" + level_number + "P1.tscn"
	story_name = "S" + level_number + "P1"
	page_instance = load_scene(story_name, level_number)
	if page_instance != null:
		correct_answer_to_pass = true
		page_instance.name = story_name
		page_instance.text_size = text_size
		add_child(page_instance)
		connect_signals(page_instance)
		page_instance.user_id = DataScript.user_id
		page_instance.editing = editing
		
		page_instance.editing_setup()
func next_page():
	if editing:
		correct_answer_to_pass = true
	if correct_answer_to_pass == true:
		correct_answer_to_pass = false
		page_handling(1)
		
func previous_page():
	page_handling(-1)
	correct_answer_to_pass = true
		
func finished_story(editing):
	if editing:
		correct_answer_to_pass = true
	if correct_answer_to_pass == true:
		correct_answer_to_pass = false
		if editing:
			finished_signal.emit(true)
		else:
			finished_signal.emit(false)
			
func return_page():
	correct_answer_to_pass = false
	return_signal.emit()
	clear_level()
		
func clear_level():
	for child in get_children():
		if child.name != "FileDialog":
			child.queue_free()

func load_scene(page_name, level_number):
	var path = PAGE_FOLDER_PATH + "Story" + str(level_number) + "/" + str(page_name) + ".tscn"
	# Load the scene from the given file path
	var packed_scene = load(path)
	if packed_scene and packed_scene is PackedScene:
		# Instantiate the scene
		var instance = packed_scene.instantiate()
		return instance
	else:
		print("Failed to load the scene at: " + path)
		return null
		
func on_answer(correct_or_inncorect):
	correct_answer_to_pass = correct_or_inncorect
	
func connect_signals(page_instance):
		page_instance.next_clicked.connect(next_page)
		page_instance.previous_clicked.connect(previous_page)
		page_instance.return_clicked.connect(return_page)
		page_instance.finished_clicked.connect(finished_story)
		page_instance.answer.connect(on_answer)
		page_instance.image_clicked.connect(_on_image_clicked)
func now_editing():
	editing = true
func stop_editing():
	editing = false
	
func page_handling(add_or_sub):
	var has_button = false
	var has_finish_buttons = false
	var find_match = page.rfind("P")
	var find_name = story_name.rfind("P")
	story_name[find_name+1] = str(int(story_name[find_name+1]) + add_or_sub)
	page_instance = load_scene(story_name, level_number)
	page_instance.name = story_name
	if page_instance != null:
		clear_level()
		page_instance.text_size = text_size
		add_child(page_instance)
		connect_signals(page_instance)
		page_instance.user_id = DataScript.user_id
		page_instance.editing = editing
		page_instance.user_id = DataScript.user_id
		page_instance.editing_setup()
func _on_image_clicked():
	if editing == true:
		file_dialoge.popup()
		file_dialoge.image_holder = page_instance.page_image
		await file_dialoge.path_gotten
		page_instance.image_path = file_dialoge.image_path
