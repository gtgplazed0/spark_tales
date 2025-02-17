extends Control
@onready var STICKER_GRID = $ScrollContainer/VBoxContainer/GridContainer
var sticker_textures = []
var stickercontnum = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_sticker_array()
	get_stickers()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func create_sticker_textures():
	var sticker_container = TextureRect.new()
	stickercontnum += 1
	sticker_container.name = "sticker_container_" + str(stickercontnum)
	sticker_container.add_to_group("sticker_holder")
	STICKER_GRID.add_child(sticker_container)
	return sticker_container
	
func get_stickers():
	if DataScript.user_id != 0 or DataScript.user_id != 1:
		await DataScript.get_stickers(DataScript.user_id)
		var stickers = DataScript.stickers_gotten
		if stickers != null:
			for sticker in stickers["stickers"]:
				var container = create_sticker_textures()
				await DataScript.get_sticker_image(sticker["image_url"], sticker["ext"])
				var sticker_texture = DataScript.sticker_from_get_image
				print("sticker texture: " + str(sticker_texture))
				if DataScript.get_sticker_worked == true:
					print("get stickers worked")
					for child in STICKER_GRID.get_children():
						if child.is_in_group("sticker_holder"):
							if child.texture == null:
									child.texture = sticker_texture
	else:
		var stickers = get_all_stickers()
		for sticker in stickers:
			var container = create_sticker_textures()
			container.texture = sticker
func create_sticker_array():
	var directory_path = "res://Stickers/"
	var sticker_directory = DirAccess.open(directory_path)
	if sticker_directory:
		sticker_directory.list_dir_begin()
		var file_name = sticker_directory.get_next()
		while file_name != "":
		# Check if it's a file (and not a folder) and has an image extension
			if !sticker_directory.current_is_dir():
				if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".webp"):
				# Load the texture and add it to the array
					var texture = load(directory_path + "/" + file_name)
					if texture:
						sticker_textures.append(texture)
					else:
						print("unable to load texture")
			else:
				print("not a sticker file.")
			file_name = sticker_directory.get_next()  # Move to the next file
		sticker_directory.list_dir_end()
	else:
		print("Failed to open the directory!")
func new_sticker():
	create_sticker_textures()
	for child in STICKER_GRID.get_children():
		if child.is_in_group("sticker_holder"):
			if child.texture == null:
				if sticker_textures.size() != 0:
					var _new_sticker = sticker_textures.pick_random()
					print(str(_new_sticker.get))
					child.texture = _new_sticker
					if DataScript.user_id != 0 or DataScript.user_id != 1:
						var path = child.texture.resource_path 
						DataScript.send_sticker(DataScript.user_id, path)
					elif DataScript.user_id == 1:
						var image: Image = child.texture.get_image()
						var extension = child.texture.resource_path.get_extension()
						print(extension)
						if image:
								image.save_png("user://Sticker" + str(child.name) + ".png")
					return _new_sticker
				else:
					print("There are no stickers")
					return
func get_all_stickers() -> Array:
	var stickers := []
	var dir := DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") and file_name.begins_with("Sticker"):
				var image = Image.new()
				var err = image.load("user://" + file_name)
				var texture = ImageTexture.new()
				texture.create_from_image(image)
				stickers.append(texture)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open user directory")
	return stickers
