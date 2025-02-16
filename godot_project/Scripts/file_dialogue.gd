extends Node
var file_dialog = self
@export var image_holder: TextureRect = null

func _on_file_selected(path: String) -> void:
	if path.get_extension() == "png" or path.get_extension() == "jpg" or path.get_extension() == "jpeg":
		var image = Image.new()
		image.load(path)
		var texture = ImageTexture.new()
		texture.set_image(image)
		if image_holder != null:
			image_holder.texture = texture
		print(texture)
	else:
		print("not an image")
