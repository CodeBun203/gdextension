extends Node

@onready var sound = $AudioStreamPlayer2D

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	sound.play()


func _on_settings_pressed():
	sound.play()


func _on_quit_pressed():
	sound.play()
	get_tree().quit()
