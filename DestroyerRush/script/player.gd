extends Node2D
class_name Player

# 首先把所有子节点搬过来
@onready var stats_component: StatsComponent = $StatsComponent
@onready var player_manage_component: PlayerManageComponent = $PlayerManageComponent
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var move_component: MoveComponent = $MoveComponent
@onready var move_input_component: MoveInputComponent = $MoveInputComponent
@onready var position_clamp_component: PositionClampComponent = $PositionClampComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var graze_area: Area2D = $GrazeArea
@onready var edge_ball: EdgeBall = $EdgeBall
@onready var spawn_points: Node2D = $SpawnPoints
@onready var bullet_spawner_component: SpawnerComponent = $BulletSpawnerComponent
@onready var destroy_effect_spawner_component_2: SpawnerComponent = $DestroyEffectSpawnerComponent2
@onready var frame_animated_sprite_2d: AnimatedSprite2D = $FrameAnimatedSprite2D
@onready var shake_component: ShakeComponent = $ShakeComponent
@onready var audio_stream_player_2d: AudioStreamPlayer = $AudioStreamPlayer2D

# 翻滚计时器
var roll_timer: Timer = null
var trail_timer: Timer = null
var shake_timer: Timer = null
# var is_double_click: bool = false
@export_range(0, 4) var play_looklike: int = 0 ## 选择玩家皮肤
@export var roll_wait_time: float = 2

var is_level5: bool = false

func _ready():
	# 发射第一类子弹
	var fire_timer1: Timer = Timer.new() # 创建一个计时器节点
	add_child(fire_timer1)
	fire_timer1.wait_time = 0.1
	fire_timer1.autostart = true
	fire_timer1.name = "FireDelay"
	# 启动计时器
	fire_timer1.start()
	fire_timer1.timeout.connect(fire_bullet1)
	# 翻滚等待CD的计时器
	roll_timer = Timer.new()
	add_child(roll_timer)
	roll_timer.autostart = true
	roll_timer.wait_time = roll_wait_time
	roll_timer.start()
	roll_timer.timeout.connect(func():
		move_input_component.roll_enable = true
		)
	# 翻滚时的残影计时器
	trail_timer = Timer.new()
	add_child(trail_timer)
	trail_timer.name = "TrailTimer"
	trail_timer.wait_time = 0.1
	# trail_timer.autostart = true
	trail_timer.timeout.connect(start_trail)
	## 手柄震动计时器
	#shake_timer = Timer.new()
	#add_child(shake_timer)
	#shake_timer.name = "ShakeTimer"
	#shake_timer.one_shot = true
	#shake_timer.wait_time = 0.5
	## shake_timer.timeout.connect()

func fire_bullet1() -> void:
	audio_stream_player_2d.play(0.1)
	var l1: Marker2D = spawn_points.get_node("left_1")
	var node1 = bullet_spawner_component.spawn(l1.global_position)
	node1.get_node("MoveComponent").roll_r_1 = 10
	node1.get_node("MoveComponent").roll_vec_rad_1 = 2*PI
	node1.get_node("MoveComponent").roll_origin_rad_1 =PI
	var r1: Marker2D = spawn_points.get_node("right_1")
	var node2 = bullet_spawner_component.spawn(r1.global_position)
	node2.get_node("MoveComponent").roll_r_1 = 10
	node2.get_node("MoveComponent").roll_vec_rad_1 = -2*PI
	node2.get_node("MoveComponent").roll_origin_rad_1 = 0
	if is_level5:
		var center: Marker2D = spawn_points.get_node("center")
		var node3 = bullet_spawner_component.spawn(center.global_position)
	
func _process(_delta):
	# 改变移动动画
	animate_the_ship()
	# 传递 位置 和 位移向量 信息同步至全局‘
	# 只同步了 普通移动 的位移向量，没有 翻滚 的位移向量
	Status.player_position = position
	Status.player_velocity = move_component.velocity + move_component.roll_velocity
	Status.player_health = stats_component.health
	
	#audio_stream_player_2d.position = position
	
func animate_the_ship() -> void:
	if move_component.velocity.x < 0:
		sprite_2d.frame_coords = Vector2(0, play_looklike)
		frame_animated_sprite_2d.play("left")
	elif move_component.velocity.x > 0:
		sprite_2d.frame_coords = Vector2(2, play_looklike)
		frame_animated_sprite_2d.play("right")
	else:
		sprite_2d.frame_coords = Vector2(1, play_looklike)
		frame_animated_sprite_2d.play("centre")

## 试图实现双击翻滚
#func double_click_roll() -> void:
	#pass

func start_trail() -> void:
	if move_component.sum_velocity == Vector2():
		return
	
	var trail = preload("res://scene/trail.tscn").instantiate()
	get_parent().add_child(trail)
	get_parent().move_child(trail, get_index())
	var animate_trail = preload("res://scene/animate_trail.tscn").instantiate()
	get_parent().add_child(animate_trail)
	get_parent().move_child(animate_trail, get_index())
	
	var properties = [
		"hframes",
		"vframes",
		"frame",
		"texture",
		"global_position",
		"filp_h"
	]
	var anime_properties = [
		"sprite_frames",
		"animation",
		"frame",
		"speed_scale",
		"global_position"
	]
	
	for name_prop in properties:
		trail.set(name_prop, sprite_2d.get(name_prop))
	trail.set("scale", self.scale) # player的根节点放大了，所以这里也要放大
	for name_prop1 in anime_properties:
		animate_trail.set(name_prop1, frame_animated_sprite_2d.get(name_prop1))
	animate_trail.set("scale", self.scale) # player的根节点放大了，所以这里也要放大

# 在翻滚时留下残影，并取消玩家碰撞检测
func _on_move_input_component_roll_start() -> void:
	trail_timer.start()
	hurtbox_component.monitorable = false
func _on_move_input_component_roll_finish() -> void:
	trail_timer.stop()
	hurtbox_component.monitorable = true
