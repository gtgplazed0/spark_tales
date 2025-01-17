extends Control
var return_button
signal next_clicked
signal return_clicked
signal previous_clicked
var page_text = null
var page_image = null
func _ready():
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

func _on_next_clicked(_button):
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
	return {"pi": page_image, "pt": page_text}
			
func get_text_content():
	var text_scene = page_setup()
	if text_scene.has("pt"):
		return text_scene["pt"].text
		
func get_image_content():
	var image_scene = page_setup()
	if image_scene.has("pi"):
		return image_scene["pi"].texture.resource_path
	#get text and image from database.
