extends Node2D

## 29 28 26 7 16 5 不准用了
@onready var player: Node2D = $player
@onready var enemy_1: Node2D = $enemy1
@onready var enemy_2: Node2D = $enemy2
@onready var follow_path_component: FollowPathComponent = $FollowPathComponent
@onready var follow_path_component_2: FollowPathComponent = $FollowPathComponent2
@onready var spawner_component: SpawnerComponent = $SpawnerComponent
var jumping: bool = false
var enemy1_is_dead: bool = false
var enemy2_is_dead: bool = false

var attack_method1: Timer
var attack_method2: Timer
var attack_method3: Timer
var attack_method4: Timer
var attack_method5: Timer
var attack_method6: Timer
var attack_method7: Timer

func _ready() -> void:
	# 更新玩家位置
	create_tween().tween_property(player, "global_position", Status.player_position, 0.3)
	# 初始化关卡
	player.tree_exited.connect(_on_player_exited)
	enemy_1.tree_exited.connect(_on_enemy1_exited)
	enemy_2.tree_exited.connect(_on_enemy2_exited)
	follow_path_component.start_follow()
	follow_path_component_2.start_follow()
	
	attack_method1 = Timer.new()
	attack_method1.autostart = true
	add_child(attack_method1)
	attack_method1.wait_time = 6.0
	attack_method1.timeout.connect(attack_1)
	
	attack_method2 = Timer.new()
	add_child(attack_method2)
	attack_method2.wait_time = 8.0
	attack_method2.timeout.connect(attack_2)
	attack_method2.start()
	
	attack_method3 = Timer.new()
	add_child(attack_method3)
	attack_method3.wait_time = 12.0
	attack_method3.timeout.connect(attack_3)
	attack_method3.start()
	
	attack_method4 = Timer.new()
	add_child(attack_method4)
	attack_method4.wait_time = 0.4
	attack_method4.timeout.connect(attack_4)
	
	attack_method5 = Timer.new()
	add_child(attack_method5)
	attack_method5.wait_time = 0.4
	attack_method5.timeout.connect(attack_5)

	attack_method6 = Timer.new()
	add_child(attack_method6)
	attack_method6.wait_time = 3
	attack_method6.timeout.connect(attack_6)
	
	attack_method7 = Timer.new()
	add_child(attack_method7)
	attack_method7.wait_time = 4
	attack_method7.timeout.connect(attack_7)
	

func _process(_delta: float) -> void:
	# 根据玩家位置上传敌人位置信息至全局
	if player != null:
		if enemy_1 != null or enemy_2 != null:
			if player.global_position.x < 360:
				if enemy1_is_dead:
					Status.enemy_position = enemy_2.global_position
				else:
					Status.enemy_position = enemy_1.global_position
			elif player.global_position.x >= 360:
				if enemy2_is_dead:
					Status.enemy_position = enemy_1.global_position
				else:
					Status.enemy_position = enemy_2.global_position
			else:
				print("玩家位于三界之外")
				return
	# 分阶段
	update_phase()
	# 此场景结束
	if enemy1_is_dead and enemy2_is_dead:
		set_process(false)
		if jumping: return
		jumping = true
		await get_tree().create_timer(1.0).timeout
		var InventoryScene: PackedScene = preload("res://Levels/level_4.tscn")
		Status.scene_into(InventoryScene)
	
	# 开发者跳关
	if Input.is_action_just_pressed("creator_jump"):
		#var jumping: bool = false
		jumping = true
		get_tree().change_scene_to_file("res://Levels/level_4.tscn")

func _on_player_exited() -> void:
	set_process(false)
	if jumping: return
	jumping = true
	await get_tree().create_timer(1.0).timeout
	var InventoryScene: PackedScene = preload("res://scene/game_over.tscn")
	Status.scene_into(InventoryScene)

func _on_enemy1_exited() -> void:
	attack_method3.stop() # 停止攻击
	attack_method6.stop() # 停止攻击
	enemy1_is_dead = true

func _on_enemy2_exited() -> void:
	attack_method2.stop() # 停止攻击
	attack_method7.stop()
	enemy2_is_dead = true

func update_phase() -> void:
	var stat1: StatsComponent
	var stat2: StatsComponent
	if enemy_1 != null:
		stat1 = enemy_1.get_node("StatsComponent")
	if enemy_2 != null:
		stat2 = enemy_2.get_node("StatsComponent")
	## 半血以下出现攻击模式4和5
	## 另一个半血，自己出现二阶段弹幕
	if stat1 != null:
		if stat1.health < stat1.health_max / 2 and attack_method5.is_stopped():
			attack_method5.start()
			attack_method7.start()
	if stat2 != null:
		if stat2.health < stat2.health_max / 2 and attack_method4.is_stopped():
			attack_method4.start()
			attack_method6.start()
	
	
# 全局下攻击
func attack_1() -> void:
	var line_down: Bullet # 一排竖着随机水平位置往下落
	var num: int = 8 ##子弹数量
	var speed: int = 150 ##子弹速度
	var frame_bullet = 5 ##子弹样式
	for i in range(0,num):
		line_down = spawner_component.spawn(Vector2(25 + i * round(720 / num) +randi_range(20,50) , -50 + randi_range(-50,50) ),self,0)
		line_down.frame = frame_bullet
		line_down.velocity = Vector2(0,speed)
		line_down.initialize()

# 敌人二的攻击
func attack_2() -> void:
	if enemy2_is_dead: return
	var direct_follow: Bullet # 瞬间跟踪并很快的往玩家身上射
	var num: int = 40 ##子弹数量
	var speed: int = 600 ##子弹速度
	var frame_bullet = 16 ##子弹样式
	for i in range(0,num):
		var offset: Vector2 = Vector2(randi_range(-4,4), randi_range(-4,4))
		if enemy_2 == null: return
		direct_follow = spawner_component .spawn(enemy_2.global_position + Vector2(0 ,48) + offset, self, 0)
		direct_follow.frame = frame_bullet
		direct_follow.speed_trail_2 = speed
		direct_follow.initialize()
		await get_tree().create_timer(0.05).timeout

# 敌人一的攻击
func attack_3() -> void:
	if enemy1_is_dead: return
	var scatter: Bullet # 散射
	var num: int = 15 ##子弹数量
	var speed: int = 250 ##子弹速度
	var frame_bullet = 7 ##子弹样式
	for i in range(0,num):
		if enemy_1 == null: return
		scatter = spawner_component.spawn(enemy_1.global_position + Vector2(0, 48), self, 0)
		scatter.frame = frame_bullet
		scatter.velocity = speed * Vector2(sin(i), abs(cos(i)))
		scatter.initialize()

# 全局生成两条相交的直线
func attack_4() -> void:
	var line: Bullet # 只是直线
	var speed: int = 200 ##子弹速度
	var frame_bullet = 28 ##子弹样式
	line = spawner_component.spawn(Vector2(360, 0), self, 0)
	line.frame = frame_bullet
	line.velocity = speed * Vector2(0, 1)
	line.initialize()
	
	line = spawner_component.spawn(Vector2(0, 640), self, 0)
	line.frame = frame_bullet
	line.velocity = speed * Vector2(1, 0)
	line.initialize()

func attack_5() -> void:
	var line: Bullet # 只是直线
	var speed: int = 200 ##子弹速度
	var frame_bullet = 28 ##子弹样式
	line = spawner_component.spawn(Vector2(0, 280), self, 0)
	line.frame = frame_bullet
	line.velocity = speed * Vector2(540, 1000).normalized()
	line.initialize()
	
	line = spawner_component.spawn(Vector2(720, 280), self, 0)
	line.frame = frame_bullet
	line.velocity = speed * Vector2(-540, 1000).normalized()
	line.initialize()

# 从敌人一周围射出，然后追踪player
func attack_6() -> void:
	if enemy1_is_dead: return
	var unfold: Bullet # 光翼展开
	var num: int = 12 ##子弹数量
	var speed: int = 200 ##子弹速度
	var frame_bullet = 29 ##子弹样式
	for i in range(6):
		if enemy_1 == null: return
		unfold = spawner_component.spawn(enemy_1.global_position + Vector2(-56, i*2-8), self, 0)
		#unfold.name = "unfold" + String.num_int64(i)
		unfold.velocity = speed * Vector2.from_angle(1.25 * PI - i * PI / 16)
		unfold.frame = frame_bullet
		unfold.wait_time = randf_range(0.6, 1.2)
		unfold.one_shot = true
		unfold.life_timer.timeout.connect(asign_value.bind(unfold))
		unfold.initialize()
		unfold.life_timer.start()
		
	for i in range(6, num):
		if enemy_1 == null: return
		unfold = spawner_component.spawn(enemy_1.global_position + Vector2(56, i*2-8), self, 0)
		#unfold.name = "unfold" + String.num_int64(i)
		unfold.velocity = speed * Vector2.from_angle(-0.25 * PI + (i-8) * PI / 16)
		unfold.frame = frame_bullet
		unfold.wait_time = randf_range(0.6, 1.2)
		unfold.one_shot = true
		unfold.life_timer.timeout.connect(asign_value.bind(unfold))
		unfold.initialize()
		unfold.life_timer.start()

## 为attack_6的第二阶段准备的
func asign_value(unfold: Bullet) -> void:
	if unfold != null:
		# print("在追踪")
		unfold.velocity = Vector2(0, 550)
		unfold.speed_trail_1 = 250
		unfold.initialize()

# 缓慢的摇摆弹幕
func attack_7() -> void:
	if enemy2_is_dead: return
	var trigogo: Bullet # 三角函数弹幕
	var num: int = 12 ##子弹数量
	var speed: int = 100 ##子弹速度
	var frame_bullet = 26 ##子弹样式
	for i in range(num):
		if enemy_2 == null: return
		trigogo = spawner_component.spawn(enemy_2.global_position + Vector2(0, 52), self, 0)
		trigogo.velocity = speed * Vector2(0, 1)
		trigogo.amplitude = 50 + 5*i
		trigogo.angle_radians = randf_range(-15.0, 15.0)
		trigogo.frame = frame_bullet
		trigogo.initialize()
