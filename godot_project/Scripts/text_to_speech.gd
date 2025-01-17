class_name TTSManager extends Node  
var tts_enabled:bool = false; 
var voice:int = 0; 
var vString = DisplayServer.tts_get_voices_for_language("en")[voice] 
var volume:int = 100; 
var speed:float = 1.0;  
func speak_text(text:String):   
	if tts_enabled: 
		stop()
		if(tts_enabled):         
			DisplayServer.tts_speak(text,vString,volume,1.0,speed);
func stop():     
	DisplayServer.tts_stop();
