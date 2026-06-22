extends Node2D
## luoruixin_time_all 中的 if flag == 8
@onready var spawner_component: SpawnerComponent = $SpawnerComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var player: Node2D = $player
@onready var enemy: Node2D = $enemy
@onready var bomm_sprite_2d: AnimatedSprite2D = $enemy/bommSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var jumping: bool = false
var time_all: Timer = null
var timer_2: Timer = null
var timer: Timer = null
var timer_prase: Timer = null
var shotgun_flag: int = 0 #散弹数量标记
## signal signal_prase_flag
var prase_flag = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	##关于计时器
	timer = Timer.new()
	timer_2 = Timer.new()
	time_all = Timer.new()##控制弹幕生产的计时器
	timer_prase = Timer.new()
	add_child(timer)
	add_child(timer_2)
	add_child(time_all)
	add_child(timer_prase)
	time_all.start()
	timer.start()
	timer_prase.start()
	
	##关于计时器的初始话
	time_all.wait_time = 2.0##弹幕生产
	timer.wait_time = 10.0
	timer_2.wait_time = 3.0
	timer_prase.wait_time = 1.0
	
	timer.autostart = true
	timer_2.autostart = true
	time_all.autostart = true
	timer_prase.autostart = true
	
	timer.one_shot = false
	timer_2.one_shot = true
	time_all.one_shot = false
	timer_prase.one_shot = false
	
	##将不同的计时,带入不同的函数
	time_all.timeout.connect(luoruixin_time_all)##生产弹幕的函数
	timer.timeout.connect(luoruixin)
	timer_2.timeout.connect(son_luoruixin)
	timer_prase.timeout.connect(prase_des)
	
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
		var InventoryScene: PackedScene = preload("res://Levels/level_1.tscn")
		Status.scene_into(InventoryScene)
		)

func _process(_delta: float) -> void:
	# 开发者跳关
	if Input.is_action_just_pressed("creator_jump"):
		jumping = true
		get_tree().change_scene_to_file("res://Levels/level_1.tscn")
	
func luoruixin_time_all() :
	var flag:int =randi_range(0,5) + prase_flag
	#var flag:int = 8#randi_range(0,7)
	#var flag_i: int = randf_range(8,18)
	var luo: Bullet = null
	if flag == 0:##生产弹幕，每一个flag都对应一个弹幕类型，一整排向下
		var num: int = 10 ##子弹数量
		var speed: int = 350 ##子弹速度
		var frame_bullet = flag+5 ##子弹样式
		for i in range(0,num):
			luo = spawner_component.spawn(Vector2(i * round(720 / num)  , 260 + randi_range(-50,50) ),self,0)
			luo.frame = frame_bullet
			luo.velocity = Vector2(0,speed)
			luo.initialize()
	if flag == 1: ##一整排向下，但是高度不一定等
		var num: int = 10 ##子弹数量
		var speed: int = 350 ##子弹速度
		var frame_bullet = flag+5 ##子弹样式
		var random_h: int = randi_range(-50,50)
		for i in range(0,num):
			luo = spawner_component.spawn(Vector2(30 + i * round(720 / num)+randi_range(20,50) , 200 + random_h),self,0)
			luo.velocity = Vector2(0,speed)
			luo.frame = frame_bullet
			luo.initialize()
	if flag == 2:
		var num: int = 10 ##子弹数量
		var speed: int = 450 ##子弹速度
		var frame_bullet = flag+5 ##子弹样式
		var random_h: int = randi_range(-50,50)
		for i in range(0,num):
			luo = spawner_component.spawn(Vector2(30 + i * round(720 / num)+randi_range(20,50) , 200 + random_h ),self,0)
			luo.velocity = Vector2(0,speed + 10 * i)
			luo.frame = frame_bullet
			luo.initialize()
	if flag == 3:
		var num: int = 10 ##子弹数量
		var speed: int = 250 ##子弹速度
		var frame_bullet = flag+5 ##子弹样式
		var random_h: int = randi_range(-50,50)
		for i in range(0,num):
			luo = spawner_component.spawn(Vector2(30 + i * round(720 / num)+randi_range(20,50)  , 200 + random_h ),self,0)
			luo.velocity = Vector2(0,speed)
			luo.roll_r_1 = 50
			luo.frame = frame_bullet
			luo.initialize()
	if flag == 4:
		var num: int = 12 ##子弹数量
		var speed: int = 450 ##子弹速度
		var frame_bullet = flag+5 ##子弹样式
		var random_h: int = randi_range(-50,50)
		for i in range(0,num):
			luo = spawner_component.spawn(Vector2(30 + i * round(720 / num) +randi_range(20,50), 200 + random_h),self,0)
			luo.velocity = Vector2(0,speed)
			luo.frame = frame_bullet
			luo.initialize()
			if randi_range( 0 , 10 ) > 8:
				luo.queue_free()
	if flag == 5:##圆型子弹需要控制删除，因为他们不和边界接触
		var luo_roll_trail_right: Bullet = null
		var luo_roll_trail_left: Bullet = null
		luo_roll_trail_right = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_right.roll_vec_rad_2 = PI
		luo_roll_trail_right.frame = 10
		luo_roll_trail_right.initialize()
		luo_roll_trail_left = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_left.roll_vec_rad_2 = -PI
		luo_roll_trail_left.frame = 10
		luo_roll_trail_left.initialize()
		await get_tree().create_timer(5).timeout
		
		if luo_roll_trail_right!=null:
				luo_roll_trail_right.queue_free()
		if luo_roll_trail_left!=null:
			luo_roll_trail_left.queue_free()
	if flag == 6:
		#for i in range(0,5):
		var luo_roll_trail_right: Bullet = null
		var luo_roll_trail_left: Bullet = null
		var luo_roll_trail_right_1: Bullet = null
		var luo_roll_trail_left_1: Bullet = null
		var luo_roll_trail_right_2: Bullet = null
		var luo_roll_trail_left_2: Bullet = null
		var luo_roll_trail_right_3: Bullet = null
		var luo_roll_trail_left_3: Bullet = null
		var luo_roll_trail_right_4: Bullet = null
		var luo_roll_trail_left_4: Bullet = null
		var jiange: float = 0.4
		var frame: int = 10
		var speed: float = PI/2
		##生成节点
		await get_tree().create_timer(jiange).timeout
		luo_roll_trail_right = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_right.roll_vec_rad_2 = speed
		luo_roll_trail_right.frame = frame
		luo_roll_trail_right.initialize()
		luo_roll_trail_left = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_left.roll_vec_rad_2 = -speed
		luo_roll_trail_left.frame = frame
		
		luo_roll_trail_left.initialize()
		await get_tree().create_timer(jiange).timeout
		luo_roll_trail_right_1 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_right_1.roll_vec_rad_2 = speed
		luo_roll_trail_right_1.frame = frame
		luo_roll_trail_right_1.initialize()
		luo_roll_trail_left_1 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_left_1.roll_vec_rad_2 = -speed
		luo_roll_trail_left_1.frame = frame
		luo_roll_trail_left_1.initialize()
		await get_tree().create_timer(jiange).timeout
		luo_roll_trail_right_2 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_right_2.roll_vec_rad_2 = speed
		luo_roll_trail_right_2.frame = frame
		luo_roll_trail_right_2.initialize()
		luo_roll_trail_left_2 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_left_2.roll_vec_rad_2 = -speed
		luo_roll_trail_left_2.frame = frame
		luo_roll_trail_left_2.initialize()
		await get_tree().create_timer(jiange).timeout
		luo_roll_trail_right_3 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_right_3.roll_vec_rad_2 = speed
		luo_roll_trail_right_3.frame = frame
		luo_roll_trail_right_3.initialize()
		luo_roll_trail_left_3 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_left_3.roll_vec_rad_2 = -speed
		luo_roll_trail_left_3.frame = frame
		luo_roll_trail_left_3.initialize()
		await get_tree().create_timer(jiange).timeout
		luo_roll_trail_right_4 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_right_4.roll_vec_rad_2 = speed
		luo_roll_trail_right_4.frame = frame
		luo_roll_trail_right_4.initialize()
		luo_roll_trail_left_4 = spawner_component.spawn(Status.enemy_position,self,0)
		luo_roll_trail_left_4.roll_vec_rad_2 = -speed
		luo_roll_trail_left_4.frame = frame
		luo_roll_trail_left_4.initialize()
		
		
		##删除节点
		await get_tree().create_timer(5).timeout
		if luo_roll_trail_right!=null:
			luo_roll_trail_right.queue_free()
		if luo_roll_trail_left!=null:
			luo_roll_trail_left.queue_free()
		await get_tree().create_timer(0.1).timeout
		if luo_roll_trail_right_1!=null:
			luo_roll_trail_right_1.queue_free()
		if luo_roll_trail_left_1!=null:
			luo_roll_trail_left_1.queue_free()
		await get_tree().create_timer(0.1).timeout
		if luo_roll_trail_right_2!=null:
			luo_roll_trail_right_2.queue_free()
		if luo_roll_trail_left_2!=null:
			luo_roll_trail_left_2.queue_free()
		await get_tree().create_timer(0.1).timeout
		if luo_roll_trail_right_3!=null:
			luo_roll_trail_right_3.queue_free()
		if luo_roll_trail_left_3!=null:
			luo_roll_trail_left_3.queue_free()
		await get_tree().create_timer(0.1).timeout
		if luo_roll_trail_right_4!=null:
			luo_roll_trail_right_4.queue_free()
		if luo_roll_trail_left_4!=null:
			luo_roll_trail_left_4.queue_free()
	if flag == 7:
		var rad: float = 0
		var num: int = 20##子弹数量
		var speed: int = 400 ##子弹速度
		var frame_bullet = flag+5 ##子弹样式
		for i in range(0,num):
			luo = spawner_component.spawn(Status.enemy_position,self,0)
			luo.velocity = speed * Vector2.from_angle(rad)
			rad = rad + PI/(num-1)
			luo.frame = frame_bullet
			luo.initialize()
	if flag == 8:##霰弹尝试
		var num: int = 15##子弹数量
		var speed: int = 300 ##子弹速度
		var rad: float = 0
		var frame_bullet = 11 ##子弹样式
		for i in range(0,num):
			luo = spawner_component.spawn(Status.enemy_position,self,0)
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
		#timer_2.start()

func luoruixin():
	if move_component != null:
		move_component.roll_vec_rad_1 = - move_component.roll_vec_rad_1
	else:
		return
	
func son_luoruixin(luo):
	#var luo: Bullet
	#for i in range(0,10):
	#luo=get_node("luorui"+String.num_int64(shotgun_flag - 10) );
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
			
			
func prase_des():
	if enemy !=null:
		if enemy.get_node("StatsComponent").health < enemy.enemy_health_max / 2 :
			prase_flag = 4
			time_all.wait_time = 2
			bomm_sprite_2d.play("boom")
			animation_player.play("big_small")
			
		#else : ##如果有血量恢复添加代码
			#prase_flag = 0
			#time_all.wait_time = 2
