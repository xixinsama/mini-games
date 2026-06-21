extends CharacterBody2D
class_name PlayerController

signal player_moved(new_position: Vector2)

# 移动参数
const GRID_SIZE = 64  # 网格大小
const MOVE_DURATION = 0.1  # 移动动画时长（秒）

var moving = false
var _move_tween: Tween

@export var tilemap: TileMapLayer
@export var game_manager: Node  # 在编辑器中拖拽GameManager节点到这里


func snap_to_grid():
	var near: Vector2 = position - Vector2.ONE * GRID_SIZE / 2
	position = near.snapped(Vector2.ONE * GRID_SIZE) + Vector2.ONE * GRID_SIZE / 2


func _process(_delta: float) -> void:
	# 移动动画期间持续通知窗口跟随
	if moving:
		player_moved.emit(position)


func _unhandled_input(event):
	if moving: return
	# 检测方向键输入
	if event.is_action_pressed("move_right"):
		try_move(Vector2.RIGHT)
		Records.increment_steps()
	if event.is_action_pressed("move_left"):
		try_move(Vector2.LEFT)
		Records.increment_steps()
	if event.is_action_pressed("move_down"):
		try_move(Vector2.DOWN)
		Records.increment_steps()
	if event.is_action_pressed("move_up"):
		try_move(Vector2.UP)
		Records.increment_steps()


func try_move(dir: Vector2):
	var target_pos = position + dir * GRID_SIZE

	if not tilemap:
		printerr("tilemaplayer不存在；player未登记tilemaplayer")
		return
	if !tilemap.has_method("is_wall"):
		printerr("tilemaplayer不存在方法is_wall。player必要调用")
		return

	# 检测前方是否有墙
	if tilemap.is_wall(target_pos):
		return

	# 检测前方是否有箱子
	for box in get_parent().get_node("Boxes").get_children():
		if box.position == target_pos:
			if !box.try_push(dir):  # 尝试推动箱子
				return

	# 使用 Tween 动画移动
	moving = true
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position", target_pos, MOVE_DURATION)
	_move_tween.tween_callback(_on_move_finished.bind(target_pos))


func _on_move_finished(_target_pos: Vector2) -> void:
	moving = false
	_move_tween = null
	player_moved.emit(position)
	# 通知游戏管理器保存状态
	if game_manager:
		game_manager.save_current_state()


## 强制停止移动动画（由 GameManager 在重置/回退时调用）
func stop_movement() -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
		_move_tween = null
	moving = false
