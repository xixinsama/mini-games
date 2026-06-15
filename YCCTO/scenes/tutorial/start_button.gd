extends Button

func _ready() -> void:
	LocalizationManager.language_changed.connect(set_lang)
	
func set_lang(locale: String):
	if locale == "zh_CN":
		set("theme_override_fonts/font", load("res://assets/fonts/SourceHanSerifCN-SemiBold-7.otf"))
	elif locale == "en":
		set("theme_override_fonts/font", load("res://assets/fonts/KronaOne-Regular.ttf"))
	elif locale == "ja":
		set("theme_override_fonts/font", load("res://assets/fonts/nagino.otf"))
	text = tr("START_BUTTON")
