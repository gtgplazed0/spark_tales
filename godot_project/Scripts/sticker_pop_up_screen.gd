extends Control
@onready var pop_up_tex = $StickerPopUpTexture
func _ready():
	modulate = 0
func create_popup(sticker):
	visible = true
	pop_up_tex.texture = sticker
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished  # Waits for the animation to finish
	visible = false
