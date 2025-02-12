extends Node
@onready var SCREENS = $Screens
func _ready() -> void:
	var text_and_image = await DataScript.get_page_modifications(4, "S1P1")
	var image = Image.new()
	var extention = text_and_image["extension"]
	var image_bytes = text_and_image["image"]
	if extention == "png":
		var err = image.load_png_from_buffer(image_bytes)
	elif extention == "jpeg" or extention == "jpg":
		var err = image.load_jpg_from_buffer(image_bytes)
		if err != null or err!= OK:
			var texture = ImageTexture.create_from_image(image)
			print(texture)
			print(text_and_image["text"])
