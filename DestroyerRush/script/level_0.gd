extends Node2D
# 游戏主循环
# 将游戏的一切在此管理
## attack7中的代码后半部分是散射的部分
@onready var killzone: HurtboxComponent = $killzone
@onready var player: Node2D = $player
@onready var enemy: Node2D = $enemy
@onready var spawner_component: SpawnerComponent = $SpawnerComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jumping: bool = false

var time_all: Timer = null
var timer_2: Timer = null
var timer: Timer = null
var timer_prase: Timer = null
var timer_attack_7: Timer = null

var shotgun_flag: int = 0 #散弹数量标记
## signal signal_prase_flag
var prase_flag = 0

func _ready() -> void:
	# create_tween().tween_property(player, "global_position", Status.player_position, 0.3)
	##关于计时器
	timer = Timer.new()
	timer_2 = Timer.new()
	time_all = Timer.new()
	timer_prase = Timer.new()
	timer_attack_7 = Timer.new()
	
	add_child(timer)
	add_child(timer_2)
	add_child(time_all)
	add_child(timer_prase)
	add_child(timer_attack_7)
	
	time_all.start()
	timer.start()
	timer_prase.start()
	timer_attack_7.start()
	##关于计时器的初始话
	time_all.wait_time = 0.5
	timer.wait_time = 4
	timer_2.wait_time = 0.5
	timer_prase.wait_time = 3
	timer_attack_7.wait_time = 3
	
	timer.autostart = true
	timer_2.autostart = true
	time_all.autostart = true
	timer_prase.autostart = true
	timer_attack_7.autostart = true
	
	timer.one_shot = false
	timer_2.one_shot = true
	time_all.one_shot = false
	timer_prase.one_shot = false
	timer_attack_7.one_shot = false
	
	##将不同的计时,带入不同的函数
	time_all.timeout.connect(luoruixin_time_all)
	timer.timeout.connect(luoruixin)
	timer_2.timeout.connect(son_luoruixin)
	timer_prase.timeout.connect(attack_6)
	timer_prase.timeout.connect(attack_7)
	
	
	player.tree_exited.connect(func():
		if jumping: return
		jumping = true
		await get_tree().create_timer(1.0).timeout
		var InventoryScene: PackedScene = preload("res://scene/game_over.tscn")
		Status.scene_into(InventoryScene)
		)
	enemy.tree_exited.connect(func():
		if jumping: return
		jumping = true
		await get_tree().create_timer(1.0).timeout
		var InventoryScene: PackedScene = preload("res://Levels/level_5.tscn")
		Status.scene_into(InventoryScene)
		)

func _process(_delta: float) -> void:
	# 玩家跳关
	if Input.is_action_just_pressed("jump_next_level") and Status.times_win_level4 > 1:
		jumping = true
		get_tree().change_scene_to_file("res://Levels/level_5.tscn")
	# 开发者跳关
	if Input.is_action_just_pressed("creator_jump"):
		jumping = true
		get_tree().change_scene_to_file("res://Levels/level_5.tscn")
	
func luoruixin_time_all() :
	var flag:int = randi_range(0,2)#randi_range(0,5) + prase_flag
	#var flag:int = 8#randi_range(0,7)
	#var flag_i: int = randf_range(8,18)
	var luo: Bullet = null
	if flag == 0 or flag == 1:
		var num: int = 45 ##子弹数量
		var speed: int = 375 ##子弹速度
		var frame_bullet =3 ##子弹样式
		var roll_r_range: int = 100+randi_range(-50,50)
		for i in range(0,num/2):
			luo = spawner_component.spawn(Vector2( round(i * 720.0 / num)  , 300  ),self,0)
			luo.frame = frame_bullet
			luo.velocity = Vector2(0,speed)
			luo.roll_origin_rad_1 = -PI/2
			luo.roll_r_1 = roll_r_range
			luo.initialize()
		for i in range(0,num/2):
			luo = spawner_component.spawn(Vector2(720 - round(i * 720.0 / num)  , 300  ),self,0)
			#print(round(i * 720.0 / num))
			luo.frame = frame_bullet
			luo.velocity = Vector2(0,speed)
			luo.roll_vec_rad_1 = PI
			luo.roll_origin_rad_1 = -PI/2
			luo.roll_r_1 = roll_r_range
			luo.initialize()
			#print(Vector2( 30+ i * round(720 / num) +randi_range(-20,20) , 200 + randi_range(-50,50) ))

			
	if flag == 2:##霰弹尝试
		var num: int = 15##子弹数量
		var speed: int = 500 ##子弹速度
		var rad: float = 0
		var frame_bullet = flag+5 ##子弹样式
		for i in range(0,num):
			luo = spawner_component.spawn(Status.enemy_position,self,0)
			luo.name = "luorui" + String.num_int64(shotgun_flag)
			shotgun_flag += 1
			luo.velocity = speed * Vector2.from_angle(rad)
			luo.frame = frame_bullet
			rad = rad + PI/(num-1)
			luo.initialize()
			luo.life_timer.one_shot = true
			luo.life_timer.wait_time = 1.7
			luo.life_timer.timeout.connect(son_luoruixin_1.bind(luo))
			luo.life_timer.start()

func luoruixin():
	var num: int = 20 ##子弹数量
	var speed: int = randi_range(190,210) ##子弹速度
	var frame_bullet = 20 ##子弹样式
	var random_h: int = randi_range(-50,50)
	var luo: Bullet = null
	var luo_1: Bullet = null
	for i in range(0,num):
		luo = spawner_component.spawn(Vector2(round(i * 280 / num) , 200 ),self,0)
		luo.velocity = Vector2(speed,0)
		luo.speed_trail_2 = 500
		luo.speed_trail_1 = 500
		luo.roll_r_1 = 3
		luo.roll_origin_rad_1 = PI/2
		luo.frame = frame_bullet
		luo.initialize()
		luo_1 = spawner_component.spawn(Vector2(round(720 - 280 +(num- i) * 280 / num) , 200 ),self,0)
		luo_1.velocity = Vector2(-speed,0)
		luo_1.speed_trail_2 = 500
		luo_1.speed_trail_1 = 500
		luo_1.roll_r_1 = 3
		luo_1.roll_origin_rad_1 = PI/2
		luo_1.frame = frame_bullet
		luo_1.initialize()
		#print(luo_1.move_component.trail_stright_v_1)
		await get_tree().create_timer(0.05).timeout
		#await get_tree().create_timer(0.05).timeout
	
func son_luoruixin():
	var luo: Bullet
	for i in range(0,10):
		luo=get_node("luorui"+String.num_int64(shotgun_flag - i) );
		if luo != null:
			var bullet_luo_son1 : Bullet = spawner_component.spawn(luo.global_position,self,0)
			bullet_luo_son1.velocity = Vector2(-50,-50)
			bullet_luo_son1.frame = 12
			bullet_luo_son1.initialize()
			var bullet_luo_son2 : Bullet = spawner_component.spawn(luo.global_position,self,0)
			bullet_luo_son2.velocity = Vector2(0,-50)
			bullet_luo_son2.frame = 12
			bullet_luo_son2.initialize()
			var bullet_luo_son3 : Bullet = spawner_component.spawn(luo.global_position,self,0)
			bullet_luo_son3.velocity = Vector2(50,-50)
			bullet_luo_son3.frame = 12
			bullet_luo_son3.initialize()
			luo.queue_free()
			
# 从敌人一周围射出，然后追踪player
func attack_6() -> void:
	var unfold: Bullet # 光翼展开
	var num: int = 12 ##子弹数量
	var speed: int = 200 ##子弹速度
	var frame_bullet = 29 ##子弹样式
	for i in range(6):
		unfold = spawner_component.spawn(Vector2(240,200) + Vector2(0, i*2-8), self, 0)
		#unfold.name = "unfold" + String.num_int64(i)
		unfold.velocity = speed * Vector2.from_angle(1.25 * PI - i * PI / 16)
		unfold.frame = frame_bullet
		unfold.wait_time = 0.8
		unfold.one_shot = true
		unfold.life_timer.timeout.connect(asign_value.bind(unfold))
		unfold.initialize()
		unfold.life_timer.start()
		
	for i in range(6, num):
		unfold = spawner_component.spawn(Vector2(480,200) + Vector2(0, i*2-8), self, 0)
		#unfold.name = "unfold" + String.num_int64(i)
		unfold.velocity = speed * Vector2.from_angle(-0.25 * PI + (i-6) * PI / 16)
		unfold.frame = frame_bullet
		unfold.wait_time = 0.8
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


func attack_7():
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

func son_luoruixin_1(luo):
	#var luo: Bullet
	#for i in range(0,10):
	#luo=get_node("luorui"+String.num_int64(shotgun_flag - 10) );
	if luo != null:
		var bullet_luo_son1 : Bullet = spawner_component.spawn(luo.global_position,self,0)
		bullet_luo_son1.velocity = Vector2(-50,-50)
		bullet_luo_son1.frame = 12
		bullet_luo_son1.initialize()
		var bullet_luo_son2 : Bullet = spawner_component.spawn(luo.global_position,self,0)
		bullet_luo_son2.velocity = Vector2(0,-50)
		bullet_luo_son2.frame = 12
		bullet_luo_son2.initialize()
		var bullet_luo_son3 : Bullet = spawner_component.spawn(luo.global_position,self,0)
		bullet_luo_son3.velocity = Vector2(50,-50)
		bullet_luo_son3.frame = 12
		bullet_luo_son3.initialize()
		luo.queue_free()
