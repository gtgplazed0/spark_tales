extends Control
class_name SelectionScreen
signal level_button_clicked(button: String)
@onready var vbox = null
@onready var scroll_cont = null
func _ready():
	if self.name == "StoriesScreen":
		scroll_cont = $ScrollContainer
		vbox = $ScrollContainer/VBoxContainer
		register_buttons()
		scroll_cont.get_v_scroll_bar().custom_minimum_size.x = 55
	
func register_buttons(): # used to register all of the screen buttons
	var buttons = []
	for first_child in vbox.get_children(): # linear search through all items
		if first_child.is_in_group("grid"):
			print(first_child)
			for second_child in first_child.get_children():
				if second_child.is_in_group("level_button"): # if the child is in the "level_button" group then add them to the array
					buttons.append(second_child)
	if buttons.size() > 0: # if there is a button in the buttons variable
		for button in buttons: # runs through each button
				button.clicked.connect(_on_button_pressed) # connect its "clicked" signal, to the on button pressed function

func _on_button_pressed(button): # a function that runs when a screen button is pressed, connected to thier "clicked" signal
	SoundFx.play("click")
	level_button_clicked.emit(button.name) # emits a signal that includes the name of the button

func reset_scroll():
	scroll_cont.set_v_scroll(0)  # Reset vertical scroll to 0
	
