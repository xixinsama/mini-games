extends State
class_name Attack2

@export var enemy: Enemy
@export var spawner_component: SpawnerComponent

# 三路来回弹
func Enter():
	var luo: Bullet = null
	var luo_1: Bullet = null
	var luo_2: Bullet = null
	var num: int = 7 ##子弹数量
	var speed: int = 450 ##子弹速度
	var frame_bullet = 19 ##子弹样式
	var e_2_p: Vector2 = Vector2() 
	for i in range(0,num):
		if enemy != null:
			e_2_p = (Status.player_position - enemy.global_position).normalized()
			luo = spawner_component.spawn(enemy.global_position,self,0)
			luo.velocity = speed * e_2_p
			luo.frame = frame_bullet
			luo.initialize()
			luo.move_component.is_bun = true
			
			e_2_p = (-enemy.global_position + Vector2(-Status.player_position.x, Status.player_position.y)).normalized()
			luo_1 = spawner_component.spawn(enemy.global_position,self,0)
			luo_1.velocity = speed * e_2_p
			luo_1.frame = frame_bullet
			luo_1.initialize()
			luo_1.move_component.is_bun = true
			
			e_2_p = (-enemy.global_position + Vector2(720*2-Status.player_position.x, Status.player_position.y)).normalized()
			luo_2 = spawner_component.spawn(enemy.global_position,self,0)
			luo_2.velocity = speed * e_2_p
			luo_2.frame = frame_bullet
			luo_2.initialize()
			luo_2.move_component.is_bun = true

	Transitioned.emit(self, "EnemyIdle")
