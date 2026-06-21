extends CharacterBody2D
class_name Box

signal box_moved(new_position)

const GRID_SIZE = 64  # 网格大小
const MOVE_DURATION = 0.1  # 推动动画时长（秒）

var _move_tween: Tween

@export var tilemap: TileMapLayer


func snap_to_grid():
	var near: Vector2 = position - Vector2.ONE * GRID_SIZE / 2
	position = near.snapped(Vector2.ONE * GRID_SIZE) + Vector2.ONE * GRID_SIZE / 2


func try_push(dir: Vector2) -> bool:
	var target_pos = position + dir * GRID_SIZE

	# 检测目标位置是否可推动
	if tilemap.is_wall(target_pos):
		return false

	# 检测是否有其他箱子
	for other_box in get_parent().get_children():
		if other_box != self and other_box.position == target_pos:
			return false  # 被其他箱子挡住

	# 使用 Tween 动画推动箱子
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position", target_pos, MOVE_DURATION)
	_move_tween.tween_callback(func():
		_move_tween = null
		emit_signal("box_moved", target_pos)
	)
	return true


## 强制停止推动动画（由 GameManager 在重置/回退时调用）
func stop_movement() -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
		_move_tween = null
