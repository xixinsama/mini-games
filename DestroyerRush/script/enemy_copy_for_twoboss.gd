extends Node2D
class_name SubEnemy

@export_range(0, 24) var enemy_looklike: int = 0 ## 选择敌人皮肤
@export_range(0,4) var enemy_destroy_effect: int = 0 ## 选择敌人爆炸效果
@export var enemy_health_max: int = 1## 在关卡中设置最大血量
@export var enemy_health: int = 1## 在关卡中设置血量
@export var enemy_speed: int = 200## 在关卡中设置敌人速度
@export var enemy_damage: int = 1 ## 敌人的碰撞伤害
@export var energy_point: int = 0 ## 敌人死亡(或其他情况)给玩家回复能量点数

func _ready() -> void:
	# 初始化
	var sprite_2d: Sprite2D = get_node("Sprite2D")
	var stats_component: StatsComponent = get_node("StatsComponent")
	var enemy_manage_component: PlayerManageComponent = get_node("EnemyManageComponent")
	var hitbox_component: HitboxComponent = get_node("HitboxComponent")
	
	sprite_2d.frame = enemy_looklike
	stats_component.health_max = enemy_health_max
	stats_component.health = enemy_health
	stats_component.speed = enemy_speed
	enemy_manage_component.flag_num = enemy_destroy_effect
	hitbox_component.damage = enemy_damage
	hitbox_component.energy_point = energy_point
