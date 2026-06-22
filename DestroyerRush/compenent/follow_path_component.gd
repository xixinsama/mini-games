## 控制节点按照路径移动(强制移动，直接操作位置)
class_name FollowPathComponent
extends Node2D

@export var actor: Node2D
@export var path_points: Curve2D = null ##绘制曲线，将节点按曲线轨迹移动
@export var auto_start: bool = false ##是否自动开启（立即），建议使用方法start_follow()
@export var is_around: bool = false ##是否来回移动，周期为到终点后原路返回起点。若is_loop为false，则只来回一次。在终点会原路返回。
@export var is_loop: bool = true ##是否循环。若曲线未闭合，则会直接跳到起点。
@export var speed: int = 0 ##节点移动的速度

var distance_along_path: float = 0.0 # 当前位置
var path_length: float # 总路径长度
var going_forward: bool = true # 标识当前是否向前移动
var is_following: bool = false # 标识是否正在跟随路径
signal finish_oneloop ##一次路径巡游结束后发送信号, 如果是is_loop为true，则每次都发送信号

func _ready() -> void:
	if path_points != null and actor != null:
		actor.tree_exiting.connect(stop_process)
		if auto_start == true:
			start_follow()
	else:
		stop_process()
		return

func start_follow(progress: float = 0) -> void:
		#if path_points == null:
			#print("为什么呢？")
			#return
		auto_start = false
		distance_along_path = progress
		is_following = true
		set_process(true)

# 停止运动
func stop_process() -> float:
	is_following = false
	set_process(false)
	return distance_along_path

func _process(delta: float) -> void:
	if !is_following:
		return
	# 每次都获取总长，万一有要加点呢？
	path_length = path_points.get_baked_length() # 路径总长度
	# print(path_length)
	# 只去一次
	if not is_around and not is_loop:
		distance_along_path += speed * delta
		distance_along_path = clamp(distance_along_path, 0, path_length)
		if distance_along_path == path_length:
			finish_oneloop.emit()
			stop_process()
	# 来回循环
	if is_around:
		if going_forward:
			if distance_along_path >= path_length:
				going_forward = false
			else:
				distance_along_path += speed * delta
		else:
			if distance_along_path <= 0:
				going_forward = true
				# 不准循环
				if not is_loop:
					finish_oneloop.emit()
					stop_process()
			else:
				distance_along_path -= speed * delta
			distance_along_path = clamp(distance_along_path, 0, path_length)
	# 一直循环走
	if not is_around and is_loop:
		distance_along_path += speed * delta
		# print(distance_along_path)
		if distance_along_path > path_length:
			distance_along_path -= path_length
			finish_oneloop.emit()
		if distance_along_path < 0:
			distance_along_path += path_length
			finish_oneloop.emit()
	# 获取位置
	var new_position: Vector2 = path_points.sample_baked(distance_along_path)
	actor.global_position = new_position

## 获取当前路径总长度
func get_path_length() -> float: 
	return path_length
