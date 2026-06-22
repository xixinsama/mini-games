## 进行节点移动的组件
class_name  MoveComponent
extends Node


@export var actor: Node2D
@export var velocity: Vector2
@export var roll_velocity: Vector2 = Vector2()
var sum_velocity: Vector2 
@export_group("Roll")
@export var roll_origin_rad_1:float = 0.0 ##加入旋转的初始角度 旋转弹
var roll_origin_rad_2:float = 0.0 ##加入旋转的初始角度 旋转追踪弹
@export var roll_vec_rad_1:float = -PI ##加入旋转的角度速度,正是顺时针，负是逆时针 旋转弹
@export var roll_vec_rad_2:float = 0.0 ##加入旋转的角度速度,正是顺时针，负是逆时针 旋转追踪弹
@export var roll_r_1:float = 0.0 ##旋转半径 旋转弹
var roll_r_2: float = 0.0 ##旋转半径 旋转追踪弹
@export_group("Trail")
@export var speed_trail_1:float = 0.0 ##追踪子弹速度 追踪弹
@export var speed_trail_2:float = 0.0 ##追踪子弹速度 直线追踪弹

var roll_v:Vector2 #旋转弹
var trail_v:Vector2#追踪弹
var trail_stright_v:Vector2 #直线追踪弹
var roll_trail_v:Vector2 #旋转追踪弹
@export var trail_pos: Vector2 = Status.player_position ##追踪谁
@export var trail_who: int = 0


@export_group("trigonometric")
@export_range(-180, 180, 0.001, "radians_as_degrees") var angle_radians = 0.0 ## 朝向，相互垂直
@export var amplitude: float = 0 ##振幅
@export var frequency: float = 1.0 ##频率，位移为（2 * 振幅/频率）
@export var phase: float = 0 ##相位
var trigo_v: Vector2
var phase_now: float = 0
var trail_stright_v_1: Vector2 = Vector2()
var is_bun: bool = false

func _ready() -> void:
	# 判定节点状态，连接关闭信号
	# actor.tree_exiting.connect(stop_process)
	if actor == null: return
	initialize()
	

func initialize(_flag: int = 0) -> void:
	if trail_who == 0:
		trail_pos = Status.player_position
	elif trail_who == 1:
		trail_pos = Status.enemy_position
	else:
		pass
	await get_tree().create_timer(0.1).timeout
	##代码 #直线追踪弹
	trail_stright_v_1 =(trail_pos - actor.position).normalized()
	##代码 #旋转追踪弹
	roll_r_2=(trail_pos - actor.position).length()/2
	roll_origin_rad_2=(trail_pos - actor.position).angle()-PI


func _process(delta):
##代码 旋转弹
	if actor == null: return
	if trail_who == 0:
		trail_pos = Status.player_position
	elif trail_who == 1:
		trail_pos = Status.enemy_position
	else:
		pass
	trail_stright_v =speed_trail_2*trail_stright_v_1.normalized();
	roll_origin_rad_1=roll_vec_rad_1*delta+roll_origin_rad_1#当前旋转的角度
	roll_v=Vector2(roll_r_1*cos(roll_origin_rad_1)-roll_r_1*cos(roll_origin_rad_1-roll_vec_rad_1*delta),roll_r_1*sin(roll_origin_rad_1)-roll_r_1*sin(roll_origin_rad_1-roll_vec_rad_1*delta))#在当前旋转角度和和半径干扰下的位移向量
##代码 #追踪弹
	#Status.player_position;
	#actor.global_position;
	trail_v =speed_trail_1*(trail_pos - actor.global_position ).normalized()# + speed_trail_1*Vector2(randfn(0,1),randfn(0,1))
##代码 #旋转追踪弹
	roll_origin_rad_2=roll_vec_rad_2*delta+roll_origin_rad_2#当前旋转的角度
	roll_trail_v=Vector2(roll_r_2*cos(roll_origin_rad_2)-roll_r_2*cos(roll_origin_rad_2-roll_vec_rad_2*delta),roll_r_2*sin(roll_origin_rad_2)-roll_r_2*sin(roll_origin_rad_2-roll_vec_rad_2*delta))#在当前旋转角度和和半径干扰下的位移向量
	# 三角函数
	var direct: Vector2 = Vector2.from_angle(angle_radians)
	#print("弧度", angle_radians)
	#print("方向", direct)
	phase_now += frequency * delta
	trigo_v = amplitude * sin(phase_now + phase) * direct
	# print(trigo_v)
##代码 向量求和
	sum_velocity = (velocity + roll_velocity) * delta + roll_v + trail_v * delta + trail_stright_v * delta + roll_trail_v + trigo_v * delta #总位移向量
	# print("en", sum_velocity)
##代码 反弹？
	if is_bun:
		if (sum_velocity + actor.global_position).x < 0 or (sum_velocity + actor.global_position).x > 720 :
			velocity.x = -velocity.x
			sum_velocity.x = -sum_velocity.x
			pass
		pass
	else:
		pass
	actor.translate(sum_velocity)

# 停止每帧运动
func stop_process() -> void:
	set_process(false)
