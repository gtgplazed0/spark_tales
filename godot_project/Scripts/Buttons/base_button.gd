extends TextureButton # This script is the base script for texture button nodes in screen scenes. 
class_name ScreenButton # The class name of the specific buttons. 
signal clicked(button: String) # Takes in the name of the button as a parameter

func _on_pressed(): # when the button is pressed ( connected to each node )
	clicked.emit(self) #emit the button name
