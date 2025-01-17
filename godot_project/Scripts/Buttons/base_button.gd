# This script is the base script for all texture button nodes in screen scenes. 
extends TextureButton
class_name ScreenButton # The class name of the buttons. 
# Used to check if the button pressed is a "screen" button

signal clicked(button: String) # A signal that can be emiited and caught. 
# Takes in a paramter of "Button", that is meant to be the name of the button. 

func _on_pressed(): # This function is connected to the button, and is called each time the button is pressed
	clicked.emit(self) # On the button being pressed, the signal is emited with the name of the button as a parameter
