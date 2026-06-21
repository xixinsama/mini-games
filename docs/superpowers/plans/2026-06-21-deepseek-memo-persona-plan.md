# DeepSeek + Memo + Persona Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Replace Ollama with DeepSeek API, add memo management, and implement persona-driven proactive AI behavior for the desktop pet.

**Architecture:** Three new autoloads (DeepSeekClient, MemoManager, PersonaManager) added to project.godot. DeepSeekClient uses HTTPRequest node for signal-driven API calls. MemoManager handles JSON file persistence. PersonaManager reads the persona file and builds contextual system prompts. main.gd drives proactive behavior via timers and idle detection.

**Tech Stack:** Godot 4.4, GDScript, HTTPRequest, DeepSeek API (deepseek-v4-pro)

## Global Constraints

- DeepSeek model: deepseek-v4-pro
- API endpoint: https://api.deepseek.com/chat/completions
- thinking enabled, reasoning_effort=high, stream=false
- Persona: cute pet, no kaomoji/emoticons
- Config and memo files are gitignored
- Menu uses TabContainer with two tabs

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| deepseek_config.json | Create | API key + model config |
| scripts/deepseek_client.gd | Create | HTTPRequest-based API client |
| scripts/memo_manager.gd | Create | Memo CRUD + JSON persistence |
| scripts/persona_manager.gd | Create | Persona loading + system prompt builder |
| scripts/main.gd | Modify | Proactive AI, idle detection, new signals |
| scripts/pet.gd | Modify | Adapt to DeepSeekClient signals |
| scripts/ollama_client.gd | Delete | Replaced by deepseek_client.gd |
| scripts/ollama_client.gd.uid | Delete | Cleanup |
| scenes/menu.tscn | Modify | TabContainer restructure |
| scenes/main.tscn | Modify | Update signal connections |
| project.godot | Modify | Update autoload list |
| .gitignore | Modify | Add private files |

---

### Task 1: Create Config and Persona Files

**Files:**
- Create: `deepseek_config.json`
- Create: `人设.md`
- Modify: `.gitignore`

**Produces:**
- Config file read by DeepSeekClient (Task 4)
- Persona file read by PersonaManager (Task 3)

- [ ] **Step 1: Create deepseek_config.json**

Write file `deepseek_config.json`:
```json
{
  "api_key": "sk-your-api-key-here",
  "model": "deepseek-v4-pro",
  "base_url": "https://api.deepseek.com",
  "thinking": true,
  "reasoning_effort": "high"
}
```

- [ ] **Step 2: Create 人设.md**

Write file `人设.md`:
```
你是奶龙，一只可爱的桌面宠物小恐龙。
- 性格：软萌、黏人、偶尔撒娇
- 说话风格：句尾用"~"、"！"
- 你会主动关心主人、给出提醒、说俏皮话
- 主人叫你"主人"，自称"奶龙"
```

- [ ] **Step 3: Update .gitignore**

Read existing `.gitignore`. Append these two lines:
```
deepseek_config.json
memos.json
```

- [ ] **Step 4: Commit**

```bash
git add deepseek_config.json 人设.md .gitignore
git commit -m "feat: add config template, persona file, update gitignore

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: Create PersonaManager Autoload

**Files:**
- Create: `scripts/persona_manager.gd`

**Consumes:**
- `人设.md` file at project root (created in Task 1)

**Produces:**
- `PersonaManager` singleton with `build_system_prompt(trigger_type: String, context: Dictionary = {}) -> String`

- [ ] **Step 1: Write persona_manager.gd**

```gdscript
extends Node
## PersonaManager - Loads persona file and builds system prompts

var persona_text: String = ""
var default_persona: String = "你是奶龙，一只可爱的桌面宠物小恐龙。- 性格：软萌、黏人、偶尔撒娇- 说话风格：句尾用~、！- 你会主动关心主人、给出提醒、说俏皮话- 主人叫你主人，自称奶龙"

func _ready() -> void:
	_load_persona()

func _load_persona() -> void:
	var file = FileAccess.open("res://人设.md", FileAccess.READ)
	if file:
		persona_text = file.get_as_text().strip_edges()
		file.close()
		print("Persona loaded from file")
	else:
		persona_text = default_persona
		print("Persona file not found, using default")

func build_system_prompt(trigger_type: String, context: Dictionary = {}) -> String:
	var prompt = persona_text + "

"

	match trigger_type:
		"chat":
			# Add memo summary for user chat context
			var memos = MemoManager.get_all_memos()
			if memos.size() > 0:
				prompt += "主人的备忘录里有这些事情：
"
				for memo in memos:
					prompt += "- " + memo["content"]
					if memo.has("deadline") and not memo["deadline"].is_empty():
						prompt += " (截止: " + memo["deadline"] + ")"
					prompt += "
"
			prompt += "
请根据以上信息，以奶龙的身份和主人对话。"

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
				prompt += "
语气要温和可爱。"

		"greeting":
			prompt += "你刚刚启动了，请用可爱的语气和主人打招呼。"

		_:
			prompt += "请以奶龙的身份回应。"

	return prompt

func get_persona_text() -> String:
	return persona_text
```

- [ ] **Step 2: Commit**

```bash
git add scripts/persona_manager.gd
git commit -m "feat: add PersonaManager autoload

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Create MemoManager Autoload

**Files:**
- Create: `scripts/memo_manager.gd`

**Consumes:** None (standalone)

**Produces:**
- `MemoManager` singleton
- `memo_updated()` signal
- `reminder_due(memo: Dictionary)` signal
- `add_memo(content: String, deadline: String) -> Dictionary`
- `update_memo(id: String, fields: Dictionary) -> void`
- `delete_memo(id: String) -> void`
- `get_all_memos() -> Array[Dictionary]`
- `get_expired_reminders() -> Array[Dictionary]`

- [ ] **Step 1: Write memo_manager.gd**

```gdscript
extends Node
## MemoManager - Memo CRUD with JSON file persistence

const MEMO_PATH = "user://memos.json"

signal memo_updated()
signal reminder_due(memo: Dictionary)

var memos: Array = []

func _ready() -> void:
	_load_memos()

func _load_memos() -> void:
	var file = FileAccess.open(MEMO_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(text)
		if error == OK:
			var data = json.get_data()
			if data and data.has("memos"):
				memos = data["memos"]
				print("Loaded %d memos" % memos.size())
		else:
			push_error("Failed to parse memos.json: " + json.get_error_message())
			memos = []
	else:
		print("No memos file found, starting fresh")
		memos = []

func _save_memos() -> void:
	var data = {"memos": memos}
	var file = FileAccess.open(MEMO_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "	"))
		file.close()
		print("Memos saved")
	else:
		push_error("Failed to save memos: " + str(FileAccess.get_open_error()))

func add_memo(content: String, deadline: String = "") -> Dictionary:
	var memo = {
		"id": str(Time.get_unix_time_from_system()) + "_" + str(randi()),
		"content": content,
		"deadline": deadline,
		"created_at": Time.get_datetime_string_from_system(),
		"pinned": false,
		"reminded": false
	}
	memos.append(memo)
	_save_memos()
	memo_updated.emit()
	return memo

func update_memo(id: String, fields: Dictionary) -> void:
	for i in range(memos.size()):
		if memos[i]["id"] == id:
			for key in fields:
				memos[i][key] = fields[key]
			_save_memos()
			memo_updated.emit()
			return

func delete_memo(id: String) -> void:
	for i in range(memos.size() - 1, -1, -1):
		if memos[i]["id"] == id:
			memos.remove_at(i)
			_save_memos()
			memo_updated.emit()
			return

func get_all_memos() -> Array:
	return memos.duplicate()

func get_expired_reminders() -> Array:
	var expired = []
	var now = Time.get_datetime_string_from_system()
	for memo in memos:
		if memo.get("reminded", false):
			continue
		if memo.has("deadline") and not memo["deadline"].is_empty():
			if memo["deadline"] <= now:
				memo["reminded"] = true
				_save_memos()
				expired.append(memo)
				reminder_due.emit(memo)
	return expired
```

- [ ] **Step 2: Commit**

```bash
git add scripts/memo_manager.gd
git commit -m "feat: add MemoManager autoload

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Create DeepSeekClient Autoload

**Files:**
- Create: `scripts/deepseek_client.gd`

**Consumes:**
- `deepseek_config.json` (created in Task 1)
- `PersonaManager.build_system_prompt()` (Task 2)

**Produces:**
- `DeepSeekClient` singleton
- `response_received(message: String)` signal
- `error_occurred(message: String)` signal
- `send_message(user_text: String)` method
- `send_system_trigger(trigger_type: String, context: Dictionary)` method

- [ ] **Step 1: Write deepseek_client.gd**

```gdscript
extends Node
## DeepSeekClient - Communicates with DeepSeek API via HTTPRequest

signal response_received(message: String)
signal error_occurred(message: String)

var http_request: HTTPRequest
var config: Dictionary = {}
var response_cache: Dictionary = {}
var is_requesting: bool = false

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
		"thinking": {"type": "enabled"},
		"reasoning_effort": config.get("reasoning_effort", "high"),
		"stream": false
	}

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
	var system_prompt = PersonaManager.build_system_prompt("chat", {})
	var cache_key = (system_prompt + "").sha256_text()
	response_cache[cache_key] = content

	response_received.emit(content)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/deepseek_client.gd
git commit -m "feat: add DeepSeekClient autoload with HTTPRequest

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: Update project.godot Autoload List

**Files:**
- Modify: `project.godot`

**Consumes:**
- DeepSeekClient script (Task 4)
- MemoManager script (Task 3)
- PersonaManager script (Task 2)

- [ ] **Step 1: Edit project.godot autoload section**

Read current `project.godot`. In the `[autoload]` section:

Remove:
```
OllamaClient="*res://脚本/ollama_client.gd"
```

Change the script paths to use the new `scripts/` directory (since git status shows old 脚本/ files are deleted and scripts/ is untracked):
```
ClickThrough="*res://scripts/click_through.cs"
DetectPassThrough="*res://scripts/detect_pass_through.gd"
```

Add:
```
DeepSeekClient="*res://scripts/deepseek_client.gd"
MemoManager="*res://scripts/memo_manager.gd"
PersonaManager="*res://scripts/persona_manager.gd"
```

The full `[autoload]` section should look like:
```ini
[autoload]

ClickThrough="*res://scripts/click_through.cs"
DetectPassThrough="*res://scripts/detect_pass_through.gd"
DeepSeekClient="*res://scripts/deepseek_client.gd"
MemoManager="*res://scripts/memo_manager.gd"
PersonaManager="*res://scripts/persona_manager.gd"
```

**IMPORTANT:** After editing, open the project in Godot Editor once so it generates the `.uid` files for the new scripts.

- [ ] **Step 2: Commit**

```bash
git add project.godot
git commit -m "feat: update autoload list for DeepSeekClient, MemoManager, PersonaManager

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 6: Restructure menu.tscn with TabContainer

**Files:**
- Modify: `scenes/menu.tscn`

**Consumes:** None

- [ ] **Step 1: Rebuild menu.tscn**

The scene structure changes from:
```
menu (Control)
  Panel
    VBoxContainer
      QuitButton, ModelLoading, ModelButton, ModelPopup, TextEdit, SendButton
```

To:
```
menu (Control)
  TabContainer
    对话 (VBoxContainer)
      QuitButton, ModelLabel(Label), TextEdit, SendButton
    备忘录 (VBoxContainer)
      MemoTextEdit(TextEdit), SaveButton(Button)
```

Open `scenes/menu.tscn` in Godot Editor and:
1. Add a `TabContainer` as child of `menu` (anchors_preset=15, full rect)
2. Create Tab 1 named "对话": move existing VBoxContainer into it
3. Remove `ModelLoading` Label, `ModelButton` Button, and `ModelPopup` PopupMenu (no longer needed - model is fixed)
4. Add a simple `Label` showing "模型: deepseek-v4-pro" where ModelButton was
5. Create Tab 2 named "备忘录": add VBoxContainer with:
   - `TextEdit` (name: MemoTextEdit, min_size: Vector2(120, 150), wrap_mode=1, placeholder="在这里写备忘...")
   - `Button` (name: SaveMemoButton, text: "保存备忘录")
6. Connect SaveMemoButton `pressed` signal to main.gd

- [ ] **Step 2: Commit**

```bash
git add scenes/menu.tscn
git commit -m "feat: restructure menu with TabContainer for chat and memo tabs

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: Update pet.gd for New Signals

**Files:**
- Modify: `scripts/pet.gd`

**Consumes:**
- `DeepSeekClient.response_received` signal (Task 4)

- [ ] **Step 1: Edit pet.gd**

Replace the signal connection and simplify. The old code connects `OllamaClient.response_received`, change to `DeepSeekClient.response_received`.

Read current `scripts/pet.gd` and make these changes:

```gdscript
extends Area2D
class_name Pet

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $CanvasLayer/NameLabel
@onready var dialogue: RichTextLabel = $CanvasLayer/Dialogue

func _ready():
	DeepSeekClient.response_received.connect(_on_ai_response)
	DeepSeekClient.error_occurred.connect(_on_ai_error)

func _on_ai_response(response: String):
	print("AI: ", response)
	dialogue.text = response
	animate_text(response)

func _on_ai_error(error_msg: String):
	print("AI Error: ", error_msg)
	dialogue.text = "唔...奶龙走神了~ 等下再说吧！"

func animate_text(text: String):
	dialogue.visible_characters = 0
	dialogue.text = text
	for i in len(text):
		dialogue.visible_characters += 1
		await get_tree().create_timer(0.02).timeout

func _on_mouse_entered() -> void:
	name_label.visible = true

func _on_mouse_exited() -> void:
	name_label.visible = false

func anime_play(name: String, dir: Vector2) -> void:
	animated_sprite_2d.play(name)
	if dir.x < 0:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false
```

Key changes:
- Line 10: `OllamaClient.response_received` -> `DeepSeekClient.response_received`
- Line 11: Add `DeepSeekClient.error_occurred.connect(_on_ai_error)`
- Remove the old `load_and_send_file()` method (no longer needed)
- Add `_on_ai_error()` handler for error display
- Remove `_on_ai_response`'s `print(response)` line (keep it clean, just print)

- [ ] **Step 2: Commit**

```bash
git add scripts/pet.gd
git commit -m "feat: update pet.gd for DeepSeekClient signals

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 8: Update main.gd with Proactive AI and Memo Support

**Files:**
- Modify: `scripts/main.gd`

**Consumes:**
- `DeepSeekClient.send_message()` and `send_system_trigger()` (Task 4)
- `MemoManager.get_all_memos()`, `get_expired_reminders()`, `memo_updated` signal (Task 3)
- `PersonaManager` (Task 2)

- [ ] **Step 1: Rewrite main.gd**

Read current `scripts/main.gd` and replace with:

```gdscript
extends Node2D

@onready var pet: Pet = $Pet
@onready var menu: Control = $menu
@onready var tab_container: TabContainer = $menu/TabContainer

# Chat tab
@onready var quit_button: Button = $menu/TabContainer/对话/VBoxContainer/QuitButton
@onready var model_label: Label = $menu/TabContainer/对话/VBoxContainer/ModelLabel
@onready var text_edit: TextEdit = $menu/TabContainer/对话/VBoxContainer/TextEdit
@onready var send_button: Button = $menu/TabContainer/对话/VBoxContainer/SendButton

# Memo tab
@onready var memo_text_edit: TextEdit = $menu/TabContainer/备忘录/VBoxContainer/MemoTextEdit
@onready var save_memo_button: Button = $menu/TabContainer/备忘录/VBoxContainer/SaveMemoButton

# Drag state
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# Wander state
var is_moving: bool = false:
	set(value):
		var direct: Vector2 = target_position - Vector2(get_window().position)
		if value == true:
			if randi_range(0, 1) == 1:
				pet.anime_play("walk", direct)
			else:
				pet.anime_play("crouch", direct)
		else:
			pet.anime_play("idle", direct)
		is_moving = value
var target_position: Vector2 = Vector2.ZERO
var move_speed: float = 360.0
var wander_timer: float = 0.0
var wander_interval: float = 15.0

# Proactive AI state
var chatter_timer: float = 0.0
var chatter_interval: float = 0.0  # Set randomly each cycle
var last_activity_time: float = 0.0
var idle_triggered: bool = false
var idle_cooldown: float = 0.0
var reminder_check_timer: float = 0.0
var greeting_sent: bool = false

func _ready():
	# Hide menu initially
	menu.visible = false
	model_label.text = "模型: deepseek-v4-pro"

	# Connect signals
	pet.input_event.connect(_on_drag_area_input)
	quit_button.pressed.connect(_on_quit_button_pressed)
	send_button.pressed.connect(_on_send_button_pressed)
	save_memo_button.pressed.connect(_on_save_memo_pressed)
	text_edit.text_changed.connect(_on_text_changed)
	DeepSeekClient.error_occurred.connect(_on_ai_error)

	# Initialize random wander
	target_position = get_random_screen_position()

	# Initialize proactive AI timers
	_set_random_chatter_interval()
	last_activity_time = Time.get_unix_time_from_system()

	# Load memos into memo editor
	_refresh_memo_display()

func _set_random_chatter_interval():
	# Random between 15-30 minutes (900-1800 seconds)
	chatter_interval = randf_range(900.0, 1800.0)
	chatter_timer = 0.0

func _process(delta):
	if is_dragging:
		var mouse_pos = DisplayServer.mouse_get_position()
		get_window().position = Vector2(mouse_pos) - drag_offset
	else:
		handle_random_wander(delta)

	# Proactive AI timers
	if not is_dragging:
		_handle_proactive_ai(delta)

func _input(event):
	# Track user activity for idle detection
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		last_activity_time = Time.get_unix_time_from_system()
		if idle_triggered:
			idle_triggered = false
			idle_cooldown = 600.0  # 10 min cooldown after idle chat

func _handle_proactive_ai(delta):
	# Greeting on start (once, after 2 seconds)
	if not greeting_sent:
		greeting_sent = true
		get_tree().create_timer(2.0).timeout.connect(
			func(): DeepSeekClient.send_system_trigger("greeting")
		)
		return

	# Random chatter timer
	chatter_timer += delta
	if chatter_timer >= chatter_interval:
		chatter_timer = 0.0
		_set_random_chatter_interval()
		DeepSeekClient.send_system_trigger("random_chatter")

	# Idle detection (5 min no activity)
	idle_cooldown = max(0.0, idle_cooldown - delta)
	if idle_cooldown <= 0.0 and not idle_triggered:
		var idle_time = Time.get_unix_time_from_system() - last_activity_time
		if idle_time > 300.0:  # 5 minutes
			idle_triggered = true
			DeepSeekClient.send_system_trigger("idle_check")

	# Reminder check (every 30 seconds)
	reminder_check_timer += delta
	if reminder_check_timer >= 30.0:
		reminder_check_timer = 0.0
		var expired = MemoManager.get_expired_reminders()
		for memo in expired:
			DeepSeekClient.send_system_trigger("reminder", {"memo": memo})

func handle_random_wander(delta):
	if not is_moving:
		wander_timer += delta

	if get_window().position.distance_to(target_position) < 10:
		is_moving = false

	if wander_timer >= wander_interval:
		wander_timer = 0.0
		target_position = get_random_screen_position()
		is_moving = true

	if is_moving:
		var direction = (target_position - Vector2(get_window().position)).normalized()
		var movement = direction * move_speed * delta
		get_window().position += Vector2i(movement)

func get_random_screen_position() -> Vector2:
	var screen_size = DisplayServer.screen_get_size()
	var window_size = get_window().size
	var max_x = screen_size.x - window_size.x
	var max_y = screen_size.y - window_size.y
	return Vector2(randi_range(0, max_x), randi_range(0, max_y))

func _on_drag_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				is_moving = false
				drag_offset = pet.global_position + pet.get_local_mouse_position()
			else:
				is_dragging = false
				wander_timer = randf_range(0, wander_interval)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			toggle_menu()

func toggle_menu():
	menu.visible = !menu.visible
	# Refresh memo display when opening menu
	if menu.visible:
		_refresh_memo_display()

	var screen_size = get_viewport_rect().size
	if menu.position.x + menu.size.x > screen_size.x:
		menu.position.x = screen_size.x - menu.size.x
	if menu.position.y + menu.size.y > screen_size.y:
		menu.position.y = screen_size.y - menu.size.y

func _on_text_changed() -> void:
	pass  # No longer auto-save on text change

func _on_send_button_pressed() -> void:
	var text = text_edit.text.strip_edges()
	if text.is_empty():
		return
	DeepSeekClient.send_message(text)
	text_edit.text = ""
	menu.hide()

func _on_save_memo_pressed() -> void:
	var text = memo_text_edit.text.strip_edges()
	if text.is_empty():
		return
	# Simple approach: clear all and re-add as single memo
	# For multi-memo editing, parse lines starting with "- "
	var lines = text.split("
")
	for line in lines:
		var stripped = line.strip_edges()
		if stripped.begins_with("- "):
			stripped = stripped.substr(2)
		if not stripped.is_empty():
			MemoManager.add_memo(stripped, "")
	memo_text_edit.text = ""
	_refresh_memo_display()
	print("Memo saved!")

func _refresh_memo_display():
	var memos = MemoManager.get_all_memos()
	if memos.size() > 0:
		var text = ""
		for memo in memos:
			text += "- " + memo["content"]
			if memo.has("deadline") and not memo["deadline"].is_empty():
				text += " [截止: " + memo["deadline"] + "]"
			text += "
"
		memo_text_edit.text = text
	else:
		memo_text_edit.text = ""

func _on_ai_error(error_msg: String):
	print("AI Error: ", error_msg)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
```

- [ ] **Step 2: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: add proactive AI, idle detection, and memo support to main.gd

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 9: Update main.tscn Signal Connections

**Files:**
- Modify: `scenes/main.tscn`

**Consumes:**
- Updated main.gd (Task 8)
- Updated menu.tscn (Task 6)

- [ ] **Step 1: Update main.tscn references and signals**

Open `scenes/main.tscn` in Godot Editor or edit manually:

1. Update script path: `res://脚本/main.gd` -> `res://scripts/main.gd`
2. Update pet scene path: `res://场景/pet.tscn` -> `res://scenes/pet.tscn`
3. Update menu scene path: `res://场景/menu.tscn` -> `res://scenes/menu.tscn`
4. Remove old signal connections and add new ones:

Old connections to remove:
```
[connection signal="pressed" from="menu/Panel/VBoxContainer/ModelButton" to="." method="_on_model_button_pressed"]
[connection signal="pressed" from="menu/Panel/VBoxContainer/SendButton" to="." method="_on_send_button_pressed"]
```

New connections (paths depend on TabContainer structure after Task 6):
```
[connection signal="pressed" from="menu/TabContainer/对话/VBoxContainer/QuitButton" to="." method="_on_quit_button_pressed"]
[connection signal="pressed" from="menu/TabContainer/对话/VBoxContainer/SendButton" to="." method="_on_send_button_pressed"]
[connection signal="text_changed" from="menu/TabContainer/对话/VBoxContainer/TextEdit" to="." method="_on_text_changed"]
[connection signal="pressed" from="menu/TabContainer/备忘录/VBoxContainer/SaveMemoButton" to="." method="_on_save_memo_pressed"]
```

**Note:** The node paths must match exactly what was created in Task 6 menu.tscn. If paths differ, adjust accordingly.

- [ ] **Step 2: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: update main.tscn signal connections for new architecture

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 10: Clean Up Ollama Files

**Files:**
- Delete: `scripts/ollama_client.gd`
- Delete: `scripts/ollama_client.gd.uid`
- Delete: `scripts/main.gd.uid` (will be regenerated)
- Delete: `scripts/pet.gd.uid` (will be regenerated)

- [ ] **Step 1: Remove old files**

```bash
git rm scripts/ollama_client.gd scripts/ollama_client.gd.uid
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove old ollama client files

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Verification Checklist

After all tasks are complete:

1. **Open project in Godot Editor** - ensure no errors in the console
2. **Verify autoloads** - check Project Settings > Autoload: ClickThrough, DetectPassThrough, DeepSeekClient, MemoManager, PersonaManager all present
3. **Set API key** - edit `deepseek_config.json` with a real key
4. **Run the project** - pet should appear, say greeting after 2 seconds
5. **Right-click** - menu opens with two tabs (对话 + 备忘录)
6. **Chat tab** - type a message, click send, verify AI response appears as dialogue bubble
7. **Memo tab** - type a memo, click save, reopen menu to verify persistence
8. **Wait for idle** - don't touch mouse/keyboard for 5 minutes, verify pet sends idle message
9. **Reminder** - add a memo with deadline set to current time, verify reminder triggers within 30 seconds
