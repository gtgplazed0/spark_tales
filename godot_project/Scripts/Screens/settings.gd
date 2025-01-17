extends Control
var TTSon = false
@onready var text_to_speech_button = $SettingsTexture/TextToSpeechBox/TextToSpeechButton
func _ready() -> void:
	text_to_speech_button.texture_normal = load("res://Assets/Textures/Buttons/Settings/UnCheckedButton.png")
	text_to_speech_button.texture_pressed = load("res://Assets/Textures/Buttons/Settings/UnCheckedButtonPressed.png")
func _on_texture_button_pressed() -> void:
	SoundFx.play("click")
	TTSon = !TTSon
	if !TTSon:
		text_to_speech_button.texture_normal = load("res://Assets/Textures/Buttons/Settings/UnCheckedButton.png")
		text_to_speech_button.texture_pressed = load("res://Assets/Textures/Buttons/Settings/UnCheckedButtonPressed.png")
		for child in text_to_speech_button.get_children():
			child.queue_free()
		var tts_label = preload("res://Scenes/notif_label.tscn").instantiate()
		tts_label.name = "NotifLabelTTSOFF"
		text_to_speech_button.add_child(tts_label)
		for child in text_to_speech_button.get_children():
			if child.name == "NotifLabelTTSOFF":
				TextToSpeech.tts_enabled = false
				child.text = "Text-To-Speech is Turned Off."
				fade_text(child)
	else:
		text_to_speech_button.texture_normal = load("res://Assets/Textures/Buttons/Settings/CheckedButton.png")
		text_to_speech_button.texture_pressed = load("res://Assets/Textures/Buttons/Settings/CheckedButtonPressed.png")
		for child in text_to_speech_button.get_children():
			child.queue_free()
		var tts_label = preload("res://Scenes/notif_label.tscn").instantiate()
		tts_label.name = "NotifLabelTTSON"
		text_to_speech_button.add_child(tts_label)
		for child in text_to_speech_button.get_children():
			if child.name == "NotifLabelTTSON":
				child.text = "Text-To-Speech is Turned On. May not work on Web versions."
				TextToSpeech.tts_enabled = true
				TextToSpeech.speak_text("Text-To-Speech is Turned On. May not work on certain web versions or OS types.")
				fade_text(child)
		
func fade_text(label: Label):
	var end_color = label.modulate
	end_color.a = 0.0  # Fully transparent
	# Create and start the tween
	var tween = create_tween()
	tween.tween_property(label, "modulate", end_color, 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
