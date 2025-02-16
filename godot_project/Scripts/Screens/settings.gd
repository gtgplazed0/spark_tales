extends Control
var TTSon = false
var text_size = 120
@onready var TEXT_TO_SPEECH_BUTTON = $SettingsTexture/TextToSpeechBox/TextToSpeechButton
@onready var TEXT_SIZE_SLIDER = $SettingsTexture/TextSizeLabel/TextSizeSlider
signal text_size_signal(text_size)
const CHECKED_TEXTURES = {
	"normal": "res://Assets/Textures/Buttons/Settings/CheckedButton.png",
	"pressed": "res://Assets/Textures/Buttons/Settings/CheckedButtonPressed.png"
}
const UNCHECKED_TEXTURES = {
	"normal": "res://Assets/Textures/Buttons/Settings/UnCheckedButton.png",
	"pressed": "res://Assets/Textures/Buttons/Settings/UnCheckedButtonPressed.png"
}
const NOTIF_LABEL_SCENE = preload("res://Scenes/notif_label.tscn")
func _ready() -> void:
	_update_button_state()
	setup_text_size()
func _on_texture_button_pressed() -> void:
	SoundFx.play("click")
	TTSon = !TTSon
	_update_button_state()

func _update_button_state() -> void:
	TEXT_TO_SPEECH_BUTTON.texture_normal = load(CHECKED_TEXTURES["normal"] if TTSon else UNCHECKED_TEXTURES["normal"])
	TEXT_TO_SPEECH_BUTTON.texture_pressed = load(CHECKED_TEXTURES["pressed"] if TTSon else UNCHECKED_TEXTURES["pressed"])

	# Remove existing labels
	for child in TEXT_TO_SPEECH_BUTTON.get_children():
		child.queue_free()

	# Create and configure the notification label
	var tts_label = NOTIF_LABEL_SCENE.instantiate()
	tts_label.name = "NotifLabelTTSON" if TTSon else "NotifLabelTTSOFF"
	tts_label.text = "Text-To-Speech is Turned On. May not work on Web versions." if TTSon else "Text-To-Speech is Turned Off."
	TEXT_TO_SPEECH_BUTTON.add_child(tts_label)

	# Update TTS settings
	TextToSpeech.tts_enabled = TTSon
	if TTSon:
		TextToSpeech.speak_text(tts_label.text)

	fade_text(tts_label)

func fade_text(label: Label) -> void:
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
func _on_text_size_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		text_size = TEXT_SIZE_SLIDER.value
	text_size_signal.emit(text_size)
	
func setup_text_size():
	TEXT_SIZE_SLIDER.value = text_size
	text_size_signal.emit(text_size)
