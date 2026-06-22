## 控制擦弹，外层Area2D包裹内层Hurtbox
class_name EdgeBall
extends Node2D

@export var outer: Area2D
@export var inner: HurtboxComponent

## 擦弹后增加能量
signal energy_up(energy_point: float)

# 存储每个进入 outer_shape 的 hitbox 状态
var grazed_hitboxes = {}

# 连接信号
func _ready():
	outer.area_entered.connect(_on_outer_shape_body_entered)
	outer.area_exited.connect(_on_outer_shape_body_exited)
	inner.area_entered.connect(_on_inner_shape_body_entered)

# 进入外层区域
func _on_outer_shape_body_entered(body: HitboxComponent):
	if body is HitboxComponent:
		if not body.has_grazed:
			grazed_hitboxes[body] = true
			# print("进入擦弹:", body.name)

# 离开外层区域
func _on_outer_shape_body_exited(body: HitboxComponent):
	if body is HitboxComponent:
		if not body.has_grazed:
			if grazed_hitboxes.has(body) and grazed_hitboxes[body]:
				body.has_grazed = true
				# print("擦弹成功")
				# 成功则加能量
				energy_up.emit(body.energy_point)
			grazed_hitboxes.erase(body)

# 进入内层区域
func _on_inner_shape_body_entered(body: HitboxComponent):
	if body is HitboxComponent:
		if not body.has_grazed:
			body.has_grazed = true
			if grazed_hitboxes.has(body):
				grazed_hitboxes[body] = false
			# 但不是从这里结算伤害
			# print("受伤")
			# 发送清除弹幕信号
		# body.hit_hurtbox.emit(self)

# 注册 hitbox 进入 GrazingArea
func register_hitbox(hitbox):
	grazed_hitboxes[hitbox] = false
