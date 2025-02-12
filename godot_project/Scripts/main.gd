extends Node
@onready var SCREENS = $Screens
func _ready() -> void:
	var text_and_image = await DataScript.get_page_modifications(4, "S1P1")
	print(text_and_image)
