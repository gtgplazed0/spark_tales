extends Control
var return_button = null
var popup = null
var page_text: Label
var page_image: TextureRect
var image_path = null
var story_num = 0
var timer_finished = true
var y_or_n_clicked = false
var editing = false # false
var user_id = DataScript.user_id
var text_edit: TextEdit
var self_path
var save_edit_button
var text_size
signal answer(correct_or_incorrect)
signal next_clicked
signal return_clicked
signal previous_clicked
signal finished_clicked(editing)
signal image_clicked
func _ready():
	await page_setup()
	set_process_unhandled_input(true)
	print(name)
	button_set_up()
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
	buttons_pressed_handling(next_clicked, null)

func _on_return_clicked(_button):
	buttons_pressed_handling(return_clicked, null)
	
func _on_previous_clicked(_button):
	buttons_pressed_handling(previous_clicked, null)
	
func _on_finished_clicked(_self):
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
	user_id = DataScript.user_id
	for child in get_children():
		match child.name:
			"PageText":
				page_text = child
				page_text.label_settings.font_size = text_size
			"PageImage":
				page_image =  child
			"Popup":
				popup = child
				popup.visible = false
			"SaveEditButton":
				save_edit_button = child
				save_edit_button.visible = false
	story_num = get_story_num()
	if int(user_id)  == 1:
		print("The user id is being setup as guest: " + str(user_id))
		if FileAccess.file_exists("user://TextModification" + str(name) + ".txt"):
			print("file exists")
			var file = FileAccess.open("user://TextModification" + str(name) + ".txt", FileAccess.READ)
			if file:
				var stored_text = file.get_var()
				file.close()
				page_text.text = stored_text
		if FileAccess.file_exists("user://ImageModification" + str(name) + ".png"):
			print("image file exists")
			var image = Image.new()
			image.load("user://ImageModification" + str(name) + ".png")
			var texture = ImageTexture.new()
			texture.set_image(image)
			print(texture)
			if texture:
				print("texture worked")
				page_image.texture = texture
	else:
		print("the User id is being setup as " + str(user_id))
		var text_and_url= await DataScript.get_page_modifications(user_id, name)
		if text_and_url["worked"] == true:
			print(text_and_url["text"])
			page_text.text = text_and_url["text"]
			var url = text_and_url["url"]
			var ext = DataScript.extention
			var texture = await DataScript.get_image(url, ext)
			if DataScript.get_image_worked == true:
				page_image.texture = texture
		else:
			print("unable to get page modifications. No modifications or error.")
func get_text_content():
	if page_text != null:
		return page_text.text

func get_image_content():
	if page_image != null:
		print("Page Image Texture = "+str(page_image.texture))
		print("Resource path = " + page_image.texture.resource_path)
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
func show_text_edit():
	if page_text != null:
		text_edit = TextEdit.new()  # Holds the dynamically created TextEdit
		text_edit.size = page_text.size
		text_edit.position = page_text.position
		text_edit.text = page_text.text
		add_child(text_edit)
		move_child(text_edit, 2)
		text_edit.show()
		page_text.hide()
func editing_setup():
	if editing:
		save_edit_button.visible = true
		
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("hello!!!")
			if text_edit:
				if text_edit.get_global_rect().has_point(event.position):
					print("on text edit")
				else:
					editing_takedown()
func editing_takedown():
	if text_edit:
		page_text.text = text_edit.text
		page_text.show()
		text_edit.queue_free()  # Remove TextEdit from scene
		text_edit = null  # Reset reference
func save_page():
	if int(user_id) == 1:
		var file_text = FileAccess.open(("user://TextModification" + str(name) + ".txt"), FileAccess.WRITE)
		var image: Image = page_image.texture.get_image()
		var extension = page_image.texture.resource_path.get_extension()
		print(extension)
		if file_text:
			file_text.store_var(page_text.text)
		else:
			print("Failed to open file! Error code: " + str(FileAccess.get_open_error()))
		file_text.close()
		if image:
				image.save_png("user://ImageModification" + str(name) + ".png")
	else:
		var image
		if image_path == null:
			image = get_image_content()
		else:
			image = image_path
		DataScript.send_page(user_id, name, page_text.text, image)
func _on_page_image_edit_button_pressed() -> void:
	image_clicked.emit()
func _on_page_text_edit_button_pressed() -> void:
	if editing:
		show_text_edit()
func _on_save_edit_button_pressed() -> void:
	editing_takedown()
	save_page()
