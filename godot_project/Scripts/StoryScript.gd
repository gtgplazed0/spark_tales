extends Control
var return_button
signal next_clicked
signal return_clicked
signal previous_clicked
signal finished_clicked
var page_text = null
var page_image = null
var story_num
var timer_finished = true
func _ready():
	timer_finished = true
	#create_timer(2)
	button_set_up()
	page_setup()
	get_image_content()
	if page_image != null:
		TextToSpeech.speak_text(page_text.text)

func button_set_up():
	for child in get_children():
		if child.is_in_group("buttons"):
			if child.name == "Next":
				child.clicked.connect(_on_next_clicked)
			elif child.name == "Return":
				child.clicked.connect(_on_return_clicked)
			elif child.name == "Previous":
				child.clicked.connect(_on_previous_clicked)
			elif child.name == "FinishStory":
				child.clicked.connect(_on_finished_clicked)
				child.add_to_group("finish_buttons")

func _on_next_clicked(_button):
	if timer_finished:
		SoundFx.play("click")
		next_clicked.emit()
func _on_return_clicked(_button):
	SoundFx.play("click")
	return_clicked.emit()
func _on_previous_clicked(_button):
	SoundFx.play("click")
	previous_clicked.emit()
	
func page_setup():
	for child in get_children():
		if child.name == "PageText":
			page_text = child
		elif child.name == "PageImage":
			page_image =  child
	story_num = get_story_num()
	return {"pi": page_image, "pt": page_text}
			
func create_timer(time):
	var my_timer = Timer.new()
	add_child(my_timer)
	# Set timer wait time (in seconds)
	my_timer.wait_time = time
	# Make sure the timer doesn't repeat
	my_timer.one_shot = true
	# Connect the timer's timeout signal
	my_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	# Start the timer
	my_timer.start()
	
func _on_timer_timeout():
	timer_finished = true
func get_text_content():
	var text_scene = page_setup()
	if text_scene.has("pt"):
		return text_scene["pt"].text
		
func get_image_content():
	var image_scene = page_setup()
	if image_scene.has("pi") and image_scene["pi"] != null:
		return image_scene["pi"].texture.resource_path
	#get text and image from database.
func _on_finished_clicked(_self):
	print("Finished story:" + str(story_num))
	finished_clicked.emit()
func get_story_num():
	var start = name.find("S") + 1
	var end = name.find("P")
	return (str(name).substr(start, end-start))
	
