extends HSlider # this script is the base for all audio sliders in settings 
@export var AUDIO_BUS_NAME: String
var AUDIO_BUS_INDEX: int

func _ready():
	connect_to_bus()

func _on_value_changed(param_value: float):
	AudioServer.set_bus_volume_db(AUDIO_BUS_INDEX, linear_to_db(param_value))
	print()

func connect_to_bus(): # connect the audio slider to its corresponding audio bus
	AUDIO_BUS_INDEX = AudioServer.get_bus_index(AUDIO_BUS_NAME) # get the value the audio bus is set too
	value_changed.connect(_on_value_changed) 
	value = db_to_linear(AudioServer.get_bus_volume_db(AUDIO_BUS_INDEX)) # change the sliders value to the audiobus's value
