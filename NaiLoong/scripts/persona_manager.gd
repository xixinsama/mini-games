extends Node
## PersonaManager - Loads persona file and builds system prompts

var persona_text: String = ""
var default_persona: String = "你是奶龙，一只可爱的桌面宠物小恐龙。- 性格：软萌、黏人、偶尔撒娇- 说话风格：句尾用~、！- 你会主动关心主人、给出提醒、说俏皮话- 主人叫你主人，自称奶龙"

func _ready() -> void:
	_load_persona()

func _get_persona_path() -> String:
	if OS.has_feature("editor"):
		return "res://人设.md"
	var exe_dir = OS.get_executable_path().get_base_dir()
	return exe_dir.path_join("人设.md")

func _load_persona() -> void:
	var path = _get_persona_path()
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		persona_text = file.get_as_text().strip_edges()
		file.close()
		print("Persona loaded: ", path)
	else:
		persona_text = default_persona
		print("Persona not found: ", path, ", using default")

func build_system_prompt(trigger_type: String, context: Dictionary = {}) -> String:
	var prompt = persona_text + "\n\n"

	match trigger_type:
		"chat":
			var memos = MemoManager.get_all_memos()
			if memos.size() > 0:
				prompt += "主人的备忘录里有这些事情：\n"
				for memo in memos:
					prompt += "- " + memo["content"]
					if memo.has("deadline") and not memo["deadline"].is_empty():
						prompt += " (截止: " + memo["deadline"] + ")"
					prompt += "\n"
			prompt += "\n请根据以上信息，以奶龙的身份和主人对话。"

		"random_chatter":
			prompt += "现在请随机说一句俏皮话或者关心的话，要自然可爱。不要重复之前说过的话。"

		"idle_check":
			prompt += "主人好像离开了一会儿没操作电脑，请试着搭话，关心一下主人。"

		"reminder":
			if context.has("memo"):
				var memo = context["memo"]
				prompt += "请提醒主人以下事项：" + memo["content"]
				if memo.has("deadline") and not memo["deadline"].is_empty():
					prompt += " (截止时间: " + memo["deadline"] + ")"
				prompt += "\n语气要温和可爱。"

		"greeting":
			prompt += "你刚刚启动了，请用可爱的语气和主人打招呼。"

		_:
			prompt += "请以奶龙的身份回应。"

	return prompt

func get_persona_text() -> String:
	return persona_text
