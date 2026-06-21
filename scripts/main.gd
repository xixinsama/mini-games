extends Node2D

@onready var pet: Pet = $Pet
@onready var menu: Control = $menu
@onready var tab_container: TabContainer = $menu/TabContainer

# Chat tab
@onready var quit_button: Button = $menu/TabContainer/对话/QuitButton
@onready var model_label: Label = $menu/TabContainer/对话/ModelLabel
@onready var text_edit: TextEdit = $menu/TabContainer/对话/TextEdit
@onready var send_button: Button = $menu/TabContainer/对话/SendButton
@onready var settings_button: Button = $menu/TabContainer/对话/SettingsButton

# Memo tab
@onready var memo_text_edit: TextEdit = $menu/TabContainer/备忘录/MemoTextEdit
@onready var save_memo_button: Button = $menu/TabContainer/备忘录/SaveMemoButton

# Config dialog (created in _ready)
var config_dialog: AcceptDialog
var config_api_key_input: LineEdit
var config_model_input: LineEdit
var config_base_url_input: LineEdit
var config_thinking_check: CheckBox

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
var chatter_interval: float = 0.0
var last_activity_time: float = 0.0
var idle_triggered: bool = false
var idle_cooldown: float = 0.0
var reminder_check_timer: float = 0.0
var greeting_sent: bool = false


func _ready():
	menu.visible = false
	_refresh_model_label()

	# Connect signals (button signals are in main.tscn)
	pet.input_event.connect(_on_drag_area_input)
	DeepSeekClient.error_occurred.connect(_on_ai_error)
	DeepSeekClient.config_loaded.connect(_on_config_loaded)
	MemoManager.memo_updated.connect(_refresh_memo_display)

	# Build config dialog
	_build_config_dialog()

	# Initialize random wander
	target_position = get_random_screen_position()

	# Initialize proactive AI timers
	_set_random_chatter_interval()
	last_activity_time = Time.get_unix_time_from_system()

	# Load memos
	_refresh_memo_display()


func _build_config_dialog():
	config_dialog = AcceptDialog.new()
	config_dialog.title = "API 设置"
	config_dialog.ok_button_text = "保存"
	add_child(config_dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	config_dialog.add_child(vbox)

	# API Key
	var key_label = Label.new()
	key_label.text = "API Key:"
	vbox.add_child(key_label)

	config_api_key_input = LineEdit.new()
	config_api_key_input.placeholder_text = "sk-..."
	config_api_key_input.secret = true
	vbox.add_child(config_api_key_input)

	# Model
	var model_label_widget = Label.new()
	model_label_widget.text = "模型名称:"
	vbox.add_child(model_label_widget)

	config_model_input = LineEdit.new()
	config_model_input.placeholder_text = "deepseek-v4-pro / gpt-4o"
	vbox.add_child(config_model_input)

	# Base URL
	var url_label = Label.new()
	url_label.text = "API 地址:"
	vbox.add_child(url_label)

	config_base_url_input = LineEdit.new()
	config_base_url_input.placeholder_text = "https://api.deepseek.com"
	vbox.add_child(config_base_url_input)

	# Thinking toggle (DeepSeek only)
	config_thinking_check = CheckBox.new()
	config_thinking_check.text = "启用 Thinking 模式 (仅 DeepSeek)"
	vbox.add_child(config_thinking_check)

	# Preset buttons
	var preset_hbox = HBoxContainer.new()
	vbox.add_child(preset_hbox)

	var deepseek_btn = Button.new()
	deepseek_btn.text = "DeepSeek 预设"
	deepseek_btn.pressed.connect(_on_preset_deepseek)
	preset_hbox.add_child(deepseek_btn)

	var openai_btn = Button.new()
	openai_btn.text = "OpenAI 预设"
	openai_btn.pressed.connect(_on_preset_openai)
	preset_hbox.add_child(openai_btn)

	config_dialog.confirmed.connect(_on_config_save)
	config_dialog.custom_minimum_size = Vector2(340, 0)


func _on_preset_deepseek():
	config_model_input.text = "deepseek-v4-pro"
	config_base_url_input.text = "https://api.deepseek.com"
	config_thinking_check.button_pressed = true


func _on_preset_openai():
	config_model_input.text = "gpt-4o"
	config_base_url_input.text = "https://api.openai.com/v1"
	config_thinking_check.button_pressed = false


func _on_settings_pressed():
	var cfg = DeepSeekClient.get_config()
	config_api_key_input.text = cfg.get("api_key", "")
	config_model_input.text = cfg.get("model", "deepseek-v4-pro")
	config_base_url_input.text = cfg.get("base_url", "https://api.deepseek.com")
	config_thinking_check.button_pressed = cfg.get("thinking", true)
	config_dialog.popup_centered()


func _on_config_save():
	var new_config = {
		"api_key": config_api_key_input.text.strip_edges(),
		"model": config_model_input.text.strip_edges(),
		"base_url": config_base_url_input.text.strip_edges().rstrip("/"),
		"thinking": config_thinking_check.button_pressed,
		"reasoning_effort": "high"
	}
	DeepSeekClient.save_config(new_config)
	_refresh_model_label()
	print("API config saved")


func _on_config_loaded(success: bool):
	if not success:
		get_tree().create_timer(0.5).timeout.connect(
			func(): _on_settings_pressed()
		)
	_refresh_model_label()


func _refresh_model_label():
	var cfg = DeepSeekClient.get_config()
	var model = cfg.get("model", "")
	if model.is_empty():
		model = "未设置"
	model_label.text = "模型: " + model


func _set_random_chatter_interval():
	chatter_interval = randf_range(900.0, 1800.0)
	chatter_timer = 0.0


func _process(delta):
	if is_dragging:
		var mouse_pos = DisplayServer.mouse_get_position()
		get_window().position = Vector2(mouse_pos) - drag_offset
	else:
		handle_random_wander(delta)

	if not is_dragging:
		_handle_proactive_ai(delta)


func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		last_activity_time = Time.get_unix_time_from_system()
		if idle_triggered:
			idle_triggered = false
			idle_cooldown = 600.0


func _handle_proactive_ai(delta):
	if not greeting_sent:
		greeting_sent = true
		get_tree().create_timer(2.0).timeout.connect(
			func(): DeepSeekClient.send_system_trigger("greeting")
		)
		return

	chatter_timer += delta
	if chatter_timer >= chatter_interval:
		chatter_timer = 0.0
		_set_random_chatter_interval()
		DeepSeekClient.send_system_trigger("random_chatter")

	idle_cooldown = max(0.0, idle_cooldown - delta)
	if idle_cooldown <= 0.0 and not idle_triggered:
		var idle_time = Time.get_unix_time_from_system() - last_activity_time
		if idle_time > 300.0:
			idle_triggered = true
			DeepSeekClient.send_system_trigger("idle_check")

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
	return Vector2(randi_range(0, max(0, max_x)), randi_range(0, max(0, max_y)))


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

	var screen_size = get_viewport_rect().size
	if menu.position.x + menu.size.x > screen_size.x:
		menu.position.x = screen_size.x - menu.size.x
	if menu.position.y + menu.size.y > screen_size.y:
		menu.position.y = screen_size.y - menu.size.y


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
	MemoManager.clear_all_memos()
	var lines = text.split("\n")
	for line in lines:
		var stripped = line.strip_edges()
		if stripped.begins_with("- "):
			stripped = stripped.substr(2)
		if not stripped.is_empty():
			MemoManager.add_memo(stripped, "")
	memo_text_edit.text = ""
	print("Memo saved!")


func _refresh_memo_display():
	var memos = MemoManager.get_all_memos()
	if memos.size() > 0:
		var text = ""
		for memo in memos:
			text += "- " + memo["content"]
			if memo.has("deadline") and not memo["deadline"].is_empty():
				text += " [截止: " + memo["deadline"] + "]"
			text += "\n"
		memo_text_edit.text = text
	else:
		memo_text_edit.text = ""


func _on_ai_error(error_msg: String):
	print("AI Error: ", error_msg)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
