extends State
class_name Attack0

@export var enemy: Enemy
@export var spawner_component: SpawnerComponent

# 散射波浪
func Enter():
	var luo: Bullet = null
	var rad: float = PI/6
	var num: int = 6 ##子弹数量
	var speed: int = 500 ##子弹速度
	var frame_bullet = 13 ##子弹样式
	for i in range(0,num):
		if enemy != null:
			luo = spawner_component.spawn(enemy.global_position,self,0)
			luo.velocity = speed * Vector2.from_angle((Status.player_position - enemy.global_position).angle()  + rad)
			rad = rad - PI/((num) * 3)
			#speed = speed + 10
			luo.frame = frame_bullet
			#luo.wait_time = 2.0
			#luo.life_timer.timeout.connect(asign_value_1.bind(luo))
			#luo.life_timer.one_shot = false
			luo.initialize()
			await get_tree().create_timer(0.01).timeout
			#luo.life_timer.start()
	for i in range(0,num):
		if enemy != null:
			luo = spawner_component.spawn(enemy.global_position,self,0)
			luo.velocity = speed * Vector2.from_angle((Status.player_position - enemy.global_position).angle()  + rad)
			rad = rad + PI/((num) * 3)
			luo.frame = frame_bullet
			luo.initialize()
			await get_tree().create_timer(0.01).timeout
	for i in range(0,num):
		if enemy != null:
			luo = spawner_component.spawn(enemy.global_position,self,0)
			luo.velocity = speed * Vector2.from_angle((Status.player_position - enemy.global_position).angle()  + rad)
			rad = rad - PI/(num * 3)
			luo.frame = frame_bullet
			luo.initialize()
			await get_tree().create_timer(0.01).timeout
			
	Transitioned.emit(self, "EnemyIdle")
