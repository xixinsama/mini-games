extends Node2D


@onready var spawner_component: SpawnerComponent = $SpawnerComponent
@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var progress_bar: ProgressBar = $ProgressBar

var jumping: bool = false
var dot_matrix_file: String = "res://asset/dot_matrix_info.txt"
var dot_positions = []
var current_frame: int = 1
var node_2: Bullet = null

func _ready():
	var file = FileAccess.open(dot_matrix_file, FileAccess.READ)
	if file.is_open():
		while not file.eof_reached():
			var line = file.get_line()
			if line.begins_with("Frame"):
				current_frame = int(line.replace("Frame ", ""))
				dot_positions.append([])
			elif line != "":
				var data = line.split(": ")
				var dot_position = data[0].replace("(", "").replace(")", "").split(", ")
				var x = int(dot_position[0])
				var y = int(dot_position[1])
				var rgba = data[1].split(" ")
				var r = int(rgba[0])
				var g = int(rgba[1])
				var b = int(rgba[2])
				var a = int(rgba[3])
				dot_positions[-1].append({"x": x, "y": y, "color": Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0)})
		file.close()
	# 播放计时
	var play_gif: Timer = Timer.new()
	add_child(play_gif)
	play_gif.wait_time = 0.1
	play_gif.timeout.connect(play_gif_frame)
	#play_gif.one_shot = true
	play_gif.start()
	current_frame = 0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("skill") or Input.is_action_just_pressed("roll"):
		if jumping: return
		jumping = true
		var InventoryScene: PackedScene = load("res://scene/menu.tscn")
		print(InventoryScene)
		await get_tree().create_timer(3.0).timeout
		Status.scene_into(InventoryScene)

# 按帧生成
func play_gif_frame() -> void:
	if current_frame < len(dot_positions):
		#node_2 = spawner_component.spawn(Vector2(0,0), self, 0)
		if current_frame == 0:
			for dot in dot_positions[current_frame]:
				spawn_bullet(dot)
		else :
			for dot in dot_positions[current_frame]:
				clear(dot)
		current_frame += 1
	else:
		current_frame = 1

# 生成弹幕
func spawn_bullet(dot) -> void:
	var bullet_position: Vector2 = Vector2(720-dot["x"] * 16, dot["y"] * 16)
	var speed: int = 190
	#var time_wait: float = 0.1
	var bullet_hint: Bullet = spawner_component.spawn(bullet_position , self, 0)
	bullet_hint.name = "bullet_hint" + String.num_int64(dot["x"]).pad_zeros(3) + String.num_int64(dot["y"]).pad_zeros(3)
	bullet_hint.frame = 0
	bullet_hint.modulate = dot["color"]
	# bullet_hint.velocity = Vector2(0, speed)
	bullet_hint.trail_who = 3
	bullet_hint.trail_pos = Vector2(360, 640)
	bullet_hint.life_timer.wait_time = 2.0
	bullet_hint.life_timer.timeout.connect(trail_it.bind(bullet_hint))
	bullet_hint.life_timer.one_shot = true
	bullet_hint.life_timer.start()
	bullet_hint.initialize()
	

func clear(dot):
	node_2 = get_node_or_null("bullet_hint" + String.num_int64(dot["x"]).pad_zeros(3) + String.num_int64(dot["y"]).pad_zeros(3))
	if node_2 != null:
		node_2.modulate = dot["color"]
	pass

func  trail_it(bullet_hint: Bullet):
	bullet_hint.speed_trail_2 = 300
	bullet_hint.initialize()
