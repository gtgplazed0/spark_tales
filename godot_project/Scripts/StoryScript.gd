extends Control

var return_button = null
var popup = null
var page_text = null
var page_image = null
var story_num = 0
var timer_finished = true
var y_or_n_clicked = false
var editing = false
var user_id = 1
var text_edit: TextEdit
var self_path
signal answer(correct_or_incorrect)
signal next_clicked
signal return_clicked
signal previous_clicked
signal finished_clicked(editing)
func _ready():
	set_process_unhandled_input(true)
	print(name)
	button_set_up()
	page_setup()
	if page_text != null:
			TextToSpeech.speak_text(get_text_content())
	get_image_content()
			
func button_set_up():
	for child in get_children():
		if child.is_in_group("buttons"):
			match child.name:
				"Next":
					child.clicked.connect(_on_next_clicked)
				"Return":
					child.clicked.connect(_on_return_clicked)
				"Previous":
					child.clicked.connect(_on_previous_clicked)
				"FinishStory":
					child.clicked.connect(_on_finished_clicked)
				"YesButton", "NoButton":
					child.clicked.connect(_on_yes_or_no)

func _on_next_clicked(_button):
	print(editing)
	if editing:
		save_page()
	buttons_pressed_handling(next_clicked, null)
	
func _on_return_clicked(_button):
	buttons_pressed_handling(return_clicked, null)
	
func _on_previous_clicked(_button):
	if editing:
		save_page()
	buttons_pressed_handling(previous_clicked, null)
	
func _on_finished_clicked(_self):
	if editing == true:
		save_page()
	buttons_pressed_handling(finished_clicked, editing)
	
func _on_yes_or_no(yes_or_no):
	var button_name
	button_name = "YesButton" if yes_or_no == "yes" else "NoButton"
	for child in get_children():
		if child.name == button_name:
			var is_correct = child.is_in_group("correct")
			buttons_pressed_handling(answer, true if is_correct else false)
			show_popup("correct" if is_correct else "incorrect")
				
			
func buttons_pressed_handling(signal_to_emit, emit_param):
	SoundFx.play("click")
	if emit_param != null:
		signal_to_emit.emit(emit_param)
	else:
		signal_to_emit.emit()
func page_setup():
	for child in get_children():
		match child.name:
			"PageText":
				page_text = child
			"PageImage":
				page_image =  child
			"Popup":
				popup = child
				popup.visible = false
	if user_id == 1:
		var save_path = "user://TextModification" + str(name) + ".txt"
		if FileAccess.file_exists(save_path):
			print("file exists")
			var file = FileAccess.open(save_path, FileAccess.READ)
			if file:
				var stored_text = file.get_var()
				file.close()
				page_text.text = stored_text
		else:
			var image = Image.new()
			var text_and_image = await DataScript.get_page_modifications(4, "S1P1")
			page_text.text = text_and_image["text"]
			var extention = text_and_image["extension"]
			var image_bytes = text_and_image["image"]
			if extention == "png":
				var err = image.load_png_from_buffer(image_bytes)
			elif extention == "jpeg" or extention == "jpg":
				var err = image.load_jpg_from_buffer(image_bytes)
				if err != null or err!= OK:
					var texture = ImageTexture.create_from_image(image)
					page_image = texture
	story_num = get_story_num()

func get_text_content():
	if page_text != null:
		return page_text.text

func get_image_content():
	if page_image != null:
		return page_image.texture.resource_path

func get_story_num():
	var start = name.find("S") + 1
	var end = name.find("P")
	return (str(name).substr(start, end-start))

func show_popup(corr_or_incorr):
	var anim_player
	if popup:
		for child in popup.get_children():
			match child.name:
				"Text":
					child.text = "Correct!" if corr_or_incorr == "correct" else "Incorrect. Please try again!"
					for grandchild in child.get_children():
						grandchild.text = "Correct!" if corr_or_incorr == "correct" else "Incorrect. Please try again!"
				"AnimationPlayer":
					anim_player = child
		popup.visible = true
	if anim_player:
		anim_player.play("RESET")
		anim_player.play("fade")
		await anim_player.animation_finished  # Waits for the animation to finish
		popup.visible = false

func _on_popup_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			popup.visible = false
			
func is_editing():
	if editing == true:
		editing_setup()
		
func editing_setup():
	if page_text != null:
		text_edit = TextEdit.new()  # Holds the dynamically created TextEdit
		text_edit.size = page_text.size
		text_edit.position = page_text.position
		text_edit.text = page_text.text
		add_child(text_edit)
		move_child(text_edit, 2)
		text_edit.show()
		page_text.hide()
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("hello!!!")
			if text_edit:
				if text_edit.get_global_rect().has_point(event.position):
					print("on text edit")
				else:
					save_page()
func editing_takedown():
	if text_edit:
		page_text.text = text_edit.text
		page_text.show()
		text_edit.queue_free()  # Remove TextEdit from scene
		text_edit = null  # Reset reference
func save_page():
	print(user_id)
	editing_takedown()
	if int(user_id) == 1:
		print("it is editing her")
		#save to file system or update if already there
		var save_path = "user://TextModification" + str(name) + ".txt"
		# Now open the file for writing
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if file:
			file.store_var(page_text.text)
		else:
			print("Failed to open file! Error code: " + str(FileAccess.get_open_error()))
			print(file.get_path())
			print("file opened at " + str(save_path))
			var stored_text = page_text.text
			file.store_var(stored_text)
			file.close()
	else:
		var image = get_image_content()
		DataScript.send_page(user_id, name, page_text.text, image)
