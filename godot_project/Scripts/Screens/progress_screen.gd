extends Control
@onready var STICKER_GRID = $ScrollContainer/VBoxContainer/GridContainer
var sticker_textures = []
var stickercontnum = 0
var editing = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_sticker_array()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func create_sticker_textures():
	var sticker_container = TextureRect.new()
	stickercontnum += 1
	sticker_container.name = "sticker_container_" + str(stickercontnum)
	sticker_container.add_to_group("sticker_holder")
	print(sticker_container.name)
	STICKER_GRID.add_child(sticker_container)
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
					child.texture = _new_sticker
					return _new_sticker
				else:
					print("There are no stickers")
					return
	
func now_editing():
	editing = true
	print(str(name)+ " is now editing and editing = " + str(editing))
