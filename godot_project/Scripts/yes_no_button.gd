extends TextureButton
signal yes_clicked
signal clicked(name)

func _on_pressed() -> void:
	if self.name == "YesButton":
		clicked.emit("yes")
	else:
		clicked.emit("no")
