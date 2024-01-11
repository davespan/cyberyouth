extends Node

var game = "res://scenes/game.tscn"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start_button_pressed():
	get_tree().change_scene_to_file(game)

func _on_quit_button_pressed():
	get_tree().quit()

func _on_english_pressed():
	TranslationServer.set_locale("en")

func _on_italian_pressed():
	TranslationServer.set_locale("it")

func _on_spanish_pressed():
	TranslationServer.set_locale("es")

func _on_bulgarian_pressed():
	TranslationServer.set_locale("bg")

func _on_dutch_pressed():
	TranslationServer.set_locale("nl")

func _on_turkish_pressed():
	TranslationServer.set_locale("tr")

func _on_estonian_pressed():
	TranslationServer.set_locale("et")
