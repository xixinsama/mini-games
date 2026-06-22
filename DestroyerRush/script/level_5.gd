extends Node2D
class_name LeveL

# 三个阶段（25，50，75），每一阶段会放出另一个之前打过的BOSS，但是削弱过的版本
# 在放出之前的BOSS之后，不可索敌，停止移动，等杀死另一个BOSS之后恢复
# 召唤出的BOSS血量降低，只会一种弹幕攻击模式，移动方式随机
# 此BOSS每个阶段多增加一种弹幕，第三阶段就四种攻击模式，其中一种为全局攻击
# 这种全局攻击模式在随阶段增强（四种） timer_attack_1 大风车半径，750（尝试）
# 七种本身具有，三种召唤出的BOSS具有

@onready var player: Player = $player
@onready var enemy: Enemy = $enemy
@onready var collision_shape_2d: CollisionShape2D = $enemy/invincible/CollisionShape2D
@onready var follow_path_component: FollowPathComponent = $FollowPathComponent
@onready var spawner_component: SpawnerComponent = $SpawnerComponent
@onready var enemy_spawner_component: SpawnerComponent = $EnemySpawnerComponent
@onready var sub_enemy_1: Node2D = $SubEnemy1 # level_2
@onready var sub_enemy_2: Node2D = $SubEnemy2 # level_1
@onready var sub_enemy_3: Node2D = $SubEnemy3 # level_0
@onready var move_component: MoveComponent = $MoveComponent


var jumping: bool = false
var flag_prase: int = 0
var tigger_health: bool = false
var path_now: float = 0.0
var timer_prase: Timer = null
var timer_attack_1: Timer = null
var timer_attack_2: Timer = null
var timer_attack_3: Timer = null
var timer_attack_4: Timer = null

func _ready() -> void:
	create_tween().tween_property(player, "global_position", Status.player_position, 0.3)
	player.tree_exited.connect(func():
		set_process(false)
		if jumping: return
		jumping = true
		await get_tree().create_timer(1.0).timeout
		var InventoryScene: PackedScene = preload("res://scene/game_over.tscn")
		Status.scene_into(InventoryScene)
		)
	enemy.tree_exited.connect(func():
		set_process(false)
		if jumping: return
		jumping = true
		await get_tree().create_timer(1.0).timeout
		var InventoryScene: PackedScene = preload("res://Levels/level_3.tscn")
		Status.scene_into(InventoryScene)
		)
	sub_enemy_1.tree_exited.connect(defeated)
	sub_enemy_2.tree_exited.connect(defeated)
	sub_enemy_3.tree_exited.connect(defeated)
	player.is_level5 = true
	
	# 全局攻击
	timer_attack_1 = Timer.new()
	add_child(timer_attack_1)
	timer_attack_1.start()
	timer_attack_1.wait_time = 16
	timer_attack_1.timeout.connect(attack_1)
	# subEnemy1的攻击
	timer_attack_2 = Timer.new()
	add_child(timer_attack_2)
	timer_attack_2.wait_time = 4
	timer_attack_2.timeout.connect(attack_2)
	# subEnemy2的攻击
	timer_attack_3 = Timer.new()
	add_child(timer_attack_3)
	timer_attack_3.wait_time = 4
	timer_attack_3.timeout.connect(attack_3)
	# subEnemy3的攻击
	timer_attack_4 = Timer.new()
	add_child(timer_attack_4)
	timer_attack_4.wait_time = 3
	timer_attack_4.timeout.connect(attack_4)

func _process(_delta: float) -> void:
	if enemy != null:
		prase_des()
	# 开发者跳关
	if Input.is_action_just_pressed("creator_jump"):
		if jumping: return
		jumping = true
		get_tree().change_scene_to_file("res://Levels/level_3.tscn")

##阶段判断
func prase_des():
	var stats: StatsComponent = enemy.get_node("StatsComponent")
	var HP: int = stats.health
	var HP_max: int = stats.health_max
	if HP > 0.75 * HP_max: flag_prase = 0
	if HP <= 0.75 * HP_max and HP > 0.5 * HP_max:
		if HP >= 0.74 * HP_max and HP <= 0.76 * HP_max and flag_prase == 0:
			enemy_invincible()
			flag_prase = 1
			# 敌人行为
			create_tween().tween_property(sub_enemy_1, "global_position", Vector2(360, 450), 0.5)
			timer_attack_2.start()
		flag_prase = 1
	if HP <= 0.5 * HP_max and HP > 0.25 * HP_max:
		if HP >= 0.49 * HP_max and HP <= 0.51 * HP_max and flag_prase == 1:
			enemy_invincible()
			flag_prase = 2
			create_tween().tween_property(sub_enemy_2, "global_position", Vector2(280, 500), 0.5)
			move_component.actor = sub_enemy_2
			await get_tree().create_timer(0.5).timeout
			move_component.amplitude = 100
			timer_attack_3.start()
		flag_prase = 2
	if HP <= 0.25 * HP_max:
		if HP >= 0.24 * HP_max and HP <= 0.26 * HP_max and flag_prase == 2:
			enemy_invincible()
			flag_prase = 3
			create_tween().tween_property(sub_enemy_3, "global_position", Vector2(360, 200), 0.5)
			move_component.actor = sub_enemy_3
			await get_tree().create_timer(0.5).timeout
			move_component.roll_r_1 = 100
			timer_attack_4.start()
		flag_prase = 3

func enemy_invincible():
	timer_attack_1.stop()
	collision_shape_2d.set_deferred("disabled", false)
	path_now = follow_path_component.stop_process()
	
func defeated() -> void:
	timer_attack_4.stop()
	timer_attack_3.stop()
	timer_attack_2.stop()
	timer_attack_1.start()
	tigger_health = false
	if collision_shape_2d == null: return #测试环境下，直接打二阶段会导致敌人和sub敌人同时消失，然后发送多次信号
	collision_shape_2d.set_deferred("disabled", true)
	follow_path_component.start_follow(path_now)

func attack_1():
	var bullet_left: Bullet = null
	var num: int = 8
	var brond_r:float = 700
	var time_ : float = 2.0
	var duan:int = 4
	var frame: int = 6
	print("全局攻击", flag_prase)
	if flag_prase == 0:
		for j in range(0,duan):
			for i in range(0,num):
				bullet_left = spawner_component.spawn(Vector2(360,640),self,0)
				bullet_left.velocity =-(brond_r/time_ - i * (brond_r/time_)/num) * Vector2.from_angle(2*PI/duan*(1+j)) 
				bullet_left.frame = frame
				bullet_left.initialize()
				bullet_left.life_timer.timeout.connect(roll_it.bind(bullet_left))
				bullet_left.life_timer.wait_time = time_
				bullet_left.life_timer.one_shot = true
				bullet_left.life_timer.start()
				
	elif  flag_prase == 1:
		duan = 6
		for j in range(0,duan):
			for i in range(0,num):
				bullet_left = spawner_component.spawn(Vector2(360,640),self,0)
				bullet_left.velocity =-(brond_r/time_ - i * (brond_r/time_)/num) * Vector2.from_angle(2*PI/duan*(1+j)) 
				bullet_left.frame = frame
				bullet_left.initialize()
				bullet_left.life_timer.timeout.connect(roll_it.bind(bullet_left))
				bullet_left.life_timer.wait_time = time_
				bullet_left.life_timer.one_shot = true
				bullet_left.life_timer.start()
	elif  flag_prase == 2:
		num = 15
		duan = 6
		for j in range(0,duan):
			for i in range(0,num):
				bullet_left = spawner_component.spawn(Vector2(360,640),self,0)
				bullet_left.velocity =-(brond_r/time_ - i * (brond_r/time_)/num) * Vector2.from_angle(2*PI/duan*(1+j)) 
				bullet_left.frame = frame
				bullet_left.initialize()
				bullet_left.life_timer.timeout.connect(roll_it.bind(bullet_left))
				bullet_left.life_timer.wait_time = time_
				bullet_left.life_timer.one_shot = true
				bullet_left.life_timer.start()
		pass
	elif  flag_prase == 3:
		num = 15
		duan = 6
		time_ = 1.0
		for j in range(0,duan):
			for i in range(0,num):
				bullet_left = spawner_component.spawn(Vector2(360,640),self,0)
				bullet_left.velocity =-(brond_r/time_ - i * (brond_r/time_)/num) * Vector2.from_angle(2*PI/duan*(1+j)) 
				bullet_left.frame = frame
				bullet_left.initialize()
				bullet_left.life_timer.timeout.connect(roll_it_1.bind(bullet_left))
				bullet_left.life_timer.wait_time = time_
				bullet_left.life_timer.one_shot = true
				bullet_left.life_timer.start()

func roll_it(bullet:Bullet):
	var roll_v: float = PI/8
	bullet.roll_origin_rad_1 =  bullet.velocity.angle()
	bullet.velocity = Vector2(0,0)
	bullet.roll_r_1 = (bullet.global_position - Vector2(360,640)).length()
	bullet.roll_vec_rad_1 = roll_v
	bullet.initialize()
	bullet.life_timer.timeout.disconnect(roll_it)
	bullet.life_timer.wait_time = 10
	bullet.life_timer.start()
	bullet.life_timer.timeout.connect(clear.bind(bullet))

func roll_it_1(bullet:Bullet):
	var roll_v: float = PI/5
	bullet.roll_origin_rad_1 =  bullet.velocity.angle()
	bullet.velocity = Vector2(0,0)
	bullet.roll_r_1 = (bullet.global_position - Vector2(360,640)).length()
	bullet.roll_vec_rad_1 = roll_v
	bullet.initialize()
	bullet.life_timer.timeout.disconnect(roll_it)
	bullet.life_timer.wait_time = 10
	bullet.life_timer.start()
	bullet.life_timer.timeout.connect(clear.bind(bullet))

# 从敌人一周围射出，然后追踪player
func attack_3() -> void:
	var unfold: Bullet # 光翼展开
	var num: int = 12 ##子弹数量
	var speed: int = 200 ##子弹速度
	var frame_bullet = 29 ##子弹样式
	for i in range(6):
		if sub_enemy_2 == null: return
		unfold = spawner_component.spawn(sub_enemy_2.global_position + Vector2(-56, i*2-8), self, 0)
		#unfold.name = "unfold" + String.num_int64(i)
		unfold.velocity = speed * Vector2.from_angle(1.25 * PI - i * PI / 16)
		unfold.frame = frame_bullet
		unfold.wait_time = randf_range(0.6, 1.2)
		unfold.one_shot = true
		unfold.life_timer.timeout.connect(asign_value.bind(unfold))
		unfold.initialize()
		unfold.life_timer.start()
		
	for i in range(6, num):
		if sub_enemy_2 == null: return
		unfold = spawner_component.spawn(sub_enemy_2.global_position + Vector2(56, i*2-8), self, 0)
		#unfold.name = "unfold" + String.num_int64(i)
		unfold.velocity = speed * Vector2.from_angle(-0.25 * PI + (i-8) * PI / 16)
		unfold.frame = frame_bullet
		unfold.wait_time = randf_range(0.6, 1.2)
		unfold.one_shot = true
		unfold.life_timer.timeout.connect(asign_value.bind(unfold))
		unfold.initialize()
		unfold.life_timer.start()

func asign_value(unfold: Bullet) -> void:
	if unfold != null:
		# print("在追踪")
		unfold.velocity = Vector2(0, 550)
		unfold.speed_trail_1 = 250
		unfold.initialize()

func attack_4():
	var luo: Bullet = null
	var rad: float = PI/4
	var num: int = 14##子弹数量
	var speed: int = 300 ##子弹速度
	var frame_bullet = 13 ##子弹样式
	for i in range(0,num):
		luo = spawner_component.spawn(Vector2(360,200),self,0)
		luo.velocity = speed * Vector2.from_angle(rad)
		rad = rad + PI/((num-1) * 2)
		# speed = speed + 10
		luo.frame = frame_bullet
		luo.wait_time = 2.0
		luo.life_timer.timeout.connect(asign_value_1.bind(luo))
		luo.initialize()
		luo.life_timer.one_shot = false
		luo.life_timer.start()

func asign_value_1(unfold: Bullet) -> void:
	var left_bullet: Bullet = null
	var right_bullet: Bullet = null
	if unfold != null:
		left_bullet = spawner_component.spawn(unfold.global_position,self,0)
		left_bullet.velocity = Vector2(250,0)
		left_bullet.frame = 4
		left_bullet.initialize()
		right_bullet = spawner_component.spawn(unfold.global_position,self,0)
		right_bullet.velocity = Vector2(-250,0)
		right_bullet.frame = 4
		right_bullet.initialize()

	
var shotgun_flag = 0
func attack_2():
	var luo: Bullet = null
	var num: int = 15##子弹数量
	var speed: int = 300 ##子弹速度
	var rad: float = 0
	var frame_bullet = 11 ##子弹样式
	for i in range(0,num):
		luo = spawner_component.spawn(sub_enemy_1.global_position, self, 0)
		luo.name = "luorui" + String.num_int64(shotgun_flag)
		shotgun_flag += 1
		luo.velocity = speed * Vector2.from_angle(rad)
		luo.frame = frame_bullet
		
		rad = rad + PI/(num-1)
		luo.initialize()
		luo.life_timer.one_shot = true
		luo.life_timer.wait_time = 3
		luo.life_timer.timeout.connect(son_luoruixin.bind(luo))
		luo.life_timer.start()

func son_luoruixin(luo):
	if luo != null:
		var bullet_luo_son1 : Bullet = spawner_component.spawn(luo.global_position,self,0)
		bullet_luo_son1.velocity = Vector2(-150,-150)
		bullet_luo_son1.frame = 12
		bullet_luo_son1.initialize()
		var bullet_luo_son2 : Bullet = spawner_component.spawn(luo.global_position,self,0)
		bullet_luo_son2.velocity = Vector2(0,-150)
		bullet_luo_son2.frame = 12
		bullet_luo_son2.initialize()
		var bullet_luo_son3 : Bullet = spawner_component.spawn(luo.global_position,self,0)
		bullet_luo_son3.velocity = Vector2(150,-150)
		bullet_luo_son3.frame = 12
		bullet_luo_son3.initialize()
		luo.queue_free()

func clear(bullet:Bullet):
	bullet.queue_free()
	pass
