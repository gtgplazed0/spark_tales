extends Control
class_name LevelTemplate
signal template_back_clicked(button_name)
@onready var level_num = $LevelNum
func _on_back_button_pressed() -> void:
	template_back_clicked.emit(self)


func setup_level(number):
	level_num.text = "level " + str(number)
	
