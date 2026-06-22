class_name PlayerManageComponent
extends Node


@export var actor: Node2D
@export var statscomponent: StatsComponent
@export var hurtboxcomponent: HurtboxComponent
@export var shake_component: ShakeComponent
@export var destroy_effect_spawner_component: SpawnerComponent
@export var flag_num: int = 0

func _ready() -> void:
	statscomponent.no_health.connect(_on_stats_component_no_health)
	# 自身碰撞盒发出信号，连接匿名函数，扣除血量
	hurtboxcomponent.hurt.connect(func(hitbox: HitboxComponent):
			# 使其晃动
		shake_component.tween_shake()
		statscomponent.health -= hitbox.damage
		)
	statscomponent.full_energy.connect(_on_energy_is_full)

# 当擦弹成功，增加能量
func _on_edge_ball_energy_up(energy_point: int) -> void:
	statscomponent.energy += energy_point

func _on_energy_is_full() -> void:
	statscomponent.energy = 0
	statscomponent.health += 1

# 血量为0时，播放爆炸效果，消失
func _on_stats_component_no_health() -> void:
	# create an effect (from the spawner component) and free the actor
	destroy_effect_spawner_component.spawn(actor.global_position, get_tree().current_scene, flag_num)
	#if flag_num == 0: #player组
	actor.queue_free()
	#if flag_num == 1: #enemy组
		#actor.visible = false
		#nextlevel.emit()
		#await get_tree().create_timer(2.0).timeout
		#actor.visible = true
