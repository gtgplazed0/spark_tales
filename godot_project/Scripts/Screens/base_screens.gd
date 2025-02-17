extends Control
class_name SelectionScreen
signal level_button_clicked(button: String)
@onready var VBOX = null # vertial box container in story screen
@onready var SCROLL_BAR = null # scroll bar
var num_of_levels = 0
func _ready():
	if self.name == "StoriesScreen":
		set_up_stories()
func register_buttons(): # used to register all of the screen buttons
	var buttons = []
	for child in VBOX.get_children(): # linear search through all children in current node
		if child.is_in_group("grid"):
			for grand_child in child.get_children(): # linear search through all children of the current child iteration
				if grand_child.is_in_group("level_button"): # if the child is in the "level_button" group  add them to the array
					buttons.append(grand_child)
					num_of_levels += 1
	if buttons.size() > 0: # if theres button(s) in the buttons variable connect them to the button pressed function
		for button in buttons:
				button.clicked.connect(_on_button_pressed)

func _on_button_pressed(button): # a function that runs when a screen button is pressed, connected to thier "clicked" signal
	level_button_clicked.emit(button.name) # emit the name of the button

func reset_scroll():
	SCROLL_BAR.set_v_scroll(0)  # Reset vertical scroll to 0
	
func set_up_stories(): # set up te stories screen
	SCROLL_BAR = $ScrollContainer
	VBOX = $ScrollContainer/VBoxContainer
	register_buttons()
	SCROLL_BAR.get_v_scroll_bar().custom_minimum_size.x = 55
