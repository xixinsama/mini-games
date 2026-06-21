extends Node
## DeepSeekClient - Communicates with DeepSeek API via HTTPRequest

signal response_received(message: String)
signal error_occurred(message: String)

var http_request: HTTPRequest
var config: Dictionary = {}
var response_cache: Dictionary = {}
var is_requesting: bool = false
var _current_cache_key: String = ""

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	_load_config()

func _load_config() -> void:
	var file = FileAccess.open("res://deepseek_config.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			config = json.get_data()
			print("DeepSeek config loaded, model: ", config.get("model", "unknown"))
		else:
			push_error("Failed to parse deepseek_config.json")
			config = {}
	else:
		push_error("deepseek_config.json not found! Please create it from the template.")

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
			if context.has("memo"):
				user_prompt = "请提醒主人：" + context["memo"].get("content", "")
		_:
			user_prompt = ""
	_send_request(trigger_type, user_prompt, context)

func _send_request(trigger_type: String, user_text: String, context: Dictionary) -> void:
	if is_requesting:
		print("Already requesting, skipping")
		return

	var system_prompt = PersonaManager.build_system_prompt(trigger_type, context)

	var cache_key = (system_prompt + user_text).sha256_text()
	_current_cache_key = cache_key
	if cache_key in response_cache:
		print("Cache hit!")
		response_received.emit(response_cache[cache_key])
		return

	var body = {
		"model": _get_model(),
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": user_text}
		],
		"reasoning_effort": config.get("reasoning_effort", "high"),
		"stream": false
	}

	if config.get("thinking", false):
		body["thinking"] = {"type": "enabled"}

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + _get_api_key()
	]

	var url = _get_base_url() + "/chat/completions"
	print("Sending request to: ", url)
	is_requesting = true
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		is_requesting = false
		error_occurred.emit("Request failed with error: " + str(error))

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
		error_occurred.emit("Unexpected response format: " + body_str.substr(0, 200))
		return

	var message = data["choices"][0].get("message", {})
	var content = message.get("content", "")

	# Extract content after </think> if present (thinking mode)
	var think_end = content.find("</think>")
	if think_end != -1:
		content = content.substr(think_end + 8).strip_edges()

	# Cache the response
	if not _current_cache_key.is_empty():
		response_cache[_current_cache_key] = content

	response_received.emit(content)
