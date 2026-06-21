extends Node2D

@onready var pet: Pet = $Pet
@onready var menu: Control = $menu
@onready var tab_container: TabContainer = $menu/TabContainer

# Chat tab
@onready var quit_button: Button = $menu/TabContainer/对话/QuitButton
@onready var model_label: Label = $menu/TabContainer/对话/ModelLabel
@onready var text_edit: TextEdit = $menu/TabContainer/对话/TextEdit
@onready var send_button: Button = $menu/TabContainer/对话/SendButton

# Memo tab
@onready var memo_text_edit: TextEdit = $menu/TabContainer/备忘录/MemoTextEdit
@onready var save_memo_button: Button = $menu/TabContainer/备忘录/SaveMemoButton

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
	DeepSeekClient.error_occurred.connect(_on_ai_error)
	MemoManager.memo_updated.connect(_refresh_memo_display)

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
	if event is InputEventKey or event is InputEventMouseButton:
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
	# Clear existing memos before re-adding to avoid duplication
	MemoManager.clear_all_memos()
	# Parse lines starting with "- "
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
