## 攻击碰撞盒组件
class_name HitboxComponent
extends Area2D

# 每个子弹只有材质和碰撞盒两个性质
# 而攻击碰撞盒内，导出两个数值
# 一是伤害，击中后扣除对方血量
# 二是能量，擦弹后增加对方能量
@export var damage: int = 1
@export var energy_point: int = 1

# 创建一个信号，当攻击碰撞盒 击中 受击碰撞盒
signal hit_hurtbox(hurtbox)

# 标记是否已经擦弹
var has_grazed: bool = false

func _ready():
	# Connect on area entered to our hurtbox entered function
	area_entered.connect(_on_hurtbox_entered)

func _on_hurtbox_entered(hurtbox):
	# 确保我们重叠的区域是伤害区
	if not hurtbox is HurtboxComponent: return
	# 确保受击碰撞盒不是无敌状态
	if hurtbox.is_invincible: return
	#print("hurt_area:", hurtbox.name)
	# Signal out that we hit a hurtbox (this is useful for destroying projectiles when they hit something)
	# 发出信号表明我们击中了受击碰撞盒（这对于在子弹击中某物时摧毁射弹很有用）
	hit_hurtbox.emit(hurtbox)
	# Have the hurtbox signal out that it was hit
	# 受击碰撞盒发送 被击中 信号
	hurtbox.hurt.emit(self)
