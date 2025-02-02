extends Control
@onready var signup_username_edit = $Signup/SignupUsernameEdit
@onready var signup_password_edit = $Signup/SignupPasswordEdit
@onready var signup_repassword_edit = $Signup/SignupRePasswordEdit
@onready var signup_error_message = $Signup/SignupErrorMessage

@onready var login_username_edit = $Login/LoginUsernameEdit
@onready var login_password_edit = $Login/LoginPasswordEdit
@onready var login_error_message = $Login/LoginErrorMessage

@onready var login_screen = $Login
@onready var signup_screen = $Signup
@onready var log_or_sign = $LogOrSign
@onready var currently_signed_in = $CurrentlySignedIn

@onready var edit_button = $CurrentlySignedIn/EditButton
@onready var stop_edit_button = $CurrentlySignedIn/StopEditButton

var logged_in = false
var user_id
var editing = false
signal new_logged_in
signal start_editing

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	log_or_sign.visible = true
	login_screen.visible = false
	signup_screen.visible = false
	currently_signed_in.visible = false

func ready_screens():
	print(logged_in)
	if logged_in == false:
		TextToSpeech.speak_text("Parents. Create New Account or Log into Existing Account?")
		log_or_sign.visible = true
		login_screen.visible = false
		signup_screen.visible = false
		currently_signed_in.visible = false
	else:
		TextToSpeech.speak_text("Parents. You're already logged in! Log Out?")
		log_or_sign.visible = false
		login_screen.visible = false
		signup_screen.visible = false
		currently_signed_in.visible = true
	if !editing:
		edit_button.visible = true
		stop_edit_button.visible = false
	else:
		edit_button.visible = false
		stop_edit_button.visible = true
func _on_existing_pressed() -> void:
	TextToSpeech.speak_text("Parents Login. Username. Password. Sign In!")
	SoundFx.play("click")
	log_or_sign.visible = false
	signup_screen.visible = false
	login_screen.visible = true
	login_error_message.text = ''
	
func _on_new_acc_pressed() -> void:
	TextToSpeech.speak_text("Parents Sign Up. Username. Password. Re-Enter Password. Sign up.")
	SoundFx.play("click")
	log_or_sign.visible = false
	login_screen.visible = false
	signup_screen.visible = true
	signup_error_message.text = ''

func _on_signup_login_button_pressed() -> void:
	SoundFx.play("click")
	var temp_user = signup_username_edit.text
	var temp_password = signup_password_edit.text
	var temp_repassword = signup_repassword_edit.text
	if temp_password != temp_repassword:
		signup_error_message.text = "password does not match the re-entered password"
	else: 
		if Passwords.valid_pass(temp_password):
			var hashedpass = Passwords.create_hashed_password(temp_password)
			signup_username_edit.text = ''
			signup_password_edit.text = ''
			signup_repassword_edit.text = ''
			var sign_up_worked = await DataScript.upload_user(temp_user, hashedpass["salt"], hashedpass["hash"])
			if sign_up_worked == -2:
				signup_error_message.text = "User Already Exists. Please Sign in or try again"
			elif sign_up_worked == -1:
				signup_error_message.text = "Error sending or reading username. Please try again"
			else:
				new_logged_in.emit()
				signup_error_message.text = ''
				logged_in = true
		else:
			signup_error_message.text = "Password is not valid. Must be 8 characters or longer, Must include a capital, Must include a number"

func _on_login_button_pressed() -> void:
	SoundFx.play("click")
	var temp_user = login_username_edit.text
	var temp_pass = login_password_edit.text
	login_password_edit.text = ''
	login_username_edit.text = ''
	if temp_user.length() > 0 and Passwords.valid_pass(temp_pass):
		var sign_in_worked = await DataScript.login(temp_user, temp_pass)
		if sign_in_worked == -1:
			login_error_message.text = "Error. Log in did not work. Please try again"
		elif sign_in_worked == -4:
			login_error_message.text = "Invalid Username or Password. Please try again"
		else:
			new_logged_in.emit()
			login_error_message.text = ''
			logged_in = true
	else:
		login_error_message.text = "Invalid Username or Password. Please try again"
		
func _on_log_out_button_pressed() -> void:
	SoundFx.play("click")
	#add saving data and load up guest items
	DataScript.user_id = 1
	logged_in = false
	new_logged_in.emit() # brings back to title screen.
	
func _on_edit_button_pressed() -> void:
	editing = true
	start_editing.emit()
