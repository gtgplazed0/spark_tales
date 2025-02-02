extends HSlider # this script is the base for all audio sliders in settings 
@export var audio_bus_name: String
var audio_bus_index: int

func _ready():
	connect_to_bus()

func _on_value_changed(param_value: float):
	AudioServer.set_bus_volume_db(audio_bus_index, linear_to_db(param_value))
	print()

func connect_to_bus(): # connect the audio slider to its corresponding audio bus
	audio_bus_index = AudioServer.get_bus_index(audio_bus_name) # get the value the audio bus is set too
	value_changed.connect(_on_value_changed) 
	value = db_to_linear(AudioServer.get_bus_volume_db(audio_bus_index)) # change the sliders value to the audiobus's value
