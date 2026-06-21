extends Node
## DeepSeekClient - OpenAI-compatible API client (DeepSeek / OpenAI ChatGPT)

signal response_received(message: String)
signal error_occurred(message: String)
signal config_loaded(success: bool)

var http_request: HTTPRequest
var config: Dictionary = {}
var response_cache: Dictionary = {}
var is_requesting: bool = false
var _current_cache_key: String = ""


func _get_config_path() -> String:
	if OS.has_feature("editor"):
		return "res://deepseek_config.json"
	var exe_dir = OS.get_executable_path().get_base_dir()
	return exe_dir.path_join("deepseek_config.json")


func _get_example_path() -> String:
	if OS.has_feature("editor"):
		return "res://deepseek_config.example.json"
	var exe_dir = OS.get_executable_path().get_base_dir()
	return exe_dir.path_join("deepseek_config.example.json")


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	_load_config()


func _load_config() -> void:
	var path = _get_config_path()
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			config = json.get_data()
			print("Config loaded: ", path, ", model: ", config.get("model", "unknown"))
			_emit_config_status()
			return
		else:
			push_error("Failed to parse config: " + json.get_error_message())

	# Config missing - copy from example
	print("Config not found: ", path, ". Copying from example...")
	var example_path = _get_example_path()
	var example_file = FileAccess.open(example_path, FileAccess.READ)
	if example_file:
		var content = example_file.get_as_text()
		example_file.close()
		var write_file = FileAccess.open(path, FileAccess.WRITE)
		if write_file:
			write_file.store_string(content)
			write_file.close()
			print("Copied example config to: ", path)
		var json = JSON.new()
		if json.parse(content) == OK:
			config = json.get_data()
	else:
		push_error("No config or example found.")
		config = {}

	_emit_config_status()


func _emit_config_status():
	var key = config.get("api_key", "")
	if not key is String or key.is_empty() or key.begins_with("sk-your-"):
		config_loaded.emit(false)
	else:
		config_loaded.emit(true)


func save_config(new_config: Dictionary) -> void:
	config = new_config
	var path = _get_config_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config, "\t"))
		file.close()
		print("Config saved: ", path)
	else:
		push_error("Failed to save config: " + path)


func get_config() -> Dictionary:
	return config.duplicate()


func _get_api_key() -> String:
	return config.get("api_key", "")


func _get_base_url() -> String:
	return config.get("base_url", "https://api.deepseek.com")


func _get_model() -> String:
	return config.get("model", "deepseek-v4-pro")


func send_message(user_text: String) -> void:
	_send_request("chat", user_text, {})


func send_system_trigger(trigger_type: String, context: Dictionary = {}) -> void:
	var user_prompt = ""
	match trigger_type:
		"greeting":
			user_prompt = "请用可爱的语气和主人打个招呼~"
		"random_chatter":
			user_prompt = "请随机说一句俏皮话或者关心的话~"
		"idle_check":
			user_prompt = "主人好像离开了一会儿，请关心一下~"
		"reminder":
			if context.has("memo") and context["memo"] is Dictionary:
				user_prompt = "请提醒主人：" + context["memo"].get("content", "")
		_:
			user_prompt = ""
	_send_request(trigger_type, user_prompt, context)


func _send_request(trigger_type: String, user_text: String, context: Dictionary) -> void:
	if is_requesting:
		print("Already requesting, skipping")
		return

	var api_key = _get_api_key()
	if not api_key is String or api_key.is_empty() or api_key.begins_with("sk-your-"):
		error_occurred.emit("请先设置 API Key~ 右键菜单 -> 设置")
		return

	var system_prompt = PersonaManager.build_system_prompt(trigger_type, context)

	var cache_key = (system_prompt + user_text).sha256_text()
	_current_cache_key = cache_key
	if cache_key in response_cache:
		print("Cache hit!")
		response_received.emit(response_cache[cache_key])
		return

	var body: Dictionary = {
		"model": _get_model(),
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": user_text}
		],
		"stream": false
	}

	# reasoning_effort + thinking: DeepSeek-specific, skip for OpenAI to avoid API errors
	if config.get("thinking", false):
		body["thinking"] = {"type": "enabled"}
		if config.has("reasoning_effort") and config["reasoning_effort"] is String and not config["reasoning_effort"].is_empty():
			body["reasoning_effort"] = config["reasoning_effort"]

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]

	var url = _get_base_url() + "/chat/completions"
	print("Sending request to: ", url)
	is_requesting = true
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		is_requesting = false
		error_occurred.emit("Request failed: " + str(error))


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_requesting = false

	if _result != HTTPRequest.RESULT_SUCCESS:
		error_occurred.emit("Network error: " + str(_result))
		return

	var body_str = body.get_string_from_utf8()

	if response_code != 200:
		var error_detail = body_str
		if error_detail.length() > 200:
			error_detail = error_detail.substr(0, 200) + "..."
		error_occurred.emit("HTTP " + str(response_code) + ": " + error_detail)
		return

	var json = JSON.new()
	var error = json.parse(body_str)
	if error != OK:
		error_occurred.emit("JSON parse error: " + json.get_error_message())
		return

	var data = json.get_data()
	if data == null or not data.has("choices") or data["choices"].size() == 0:
		error_occurred.emit("Unexpected response: " + body_str.substr(0, 200))
		return

	var message = data["choices"][0].get("message", {})
	var content = message.get("content", "")

	# Strip </think> tag if present (DeepSeek thinking mode)
	var think_end = content.find("</think>")
	if think_end != -1:
		content = content.substr(think_end + 8).strip_edges()

	if not _current_cache_key.is_empty():
		response_cache[_current_cache_key] = content

	response_received.emit(content)
