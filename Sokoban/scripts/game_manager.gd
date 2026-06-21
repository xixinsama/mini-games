extends Node
## 游戏管理节点
## 包含以下，但不包含游戏规则
## R 和 Z键的功能实现
## 游戏状态的初始化
## 游戏胜利条件
class_name GameManager

@onready var tile_map_layer: TileMapLayer = $"../TileMapLayer"
@onready var player: PlayerController = $"../Player"
@onready var boxes: Node2D = $"../Boxes"

# 游戏状态变量
var target_positions = []
var boxes_on_target = 0
var initial_player_position: Vector2
var initial_box_positions = []
var move_history = []  # 存储操作历史
var current_state_index = -1 # 当前状态在历史中的索引
var is_resetting = false # 防止重置时记录状态

func _ready():
	# 第一步：确保所有对象对齐网格
	align_all_objects_to_grid()

	# 从tile_map_layer获取所有目标点位置
	target_positions = tile_map_layer.get_all_target_positions()

	# 保存初始状态
	initial_player_position = player.position
	for box in boxes.get_children():
		initial_box_positions.append(box.position)
		box.connect("box_moved", check_win_condition)

	# 初始检查胜利条件
	check_win_condition(Vector2.ZERO)

	# 保存初始状态到历史
	save_current_state(true)  # 强制保存初始状态

# 确保所有对象对齐网格
func align_all_objects_to_grid():
	player.snap_to_grid()
	for box in boxes.get_children():
		box.snap_to_grid()

# 保存当前游戏状态
func save_current_state(force_save = false):
	if is_resetting and !force_save:
		return

	# 创建当前状态快照
	var current_box_positions = []
	for box in boxes.get_children():
		current_box_positions.append(box.position)

	var state = {
		"player_pos": player.position,
		"box_positions": current_box_positions,
		"is_reset": false  # 标记是否为重置操作
	}

	# 如果当前不在历史末尾，截断后面的历史
	if current_state_index < move_history.size() - 1:
		move_history.resize(current_state_index + 1)

	# 添加新状态
	move_history.append(state)
	current_state_index = move_history.size() - 1

	# 限制历史记录长度
	if move_history.size() > 100:
		move_history.pop_front()
		current_state_index -= 1

# 重置关卡
func reset_level():
	is_resetting = true

	# 创建重置状态快照
	var reset_state = {
		"player_pos": initial_player_position,
		"box_positions": initial_box_positions.duplicate(),
		"is_reset": true  # 标记为重置操作
	}

	# 应用重置状态
	apply_state(reset_state)

	# 保存重置状态到历史
	if current_state_index < move_history.size() - 1:
		move_history.resize(current_state_index + 1)

	move_history.append(reset_state)
	current_state_index = move_history.size() - 1

	is_resetting = false

	print("关卡已重置")

	# 重新检查胜利条件
	check_win_condition(Vector2.ZERO)

# 回退一步操作
func revert_step():
	if current_state_index <= 0:  # 无法回退到初始状态之前
		print("无法回退，历史记录不足")
		return

	# 回退到上一个状态
	current_state_index -= 1
	var prev_state = move_history[current_state_index]
	apply_state(prev_state)

	# 根据状态类型显示不同消息
	if prev_state.get("is_reset", false):
		print("已回退重置操作")
	else:
		print("已回退一步操作")

	# 重新检查胜利条件
	check_win_condition(Vector2.ZERO)

# 应用状态到游戏
func apply_state(state: Dictionary):
	# 停止所有移动动画（防止 tween 覆盖直接设置的位置）
	player.stop_movement()
	for box in boxes.get_children():
		box.stop_movement()

	# 应用玩家位置
	player.position = state["player_pos"]

	# 通知关卡脚本更新窗口位置（重置/回退操作）
	player.player_moved.emit(state["player_pos"])

	# 应用箱子位置
	for i in range(boxes.get_child_count()):
		boxes.get_child(i).position = state["box_positions"][i]

# 检查胜利条件
signal youwin
func check_win_condition(_pos):
	boxes_on_target = 0

	# 检查每个箱子是否在目标点上
	for box in boxes.get_children():
		if tile_map_layer.is_target(box.position):
			boxes_on_target += 1

	# 胜利条件：所有箱子在目标点
	if boxes_on_target == target_positions.size():
		print("You Win!")
		youwin.emit()
		# 此处可触发胜利画面或下一关

# 处理输入
func _unhandled_input(event):
	if event.is_action_pressed("reset"):  # R键
		reset_level()
		Records.increment_steps()
	elif event.is_action_pressed("revert"):  # Z键
		revert_step()
		Records.increment_steps()
