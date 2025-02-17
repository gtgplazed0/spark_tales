extends Node
class_name ScreenController

# Screen references
@onready var TITLE_SCREEN = $TitleScene
@onready var STORIES_SCREEN = $StoriesScreen
@onready var LEVEL_CONTROLLER = $LevelController
@onready var PARENT_LOGIN_SCREEN = $ParentLoginScreen
@onready var SETTING_SCREEN = $SettingsScreen
@onready var PROGRESS_SCREEN = $ProgressScreen
@onready var STICKER_POPUP_SCREEN = $StickerPopUpScreen
@onready var INFO_SCREEN = $InfoScreen
@onready var INFO_SCREEN_TEXT = $InfoScreen/InfoScreenTexture/InformationLabel
# Variables
var level_number = ""
var current_screen = null
var editing = false
func _ready():
	register_buttons()
	initialize_screens()

func initialize_screens():
	# Set all screens invisible except the title screen
	for child in get_children():
		if child.name != "TitleScene" and child is Control:
			child.visible = false
	current_screen = TITLE_SCREEN
	LEVEL_CONTROLLER.return_signal.connect(_on_level_reset)
	LEVEL_CONTROLLER.finished_signal.connect(_on_level_finished)
	PARENT_LOGIN_SCREEN.new_logged_in.connect(_on_new_log_in)
	PARENT_LOGIN_SCREEN.start_editing.connect(_on_start_editing)
	PARENT_LOGIN_SCREEN.log_out.connect(_on_log_out)
	PARENT_LOGIN_SCREEN.stop_editing.connect(_on_stop_editing)
	SETTING_SCREEN.text_size_signal.connect(_on_text_size_changed)
	
func register_buttons():
	# Register buttons and connect their signals
	for button in get_tree().get_nodes_in_group("buttons"):
		if button is ScreenButton:
			button.clicked.connect(_on_button_pressed)
	STORIES_SCREEN.level_button_clicked.connect(_on_story_level_button)

func _on_button_pressed(button):
	match button.name:
		"StoryButton":
			button_navigation(STORIES_SCREEN, "Stories")
			STORIES_SCREEN.reset_scroll()
		"StoryBackButton":
			button_navigation(TITLE_SCREEN, "Spark Tales. Stories. Progress. Parents")
		"ParentButton":
			button_navigation(PARENT_LOGIN_SCREEN, "")
			PARENT_LOGIN_SCREEN.editing = editing
			PARENT_LOGIN_SCREEN.open_screens()
		"ParentBackButton":
			button_navigation(TITLE_SCREEN, "Spark Tales. Stories. Progress. Parents")
		"LSBackButton":
			SoundFx.play("click")
			PARENT_LOGIN_SCREEN.LOGIN_SCREEN.visible = false
			PARENT_LOGIN_SCREEN.SIGNUP_SCREEN.visible = false
			if PARENT_LOGIN_SCREEN.logged_in == false:
				TextToSpeech.speak_text("Create New Account or Log into Existing Account?")
				PARENT_LOGIN_SCREEN.open_screens()
			else:
				TextToSpeech.speak_text("You're already logged in!")
				PARENT_LOGIN_SCREEN.open_screens()
		"ProgressButton":
			change_popup_screen("Progress", PROGRESS_SCREEN, true)
		"ProgressBackButton":
			change_popup_screen("Spark Tales. Stories. Progress. Parents", PROGRESS_SCREEN, false)
		"SettingButton":
			change_popup_screen("Settings. Music Volume. Sound Volume. Text Size. Text To Speech.", SETTING_SCREEN, true)
		"SettingBackButton":
			change_popup_screen("Spark Tales. Stories. Progress. Parents", SETTING_SCREEN, false)
		"InformationButton":
			change_popup_screen(INFO_SCREEN_TEXT.text, INFO_SCREEN, true)
		"InformationBackButton":
			change_popup_screen("Spark Tales. Stories. Progress. Parents", INFO_SCREEN, false)

func change_popup_screen(text_to_speak, screen_to_change, visibillity):
	TextToSpeech.speak_text(text_to_speak)
	SoundFx.play("click")
	screen_to_change.visible = visibillity
func _on_level_reset():
		change_screen(STORIES_SCREEN)
		
func change_screen(screen_to_change):
	if current_screen:
		current_screen.visible = false
	current_screen = screen_to_change
	current_screen.visible = true if screen_to_change else false

func _on_story_level_button(button_name):
	start_new_level(button_name)
	change_screen(LEVEL_CONTROLLER)
	
func start_new_level(button_name):
	level_number = extract_number(button_name)
	if editing == false:
		LEVEL_CONTROLLER.start_level(level_number, false)
	else:
		LEVEL_CONTROLLER.start_level(level_number, true)

func extract_number(button_name):
	var number = ""
	for character in str(button_name):
		if character.is_valid_int(): # Use Godot's is_numeric method
			number += character
	return number

func _on_new_log_in():
	PARENT_LOGIN_SCREEN.logged_in = true
	PARENT_LOGIN_SCREEN.open_screens()
	PROGRESS_SCREEN.get_stickers()
	print(PARENT_LOGIN_SCREEN.user_id)

func _on_start_editing():
	editing = true
	change_screen(TITLE_SCREEN)
	for child in get_children():
		if child.is_in_group("editable") and child.has_method("now_editing"):
			child.now_editing()
func _on_stop_editing():
	editing = false
	change_screen(TITLE_SCREEN)
	for child in get_children():
		if child.is_in_group("editable") and child.has_method("stop_editing"):
			child.stop_editing()
	
func _on_level_finished(editing):
	var sticker = null
	change_screen(STORIES_SCREEN)
	TextToSpeech.speak_text("Spark Tales. Stories. Progress. Parents")
	if editing == false:
		sticker = PROGRESS_SCREEN.new_sticker()
		if sticker != null:
			STICKER_POPUP_SCREEN.create_popup(sticker)
			
func button_navigation(screen, text_to_speech_text):
	TextToSpeech.speak_text(text_to_speech_text)
	SoundFx.play("click")
	change_screen(screen)
	
func _on_log_out():
	PARENT_LOGIN_SCREEN.logged_in = false
	#make sure to stop editing on log out, and save evrything. 
	PARENT_LOGIN_SCREEN.open_screens()
	
func _on_text_size_changed(new_text_size):
	LEVEL_CONTROLLER.text_size = new_text_size

