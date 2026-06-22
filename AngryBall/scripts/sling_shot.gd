extends Node3D

signal ball_launched

@export var ball: Node3D
@onready var rope_area: Area3D = $RopeArea
@onready var anchor_left: Marker3D = $AnchorLeft
@onready var anchor_right: Marker3D = $AnchorRight
@onready var path_3d: Path3D = $Path3D

var is_dragging = false
var max_drag_distance = 3.0  # 最大拖拽距离
var launch_force_multiplier = 15.0  # 发射力度倍数
var drag_smoothness = 0.3  # 拖拽平滑度 (0-1, 越小越平滑)

# 弹弓中心位置
var slingshot_center = Vector3.ZERO
var rope_initial_position = Vector3.ZERO

func _ready():
	# 连接Area3D的输入事件
	rope_area.input_event.connect(_on_rope_input_event)
	init_ball()

func init_ball():
	# 计算弹弓中心（两个锚点的中间）
	slingshot_center = (anchor_left.global_position + anchor_right.global_position) / 2.0
	# 记录rope_area的初始位置
	rope_initial_position = rope_area.global_position
	# 将小球初始化到弹弓位置
	if ball:
		ball.global_position = rope_area.global_position
	# 设置绳子的中心点
	path_3d.curve.clear_points()
	path_3d.curve.add_point(anchor_left.position)
	path_3d.curve.add_point(slingshot_center - global_position)
	path_3d.curve.add_point(anchor_right.position)

func _on_rope_input_event(_camera, event, _position, _normal, _shape_idx):
	# 处理鼠标点击事件
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖拽
				start_drag()
			else:
				# 松开鼠标，发射小球
				if is_dragging:
					release_ball()

func _input(event):
	# 处理鼠标移动事件
	if event is InputEventMouseMotion and is_dragging:
		update_drag(event.position)
	
	# 也可以通过这里处理松开鼠标（备用方案）
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_dragging:
			release_ball()

func start_drag():
	is_dragging = true
	print("Started dragging slingshot")

func update_drag(mouse_pos: Vector2):
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	# 将鼠标位置投射到3D空间
	var from = camera.project_ray_origin(mouse_pos)
	var ray_normal = camera.project_ray_normal(mouse_pos)
	
	# 计算与弹弓平面的交点（弹弓所在的平面）
	var plane = Plane(Vector3.UP, slingshot_center.y)
	var intersection = plane.intersects_ray(from, ray_normal)
	
	if intersection:
		# 计算拖拽偏移（相对于弹弓中心）
		var offset = intersection - slingshot_center
		
		# 限制拖拽距离
		var distance = offset.length()
		if distance > max_drag_distance:
			offset = offset.normalized() * max_drag_distance
		
		# 计算目标位置
		var target_position = slingshot_center + offset
		
		# 平滑移动rope_area和小球
		rope_area.global_position = rope_area.global_position.lerp(target_position, drag_smoothness)
		if ball:
			ball.global_position = rope_area.global_position
		path_3d.curve.set_point_position(1, rope_area.global_position - global_position)

func release_ball():
	if not is_dragging:
		return
	
	is_dragging = false
	
	# 计算发射方向和力度（从拖拽位置指向弹弓中心的反方向）
	var drag_offset = rope_area.global_position - slingshot_center
	var launch_direction = -drag_offset.normalized()  # 反方向发射
	var launch_power = drag_offset.length() / max_drag_distance  # 0-1的力度
	
	# 给小球施加力
	var launch_velocity = launch_direction * launch_power * launch_force_multiplier
	launch_velocity.y = abs(launch_velocity.y) + 3.0  # 增加向上的分量
	if ball:
		ball.launch(launch_velocity)
	
	# 重置rope_area位置
	rope_area.global_position = rope_initial_position
	# 发送信号
	ball_launched.emit()
	
	print("Ball launched with velocity: ", launch_velocity, " | Power: ", launch_power)
