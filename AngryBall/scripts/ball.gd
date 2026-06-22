extends RigidBody3D
class_name PinBall3d

var is_launched = false

# ========== 体素破坏相关 ==========
@onready var voxel_damager: VoxelDamager = %VoxelDamager
const EXPLOSION = preload("uid://bbeyusaoy77fn")
var last_collision_point = Vector3.ZERO  # 上次碰撞点

func _ready():
	add_to_group("Ball")
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	# 初始状态冻结小球（在弹弓上时）
	freeze = true

func launch(launch_velocity: Vector3):
	is_launched = true
	freeze = false  # 解除冻结
	linear_velocity = launch_velocity
	print("Ball launched with velocity: ", launch_velocity)

func _on_body_entered(body):
	if not is_launched:
		return
	
	# 获取碰撞时的速度大小
	#var impact_force = linear_velocity.length()
	# 检查是否碰撞到体素物体（VoxelObject）
	if body is StaticBody3D:
		_damage_voxel_object()

func _damage_voxel_object():
	if not voxel_damager:
		push_warning("VoxelDamager not available")
		return
	
	# 获取碰撞点（使用小球当前位置作为近似）
	var collision_point = global_position
	last_collision_point = collision_point
	
	# 设置VoxelDamager位置到碰撞点
	voxel_damager.global_position = collision_point
	var explosion := EXPLOSION.instantiate()
	add_child(explosion)
	explosion.explode()
	
	# 必须等待2个物理帧，以获取碰撞区域
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# 执行破坏
	voxel_damager.hit()
	#print(VoxelServer.get_destroyed_voxel_count())

func reset_position():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	is_launched = false
	freeze = true  # 重新冻结

func stop():
	# 停止小球运动
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
