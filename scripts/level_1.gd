extends Node2D

@onready var _MainWindow: Window = get_window()
@onready var _SubWindow: Window = $Window
@onready var camera_2d: Camera2D = $Window/Camera2D
@onready var player: PlayerController = $Player
@onready var _SubWindow_2: Window = $Window2
@onready var camera_2d_2: Camera2D = $Window2/Camera2D
@onready var game_manager: GameManager = $GameManager
@onready var ui_layer: CanvasLayer = $UI

var _needs_window_update: bool = false
var _last_main_window_pos: Vector2i
var _was_minimized: bool = false


func _ready() -> void:
	_SubWindow.world_2d = _MainWindow.world_2d
	_SubWindow_2.world_2d = _MainWindow.world_2d
	_MainWindow.transparent_bg = true
	_MainWindow.maximize_disabled = true

	# 玩家移动时更新窗口位置（信号驱动，不再每帧轮询）
	player.player_moved.connect(_on_player_moved)

	# 在帧渲染完成后移动窗口，确保内容已更新再移动
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw)

	# 通关检测
	game_manager.youwin.connect(_on_win)

	# 初始化窗口位置
	_update_subwindow()
	_update_static_windows()
	_last_main_window_pos = _MainWindow.position


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
			_SubWindow_2.hide()
		else:
			_SubWindow.show()
			_SubWindow_2.show()
			_update_subwindow()
			_update_static_windows()


func _on_player_moved(_new_position: Vector2) -> void:
	# 更新摄像机位置（立即，确保当前帧渲染正确内容）
	_update_camera()
	# 延迟到帧渲染完成后移动窗口
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
	_SubWindow_2.position = Vector2(_MainWindow.position) + (camera_2d_2.position - Vector2(_SubWindow_2.size) / 2)


## 通关：显示 UI，取消摄像机窗口置顶
func _on_win() -> void:
	ui_layer.visible = true
	_SubWindow.always_on_top = false
	_MainWindow.grab_focus()
	#_SubWindow_2.always_on_top = false


## 进入下一关
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")
