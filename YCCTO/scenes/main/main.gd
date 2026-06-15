extends Node2D

## UI
@onready var time_label: Label = $UI/Control/TimeLabel
@onready var restart_button: Button = $UI/Control/RestartButton
@onready var draw_portal_line: DrawPortalLine = $DrawPortalLine

@onready var under: TileMapLayer = $Under
@onready var spawner_component: SpawnerComponent = $SpawnerComponent
@onready var hero: Node2D = $Hero
@onready var cover: TileMapLayer = $Cover
@onready var dragable_camera: DragableCamera = $DragableCamera

# ---------------------- 游戏配置 ----------------------
const MAP_WIDTH = 80
const MAP_HEIGHT = 45

@export var rule_1: bool = true ## 0-3数字规则，将去除传送门和怪，即0-1
@export var rule_2: bool = true ## 计算规则，将不进行四个的计算

@export var initial_time: float = 60.0
# 导出变量，方便你在编辑器属性面板里调整
@export_group("Map Generation")
@export var monster_count: int = 180        # 怪兽(2)的数量
@export var portal_pairs: int = 36          # 传送门(3)的对数 (5对=10个)

@export_range(0, 10, 1) var waypoints: int = 5 ## 途径点
@export_range(0.0, 1.0) var random_trace: float = 0.6 ## 游走趋势，越大越向着终点游走，越小越随机
@export_range(0.0, 1.0) var openness: float = 0.5 ## 开阔度：0为单一直路，1为全地图铺满路

# ---------------------- 运行时变量 ----------------------
var current_time: float = 0.0
var game_active: bool = false
var player_grid_pos: Vector2i

var start_pos: Vector2i
var end_pos: Vector2i

# 地图数据二维数组 (0:墙, 1:路, 2:怪, 3:传送)
var level_data: Array = [] 
var portal_locations: Array[Vector2i] = []

func _on_restart_pressed() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.hide()
	
	set_process_unhandled_input(false)
	
	# 同步gamedata
	rule_1 = GameData.enable_rule_1
	rule_2 = GameData.enable_rule_2
	# 1. 初始化地图数据
	_init_level_data()
	
	# 2. 初始化游戏状态
	current_time = initial_time
	game_active = true
	player_grid_pos = start_pos
	
	# 3. 设置角色初始位置
	_update_hero_position(start_pos)
	# 初始朝向动画（默认向下或根据需求）
	hero.play_anime("idle") 
	
	cover.clear()
	if not rule_1 and not rule_2:
		_generate_map_wall()
	else:
		_generate_number_labels()
	
	# 标出起点和终点
	
	cover.set_cell(start_pos, 0, Vector2i(3, 0))
	cover.set_cell(end_pos, 0, Vector2i(2, 0))
	await get_tree().create_timer(2.5).timeout
	await tween_camera(cover.map_to_local(end_pos), Vector2i(4, 4))
	await get_tree().create_timer(0.8).timeout
	await tween_camera(cover.map_to_local(start_pos), Vector2i(4, 4))
	# 允许操作
	draw_portal_line.walk_path.append(under.map_to_local(start_pos))
	set_process_unhandled_input(true)

func _process(delta: float) -> void:
	if not game_active:
		return
		
	current_time -= delta
	time_label.text = "%.2fs" % max(0, current_time)
	
	if current_time <= 0:
		_game_over(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SHIFT:
			draw_portal_line.visible = !draw_portal_line.visible
	
	if not game_active:
		return
		
	var move_dir = Vector2i.ZERO
	
	if event.is_action_pressed("ui_up"):
		move_dir = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		move_dir = Vector2i.DOWN
	elif event.is_action_pressed("ui_left"):
		move_dir = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		move_dir = Vector2i.RIGHT
	# 脱出传送门
	elif event.is_action_pressed("ui_accept"):
		if _calculate_neighbor_sum(player_grid_pos.x, player_grid_pos.y) == 0:
			_try_move(Vector2i.ZERO)
	
	if move_dir != Vector2i.ZERO:
		_try_move(move_dir)

# ---------------------- 核心移动逻辑 ----------------------
func _try_move(direction: Vector2i) -> void:
	var target_pos = player_grid_pos + direction
	
	_play_hero_animation(direction)
	
	if not _is_inside_grid(target_pos):
		return
		
	var cell_type = level_data[target_pos.y][target_pos.x]
	
	if cell_type == 0: 
		return # 只有0才是绝对的墙
	
	player_grid_pos = target_pos
	draw_portal_line.walk_path.append(under.map_to_local(target_pos))
	draw_portal_line.queue_redraw()
	_update_hero_position(player_grid_pos)
	
	_handle_cell_event(cell_type, target_pos)
	
	tween_camera(cover.map_to_local(player_grid_pos), Vector2i(4, 4))
	
	if player_grid_pos == end_pos:
		_game_over(true)
	
func _play_hero_animation(dir: Vector2i):
	if dir == Vector2i.UP:
		hero.play_anime("move_up")
	elif dir == Vector2i.DOWN:
		hero.play_anime("move_down")
	elif dir == Vector2i.LEFT:
		hero.play_anime("move_left")
	elif dir == Vector2i.RIGHT:
		hero.play_anime("move_right")

func _handle_cell_event(type: int, pos: Vector2i) -> void:
	match type:
		2: # 怪兽
			print("遭遇怪兽！时间 -2s")
			hero.play_anime("hurt")
			current_time -= 2.0
		3: # 传送门
			_teleport_player(pos)

func _teleport_player(current_portal_pos: Vector2i) -> void:
	# 简单的传送逻辑：传送到列表中的下一个传送门
	if draw_portal_line.portal_line.is_empty():
		draw_portal_line.portal_line.append(under.map_to_local(current_portal_pos))
	for i in range(portal_locations.size()):
		if portal_locations[i] == current_portal_pos:
			# 找到下一个传送门索引（循环）
			var next_index = (i + 1) % portal_locations.size()
			var target_portal = portal_locations[next_index]
			
			# 如果只有一个传送门，不传送
			if target_portal == current_portal_pos:
				return
			
			draw_portal_line.portal_line.append(under.map_to_local(target_portal))
			draw_portal_line.queue_redraw()
			player_grid_pos = target_portal
			_update_hero_position(player_grid_pos)
			hero.play_anime("idle")
			break

func _update_hero_position(grid_pos: Vector2i) -> void:
	# map_to_local 返回格子的中心像素坐标
	hero.position = under.map_to_local(grid_pos)

func _game_over(is_win: bool) -> void:
	game_active = false
	if is_win:
		print("游戏胜利！")
		time_label.text = "WIN!"
		time_label.modulate = Color.GOLD
	else:
		print("游戏失败！")
		time_label.text = "LOSE"
		time_label.modulate = Color.RED
	time_label.set_anchors_preset(Control.PRESET_CENTER, true)
	time_label.scale = Vector2(3, 3)
	tween_camera(Vector2(640, 360), Vector2(1, 1))
	restart_button.show()
	

# ---------------------- 数据与生成 ----------------------
func _init_level_data() -> void:
	level_data = []
	portal_locations.clear()
	
	# 1. 初始化全墙壁 (0)
	for y in range(MAP_HEIGHT):
		var row = []
		for x in range(MAP_WIDTH):
			row.append(0)
		level_data.append(row)
		
	# 2. 随机确立起点和终点
	# 起点：左上角 5x5 (0,0) 到 (4,4)
	start_pos = Vector2i(randi_range(0, 4), randi_range(0, 4))
	# 终点：右下角 5x5 (75,40) 到 (79,44)
	end_pos = Vector2i(randi_range(MAP_WIDTH - 5, MAP_WIDTH - 1), randi_range(MAP_HEIGHT - 5, MAP_HEIGHT - 1))
	
	# 设置全局变量供移动逻辑使用
	player_grid_pos = start_pos
	
	# 3. 生成主路径 (保证连通性)
	var way_pass: Array[Vector2i] = []
	way_pass.resize(waypoints)
	for i in range(waypoints):
		way_pass[i] = Vector2i(randi() % MAP_WIDTH, randi() % MAP_HEIGHT)
	_carve_path(start_pos, way_pass[0])
	_carve_path(way_pass[-1], end_pos)
	for i in range(way_pass.size() - 1):
		_carve_path(way_pass[i], way_pass[i+1])
	_carve_path(start_pos, way_pass.pick_random())
	_carve_path(end_pos, way_pass.pick_random())
	
	
	# 4. 增加随机噪点 (让地图更像迷宫，而不是一条线)
	_add_random_noise()
	
	# 确保起点终点一定是路(1)
	level_data[start_pos.y][start_pos.x] = 1
	level_data[end_pos.y][end_pos.x] = 1
	
	# 5. 放置怪兽 (2) 和 传送门 (3)
	if rule_1:
		_place_monsters_and_portals()
	
	# 6. 更新 Hero 位置
	_update_hero_position(start_pos)
	
	# (可选) 打印调试信息
	print("地图生成完毕。起点:", start_pos, " 终点:", end_pos)

# --- 迷宫算法具体实现 ---

func _carve_path(from: Vector2i, to: Vector2i) -> void:
	var current = from
	# 把起点变成路
	level_data[current.y][current.x] = 1
	
	# 只要没走到终点，就一直走
	while current != to:
		var move_dir = Vector2i.ZERO
		
		# 简单的随机游走算法：
		# 60% 的概率向终点方向靠拢，40% 的概率随机移动
		if randf() < random_trace:
			# 向终点靠拢
			var diff = to - current
			# 优先消除距离大的轴
			if abs(diff.x) > abs(diff.y):
				move_dir.x = sign(diff.x)
			else:
				move_dir.y = sign(diff.y)
		else:
			# 随机方向 (上下左右)
			var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
			move_dir = dirs.pick_random()
		
		# 计算下一步
		var next_step = current + move_dir
		
		# 确保不跑出地图边界
		next_step.x = clampi(next_step.x, 0, MAP_WIDTH - 1)
		next_step.y = clampi(next_step.y, 0, MAP_HEIGHT - 1)
		
		current = next_step
		# 挖空，变成路
		level_data[current.y][current.x] = 1

func _add_random_noise() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			# 如果是墙，有一定概率变成路
			# openness 越高，墙越少
			if level_data[y][x] == 0:
				if randf() < openness:
					level_data[y][x] = 1
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			# 如果是路，满足八格的条件下有概率变成墙
			if level_data[y][x] == 1:
				if randf() < (1-openness) and _calculate_eight_neighbor(x, y):
					level_data[y][x] = 0

func _place_monsters_and_portals() -> void:
	# --- 放置怪兽 (2) ---
	# 规则：在 1 的位置随机赋予 2
	var placed_monsters = 0
	var attempts = 0
	# 防止死循环，设置最大尝试次数
	while placed_monsters < monster_count and attempts < 10000:
		attempts += 1
		var x = randi_range(0, MAP_WIDTH - 1)
		var y = randi_range(0, MAP_HEIGHT - 1)
		
		# 只能放在路(1)上，且不能覆盖起点和终点
		if level_data[y][x] == 1 and Vector2i(x,y) != start_pos and Vector2i(x,y) != end_pos:
			level_data[y][x] = 2
			placed_monsters += 1
	
	# --- 放置传送门 (3) ---
	# 规则：在 0 的位置随机赋予成对的 3
	# 注意：如果把墙变成了传送门，玩家必须能走到传送门上才能传送。
	# 所以这里的逻辑是：把墙(0)变成传送门(3)，这个位置就变得"可通行"了。
	var placed_pairs = 0
	attempts = 0
	
	while placed_pairs < portal_pairs and attempts < 10000:
		attempts += 1
		# 找第一个点
		var p1 = _get_random_wall_pos()
		if p1 == Vector2i(-1, -1): continue # 找不到合适的墙了
		
		# 找第二个点
		var p2 = _get_random_wall_pos()
		if p2 == Vector2i(-1, -1) or p2 == p1: continue
		
		# 放置一对
		level_data[p1.y][p1.x] = 3
		level_data[p2.y][p2.x] = 3
		
		# 记录到传送门列表
		portal_locations.append(p1)
		portal_locations.append(p2)
		
		placed_pairs += 1

func _get_random_wall_pos() -> Vector2i:
	# 随机尝试找一个墙(0)的位置
	for i in range(100): # 尝试100次
		var x = randi_range(0, MAP_WIDTH - 1)
		var y = randi_range(0, MAP_HEIGHT - 1)
		# 必须是墙(0)，且不在边缘(为了美观防止出界风险，也可不加边缘限制)
		if level_data[y][x] == 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)

func _generate_number_labels() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			# 1. 计算周围四格数值和
			if rule_2:
				var sum_val = _calculate_neighbor_sum(x, y)
				var local_pos = under.map_to_local(Vector2i(x, y))
				var global_pos = under.to_global(local_pos)
				spawner_component.spawn(global_pos, sum_val)
			else:
				var local_pos = under.map_to_local(Vector2i(x, y))
				var global_pos = under.to_global(local_pos)
				spawner_component.spawn(global_pos, level_data[y][x])

func _generate_map_wall() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if level_data[y][x] == 0:
				under.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

func _calculate_neighbor_sum(x: int, y: int) -> int:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var total = 0
	
	for dir in directions:
		var check_pos = Vector2i(x, y) + dir
		if _is_inside_grid(check_pos):
			total += level_data[check_pos.y][check_pos.x]
			
	return total

# 周围8格都是路时，返回真
func _calculate_eight_neighbor(x: int, y: int) -> bool:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(-1, 1)]
	for dir in directions:
		var check_pos = Vector2i(x, y) + dir
		if _is_inside_grid(check_pos):
			if level_data[check_pos.y][check_pos.x] == 0:
				return false
			
	return true

func _is_inside_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < MAP_WIDTH and pos.y >= 0 and pos.y < MAP_HEIGHT

func tween_camera(target_pos: Vector2, target_zoom: Vector2, duration: float = 1.0):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(dragable_camera, "global_position", target_pos, duration)
	tween.tween_property(dragable_camera, "zoom", target_zoom, duration)
	await tween.finished

func _on_dragable_camera_click_left(click_position: Vector2) -> void:
	var click_pos_map := under.local_to_map(click_position)
	if _is_inside_grid(click_pos_map):
		if under.get_cell_atlas_coords(click_pos_map) == Vector2i(0, 0):
			under.set_cell(click_pos_map, 0, Vector2i(1, 0))
		else:
			under.set_cell(click_pos_map, 0, Vector2i(0, 0))
