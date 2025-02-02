extends Node
class_name ScreenController

# Screen references
@onready var title_screen = $TitleScene
@onready var stories_screen = $StoriesScreen
@onready var level_controller = $LevelController
@onready var parent_login_screen = $ParentLoginScreen
@onready var settings_screen = $SettingsScreen
@onready var progress_screen = $ProgressScreen
@onready var sticker_pop_up = $StickerPopUpScreen
# Variables
var level_number = ""
var current_screen = null

func _ready():
	register_buttons()
	initialize_screens()

func initialize_screens():
	# Set all screens invisible except the title screen
	for child in get_children():
		if child.name != "TitleScene" and child is Control:
			child.visible = false
	current_screen = title_screen
	level_controller.return_signal.connect(_on_level_reset)
	level_controller.finished_signal.connect(_on_level_finsihed)
	parent_login_screen.new_logged_in.connect(_on_new_log_in)
	parent_login_screen.start_editing.connect(_on_start_editing)
	progress_screen.create_sticker_textures(stories_screen.num_of_levels)
func register_buttons():
	# Register buttons and connect their signals
	for button in get_tree().get_nodes_in_group("buttons"):
		if button is ScreenButton:
			button.clicked.connect(_on_button_pressed)
	stories_screen.level_button_clicked.connect(_on_story_level_button)

func _on_level_reset():
		change_screen(stories_screen)
		
func _on_button_pressed(button):
	match button.name:
		"StoryButton":
			TextToSpeech.speak_text("Stories")
			SoundFx.play("click")
			change_screen(stories_screen)
			stories_screen.reset_scroll()
		"ParentButton":
			SoundFx.play("click")
			change_screen(parent_login_screen)
			parent_login_screen.ready_screens()
		"ProgressButton":
			progress_screen.visible = true
		"BackButton":
			TextToSpeech.speak_text("Spark Tales. Stories. Progress. Parents")
			SoundFx.play("click")
			change_screen(title_screen)
		"LSBackButton":
			SoundFx.play("click")
			parent_login_screen.login_screen.visible = false
			parent_login_screen.signup_screen.visible = false
			if parent_login_screen.logged_in == false:
				TextToSpeech.speak_text("Create New Account or Log into Existing Account?")
				parent_login_screen.log_or_sign.visible = true
			else:
				TextToSpeech.speak_text("You're already logged in!")
				parent_login_screen.currently_signed_in = true
		"SettingButton":
			TextToSpeech.speak_text("Settings. Music Volume. Sound Volume. Text Size. Text To Speech.")
			SoundFx.play("click")
			settings_screen.visible = true
		"SettingBackButton":
			TextToSpeech.speak_text("Spark Tales. Stories. Progress. Parents")
			SoundFx.play("click")
			settings_screen.visible = false
		"ProgressBackButton2":
			TextToSpeech.speak_text("Spark Tales. Stories. Progress. Parents")
			progress_screen.visible = false

func change_screen(screen_to_change):
	if current_screen:
		current_screen.visible = false
	current_screen = screen_to_change
	current_screen.visible = true if screen_to_change else false

func _on_story_level_button(button_name):
	start_new_level(button_name)
	change_screen(level_controller)
	
func start_new_level(button_name):
	level_number = extract_number(button_name)
	level_controller.start_level(level_number)

func extract_number(button_name):
	var number = ""
	for character in str(button_name):
		if character.is_valid_int(): # Use Godot's is_numeric method
			number += character
	return number

func _on_hud_back():
	stories_screen.reset_scroll()

func _on_new_log_in():
	change_screen(title_screen)
	print(DataScript.user_id)

func _on_start_editing():
	change_screen(title_screen)
func _on_level_finsihed():
	var sticker = null
	change_screen(stories_screen)
	TextToSpeech.speak_text("Spark Tales. Stories. Progress. Parents")
	sticker = progress_screen.new_sticker()
	if sticker != null:
		sticker_pop_up.create_popup(sticker)
	
