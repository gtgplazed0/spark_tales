extends Control
@onready var POP_UP_TEX = $StickerPopUpTexture
@onready var ANIM_PLAYER = $AnimationPlayer
func _ready():
	modulate = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
func _gui_input(event: InputEvent)-> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			visible = false
func create_popup(sticker):
	visible = true
	POP_UP_TEX.texture = sticker
	ANIM_PLAYER.play("RESET")
	ANIM_PLAYER.play("fade")
	await ANIM_PLAYER.animation_finished  # Waits for the animation to finish
	visible = false
