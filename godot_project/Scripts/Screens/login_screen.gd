extends Control
#Signup variables
@onready var SIGNUP_USERNAME_EDIT = $Signup/SignupUsernameEdit
@onready var SIGNUP_PASSWORD_EDIT = $Signup/SignupPasswordEdit
@onready var SIGNUP_REPASSWORD_EDIT = $Signup/SignupRePasswordEdit
@onready var SIGNUP_ERROR_MESSAGE = $Signup/SignupErrorMessage
#Login Variables
@onready var LOGIN_USERNAME_EDIT = $Login/LoginUsernameEdit
@onready var LOGIN_PASSWORD_EDIT = $Login/LoginPasswordEdit
@onready var LOGIN_ERROR_MESSAGE = $Login/LoginErrorMessage

@onready var LOGIN_SCREEN = $Login
@onready var SIGNUP_SCREEN = $Signup
@onready var LOG_OR_SIGN = $LogOrSign
@onready var CURRENTLY_SIGNED_IN = $CurrentlySignedIn

@onready var EDIT_BUTTON = $CurrentlySignedIn/EditButton
@onready var STOP_EDIT_BUTTON = $CurrentlySignedIn/StopEditButton

var logged_in = false
var user_id
var editing
signal new_logged_in
signal start_editing
signal stop_editing
signal log_out

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visability(true, false, false, false)

func open_screens():
	if logged_in == false:
		TextToSpeech.speak_text("Parents. Create New Account or Log into Existing Account?")
		visability(true, false, false, false)
	else:
		TextToSpeech.speak_text("Parents. You're already logged in! Log Out?")
		visability(false, false, false, true)
	if editing == false:
		EDIT_BUTTON.visible = true
		STOP_EDIT_BUTTON.visible = false
	else:
		EDIT_BUTTON.visible = false
		STOP_EDIT_BUTTON.visible = true
		
func _on_existing_pressed() -> void:
	TextToSpeech.speak_text("Parents Login. Username. Password. Sign In!")
	SoundFx.play("click")
	visability(false, true, false, false)
	LOGIN_ERROR_MESSAGE.text = ''
	
func _on_new_acc_pressed() -> void:
	TextToSpeech.speak_text("Parents Sign Up. Username. Password. Re-Enter Password. Sign up.")
	SoundFx.play("click")
	visability(false, false, true, false)
	SIGNUP_ERROR_MESSAGE.text = ''

func _on_signup_login_button_pressed() -> void:
	SoundFx.play("click")
	var temp_user = SIGNUP_USERNAME_EDIT.text
	var temp_password = SIGNUP_PASSWORD_EDIT.text
	var temp_repassword = SIGNUP_REPASSWORD_EDIT.text
	if temp_password != temp_repassword:
		SIGNUP_ERROR_MESSAGE.text = "password does not match the re-entered password"
	else: 
		if Passwords.valid_pass(temp_password):
			var hashedpass = Passwords.create_hashed_password(temp_password)
			SIGNUP_USERNAME_EDIT.text = ''
			SIGNUP_PASSWORD_EDIT.text = ''
			SIGNUP_REPASSWORD_EDIT.text = ''
			var sign_up_worked = await DataScript.upload_user(temp_user, hashedpass["salt"], hashedpass["hash"])
			if sign_up_worked == -2:
				SIGNUP_ERROR_MESSAGE.text = "User Already Exists. Please Sign in or try again"
			elif sign_up_worked == -1:
				SIGNUP_ERROR_MESSAGE.text = "Error sending or reading username. Please try again"
			else:
				new_logged_in.emit()
				SIGNUP_ERROR_MESSAGE.text = ''
				logged_in = true
		else:
			SIGNUP_ERROR_MESSAGE.text = "Password is not valid. Must be 8 characters or longer, Must include a capital, Must include a number"

func _on_login_button_pressed() -> void:
	SoundFx.play("click")
	var temp_user = LOGIN_USERNAME_EDIT.text
	var temp_pass = LOGIN_PASSWORD_EDIT.text
	LOGIN_PASSWORD_EDIT.text = ''
	LOGIN_USERNAME_EDIT.text = ''
	if temp_user.length() > 0 and Passwords.valid_pass(temp_pass):
		var sign_in_worked = await DataScript.login(temp_user, temp_pass)
		if sign_in_worked == -1:
			LOGIN_ERROR_MESSAGE.text = "Error. Log in did not work. Please try again"
		elif sign_in_worked == -4:
			LOGIN_ERROR_MESSAGE.text = "Invalid Username or Password. Please try again"
		else:
			new_logged_in.emit()
			LOGIN_ERROR_MESSAGE.text = ''
			logged_in = true
	else:
		LOGIN_ERROR_MESSAGE.text = "Invalid Username or Password. Please try again"
		
func _on_log_out_button_pressed() -> void:
	SoundFx.play("click")
	#add saving data and load up guest items
	DataScript.user_id = 0
	logged_in = false
	log_out.emit()
	
func _on_edit_button_pressed() -> void:
	start_editing.emit()
	
func visability(l_o_s, l_s, s_s, c_s_i):
	LOG_OR_SIGN.visible = l_o_s
	LOGIN_SCREEN.visible = l_s
	SIGNUP_SCREEN.visible = s_s
	CURRENTLY_SIGNED_IN.visible = c_s_i
	
func now_editing():
	editing = true


func _on_stop_edit_button_pressed() -> void:
	stop_editing.emit()


func _on_guest_pressed() -> void:
	SoundFx.play("click")
	var sign_in_worked = await DataScript.login("guest", "GuestPassword123")
	if sign_in_worked == -1:
		print("Error. Log in did not work. Please try again")
	elif sign_in_worked == -4:
		print("Error. Log in did not work. Please try again")
	else:
		new_logged_in.emit()
		logged_in = true
