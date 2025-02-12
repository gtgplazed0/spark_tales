extends Node
@onready var SOUND_PLAYERS = get_children()
var sounds = {
	"song1": load("res://Assets/Music/Song1.mp3"), 
	"song2": load("res://Assets/Music/Song2.mp3"), 
	"song3": load("res://Assets/Music/Song3.mp3"),
	"click": load("res://Assets/Sounds/ButtonClickSound.mp3")
	}
func play(sound_name):
		var sound_to_play = null
		if sound_name in sounds:
			sound_to_play = sounds[sound_name]
		else:
			print("sound does not exist, please check spelling and list of sounds")
		for sound_player in SOUND_PLAYERS:
			if !sound_player.playing:
				if sound_player.name != 'music_player':
					sound_player.stream = sound_to_play
					sound_player.play()
					return
		print("Too many sounds playing at once, not enough sound players!")



