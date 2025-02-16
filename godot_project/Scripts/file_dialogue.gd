extends Node
var file_dialog = self
var extension
var image_path
signal path_gotten
@export var image_holder: TextureRect = null
func _on_file_selected(path: String) -> void:
	image_path = path
	path_gotten.emit()
	extension = path.get_extension()
	if extension == "png" or extension == "jpg" or extension == "jpeg":
		var image = Image.new()
		image.load(path)
		var texture = ImageTexture.new()
		texture.set_image(image)
		if image_holder != null:
			image_holder.texture = texture
		print(texture)
	else:
		print("not an image")
