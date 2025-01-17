extends TextureButton
class_name LevelButton
var texture : String
signal clicked(button: String) # A signal that can be emiited and caught. 
@onready var label = $LevelName
var mouse_exit = true
var label_position_og : Vector2
var label_position_new : Vector2
func _ready():
	switch_texture("reg_level_button_texture")
	label_setup()
func switch_texture(texture_to_switch):
	match texture_to_switch:
		"reg_level_button_texture":
			texture_normal = preload("res://Assets/Textures/Buttons/LevelSelectButtons/LevelButton.png")
			texture_pressed = preload("res://Assets/Textures/Buttons/LevelSelectButtons/LevelButtonPressed.png")
			texture = "reg_level_button_texture"
		"customize_level_button_texture":
			texture_normal = preload("res://Assets/Textures/Buttons/LevelSelectButtons/CustomizeButton.png")
			texture_pressed = preload("res://Assets/Textures/Buttons/LevelSelectButtons/CustomizeButtonPressed.png")
			texture = "customize_level_button_texture"
		"new_level_button_texture":
			texture_normal = preload("res://Assets/Textures/Buttons/LevelSelectButtons/NewLevelButton.png")
			texture_pressed = preload("res://Assets/Textures/Buttons/LevelSelectButtons/NewLevelButtonPressed.png")
			texture = "new_level_button_texture"
func label_name():
	var label_num = ""
	for i in range(self.name.length()):
		var chars = str(self.name)[i]
		if chars >= '0' and chars <= '9':
			label_num += chars  # A number is found in the string
	label.text = label_num

func _process(_delta: float) -> void:
	if mouse_exit == true and self.button_pressed == false:
		label.position = label_position_og
	
func label_setup():
	label_position_og = label.position
	label_position_new = label_position_og + Vector2(15, 15)
	label_name()
	
func _on_pressed():
	clicked.emit(self) # On the button being pressed, the signal is emited with the name of the button as a parameter

func _on_button_down() -> void:
	label.position = label_position_new
	
func _on_button_up() -> void:
	if mouse_exit == false:
		label.position = label_position_og

func _on_mouse_exited() -> void:
	mouse_exit = true
	label.position = label_position_og

func _on_mouse_entered() -> void:
	mouse_exit = false
	if self.button_pressed == true:
		label.position = label_position_new
