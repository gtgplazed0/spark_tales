extends Node

@onready var music_player = $MusicPlayer
var paused = false
var muted_music = false
var muted_effects

var sounds = {
	"song1": load("res://Assets/Music/Song1.mp3"), 
	"song2": load("res://Assets/Music/Song2.mp3"), 
	"song3": load("res://Assets/Music/Song3.mp3"),
	"click": load("res://Assets/Sounds/ButtonClickSound.mp3")
	}

@onready var sound_players = get_children()
func play(sound_name):
	var sound_to_play = null
	if sound_name in sounds:
		sound_to_play = sounds[sound_name]
	else:
		print("sound does not exist, please check spelling and list of sounds")
	for sound_player in sound_players:
		if !sound_player.playing:
			if sound_player.name != 'music_player':
				sound_player.stream = sound_to_play
				sound_player.play()
				return
	print("Too many sounds playing at once, not enough sound players!")
	
func clear_sound():
	for sound_player in sound_players:
		if sound_player.playing:
			sound_player.stream = null
			
func _process(_delta):
	if muted_music == true: 
		music_player.stream_paused = true
	else:
		music_player.stream_paused = false
	if !music_player.playing and muted_music == false:
		music_player.play()
	
func pause():
	paused = true
func unpause():
	paused = false


