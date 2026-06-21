extends Node2D

@onready var _MainWindow: Window = get_window()
@onready var _SubWindow: Window = $Window
@onready var camera_2d: Camera2D = $Window/Camera2D
@onready var player: PlayerController = $Player
@onready var _Subwindow_2: Window = $SubViewport/Window2
@onready var camera_2d_2: Camera2D = $SubViewport/Window2/Camera2D
@onready var _Subwindow_3: Window = $SubViewport2/Window2
@onready var start_button: Button = $CanvasLayer/StartButton

var _needs_window_update: bool = false
var _last_main_window_pos: Vector2i
var _was_minimized: bool = false


func _ready():
	var language = "zh"
	if language == "zh":
		var preferred_language = OS.get_locale_language()
		TranslationServer.set_locale(preferred_language)
	else:
		TranslationServer.set_locale(language)
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", true)

	_SubWindow.world_2d = _MainWindow.world_2d
	_Subwindow_2.world_2d = _MainWindow.world_2d
	_Subwindow_3.world_2d = _MainWindow.world_2d

	_MainWindow.transparent_bg = true

	# 玩家移动时更新窗口位置（信号驱动，不再每帧轮询）
	player.player_moved.connect(_on_player_moved)

	# 在帧渲染完成后移动窗口，确保内容已更新再移动
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw)

	# 初始化所有窗口位置
	_update_subwindow()
	_update_static_windows()
	_last_main_window_pos = _MainWindow.position
	
	_MainWindow.grab_focus()

func _process(_delta: float) -> void:
	# 主窗口被拖动时更新子窗口位置
	if _MainWindow.position != _last_main_window_pos:
		_last_main_window_pos = _MainWindow.position
		_update_subwindow()
		_update_static_windows()

	# 检测主窗口最小化/恢复（visibility_changed 信号在 Godot 4 不响应 OS 级最小化）
	var is_minimized = _MainWindow.mode == Window.MODE_MINIMIZED
	if is_minimized != _was_minimized:
		_was_minimized = is_minimized
		if is_minimized:
			_SubWindow.hide()
			_Subwindow_2.hide()
			_Subwindow_3.hide()
		else:
			_SubWindow.show()
			_Subwindow_2.show()
			_Subwindow_3.show()
			_update_subwindow()
			_update_static_windows()


func _on_player_moved(_new_position: Vector2) -> void:
	_update_camera()
	_needs_window_update = true


func _on_frame_post_draw() -> void:
	if _needs_window_update:
		_needs_window_update = false
		_SubWindow.position = player.position + Vector2(_MainWindow.position) - Vector2(128, 128)


func _update_camera() -> void:
	camera_2d.position = player.position + Vector2(_SubWindow.size) / 2 - Vector2(128, 128)


func _update_subwindow() -> void:
	_SubWindow.position = player.position + Vector2(_MainWindow.position) - Vector2(128, 128)
	_update_camera()


func _update_static_windows() -> void:
	_Subwindow_2.position = Vector2(_MainWindow.position) + Vector2(96, 608)
	_Subwindow_3.position = Vector2(_MainWindow.position) - Vector2(160, 416)


func _on_start_button_pressed() -> void:
	start_button.hide()
