# LocalizationManager.gd
extends Node

signal language_changed(locale: String)

var language = "automatic"

func _ready():
	# Load here language from the user settings file
	if language == "automatic":
		var preferred_language = OS.get_locale_language()
		TranslationServer.set_locale(preferred_language)
	else:
		TranslationServer.set_locale(language)

func set_language(locale_code):
	TranslationServer.set_locale(locale_code)
	language = locale_code
	language_changed.emit(locale_code)
	print("Language switched to: ", locale_code)

func get_current_language():
	return language
