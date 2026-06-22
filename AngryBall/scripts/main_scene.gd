extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var slingshot: Node3D = $SlingShot
@onready var ball: PinBall3d = $Ball
@onready var killzone: KillZone = $KillZone
## UI
@onready var game_start: Control = $UI/GameStart
@onready var gaming: Control = $UI/Gaming
@onready var timer_label: Label = $UI/Gaming/TimeLabel
@onready var fin: Control = $UI/Fin
@onready var message_label: Label = $UI/Fin/VBoxContainer/MessageLabel
@onready var score_label: Label = $UI/Fin/VBoxContainer/ScoreLabel
@onready var rank_label: Label = $UI/Fin/VBoxContainer/ScrollContainer/RankLabel

var game_started: bool = false
var game_ended: bool = false
var score: int = 0
var score_string: String = ""
var score_history: Array[int] = [0]
var rank_string: String = ""
## 当前关
var level: int = 0

# 摄像机初始位置和目标位置
var camera_follow_offset: Vector3 = Vector3(0, 8, 8)  # 俯视角60度的偏移
var camera_init_position: Vector3
var camera_init_rotation: Vector3
# ========== 新增：体素破坏统计 ==========
var total_voxels_destroyed = 0  # 总共破坏的体素数量
var combo_multiplier = 1.0  # 连击倍率
var last_destruction_time = 0.0  # 上次破坏时间
const COMBO_TIMEOUT = 2.0  # 连击超时时间（秒）

@export var time_counter: Timer

func _ready():
	# 连接弹弓信号
	slingshot.ball_launched.connect(_on_ball_launched)
	# 连接KillZone信号
	if killzone:
		killzone.ball_out_of_bounds.connect(_on_ball_out_of_bounds)
	time_counter.timeout.connect(end_game.bind(false))
	
	camera_init_position = camera.global_position
	camera_init_rotation = camera.global_rotation
	gaming.hide()
	fin.hide()

func _process(delta):
	if game_started and not game_ended:
		update_ui()
		follow_ball(delta)

func _input(event):
	# 游戏结束后，按左键重新开始
	if game_ended and event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT) \
		and event.pressed:
			reset_game()

func _on_ball_launched():
	# 开始游戏计时
	game_start.hide()
	gaming.show()
	game_started = true
	game_ended = false
	time_counter.start()

func follow_ball(delta):
	# 平滑跟随小球，保持俯视角
	var target_pos = ball.global_position + camera_follow_offset
	camera.global_position = camera.global_position.lerp(target_pos, delta * 5.0)
	# 摄像机始终看向小球
	camera.look_at_from_position(ball.global_position, Vector3.UP)

func on_ball_out_of_bounds():
	# 小球出界，游戏结束
	if not game_ended:
		end_game(true)  # 出界结束

func _on_ball_out_of_bounds():
	# 小球出界的信号回调
	on_ball_out_of_bounds()

func end_game(out_of_bounds: bool):
	if game_ended: return
	game_ended = true
	game_started = false
	gaming.hide()
	fin.show()
	# 停止小球
	ball.stop()
	
	if out_of_bounds:
		print("\n=== Ball went out of bounds! ===")
		score_string += "Out of bounds!\n"
	else:
		print("\n=== Time's up! ===")
		score_string += "Time's up!\n"
	
	score = VoxelServer.get_destroyed_voxel_count() - score_history[level]
	score_history.append(score)
	show_sorted_scores()
	rank_label.text = rank_string
	score_string += "Final Score: %d" % score
	score_label.text = score_string
	print("Final Score: %d" % score)
	print("Click left mouse button to restart\n")

func show_sorted_scores():
	# 过滤掉第一个零分
	var filtered = score_history.duplicate()
	if filtered.size() > 0 and filtered[0] == 0:
		filtered.remove_at(0)
	
	# 创建索引-分数对并排序
	var indexed = []
	for i in range(filtered.size()):
		indexed.append({"idx": i+1, "score": filtered[i]})
	
	# 排序：先分数降序，再索引升序
	indexed.sort_custom(func(a, b): 
		return a.score > b.score or (a.score == b.score and a.idx < b.idx)
	)
	rank_string = ""
	# 输出结果
	print("总次数: " + str(indexed.size()))
	rank_string += "GameNumber: " + str(indexed.size()) + "\n" + "Rankings:\n"
	for i in range(indexed.size()):
		print(str(i+1) + ". " + str(indexed[i].score) + " (第" + str(indexed[i].idx) + "次)")
		rank_string += str(i+1) + ". " + str(indexed[i].score) + "\n"

func update_ui():
	timer_label.text = "Time: %.1f" % time_counter.time_left

const Loading = preload("uid://dqjqnlddnx7pb")
func reset_game():
	print("\n=== Restarting game... ===\n")
	
	# 重置游戏状态
	game_started = false
	game_ended = false
	level += 1
	score = 0
	score_string = ""
	
	# 重置小球状态
	if ball:
		ball.reset_position()
	
	game_start.show()
	gaming.hide()
	fin.hide()
	
	camera.global_position = camera_init_position
	camera.global_rotation = camera_init_rotation
	slingshot.init_ball()
	
	## 创建并显示加载场景
	#var loading_screen = LOADING_SCREEN.instantiate()
	#get_tree().root.add_child(loading_screen)
	#
	## 获取当前场景路径
	#var current_scene_path = "res://scenes/main_scene.tscn"
	## 开始加载场景
	#loading_screen.load_scene(current_scene_path)
	#if LOADING_SCREEN:
		#get_tree().change_scene_to_packed(LOADING_SCREEN)
	
	print("Loading scene...")
