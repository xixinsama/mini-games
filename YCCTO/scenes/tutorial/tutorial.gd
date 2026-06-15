extends Control

@onready var start_button: Button = $StartButton
@onready var under: TileMapLayer = $Under
@onready var grid_1: Node2D = $Grid1
@onready var grid_2: Node2D = $Grid2
@onready var grid_3: Node2D = $Grid3
@onready var hero: Node2D = $Hero
@onready var cover: TileMapLayer = $Cover
@onready var rule_button_1: Button = $RuleButton1
@onready var rule_button_2: Button = $RuleButton2

const rule_2_rect: Rect2i = Rect2i(512, 320, 192, 192)
const rule1_start_map_pos: Vector2i = Vector2i(2, 5)
const rule2_start_map_pos: Vector2i = Vector2i(8, 5)

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	start_button.text = tr("START_BUTTON")

func _process(_delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	if rule_2_rect.has_point(mouse_pos):
		var target_map_position: Vector2i = (Vector2i(mouse_pos) - rule_2_rect.position) / Vector2i(64, 64)
		target_map_position = rule2_start_map_pos + target_map_position
		cover.clear()
		cover.set_cell(target_map_position, 0, Vector2(2, 0))
		cover.set_cell(target_map_position - Vector2i(6, 1), 0, Vector2(3, 0))
		cover.set_cell(target_map_position - Vector2i(6, -1), 0, Vector2(3, 0))
		cover.set_cell(target_map_position - Vector2i(7, 0), 0, Vector2(3, 0))
		cover.set_cell(target_map_position - Vector2i(5, 0), 0, Vector2(3, 0))
		
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_texture_button_cn_pressed() -> void:
	LocalizationManager.set_language("zh_CN")
func _on_texture_button_en_pressed() -> void:
	LocalizationManager.set_language("en")
func _on_texture_button_ja_pressed() -> void:
	LocalizationManager.set_language("ja")
	start_button.set("theme_override_fonts/font", load("res://assets/fonts/nagino.otf"))
	start_button.text = tr("START_BUTTON")

#region player_control
var player_grid_pos := Vector2i.ZERO
var vaild_grid := Rect2i(Vector2i.ZERO, Vector2i(3, 3))
# map_data[y][x]
var map_data: Array = [
	[1, 1, 3],
	[0, 2, 0],
	[3, 1, 1],
]

func _unhandled_input(event: InputEvent) -> void:
	var move_dir = Vector2i.ZERO
	
	if event.is_action_pressed("ui_up"):
		move_dir = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		move_dir = Vector2i.DOWN
	elif event.is_action_pressed("ui_left"):
		move_dir = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		move_dir = Vector2i.RIGHT
	
	if move_dir != Vector2i.ZERO:
		_try_move(move_dir)

func _try_move(direction: Vector2i) -> void:
	var target_pos = player_grid_pos + direction
	_play_hero_animation(direction)
	if not vaild_grid.has_point(target_pos):
		return
	var cell_type = map_data[target_pos.y][target_pos.x]
	if cell_type == 0: 
		return # 只有0才是绝对的墙
	player_grid_pos = target_pos
	_update_hero_position(player_grid_pos)
	_handle_cell_event(cell_type, target_pos)

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
		3: # 传送门
			if pos == Vector2i(0, 2):
				_update_hero_position(Vector2i(2, 0))
			else:
				_update_hero_position(Vector2i(0, 2))

const hero_start_pos := Vector2i(928, 352)
func _update_hero_position(grid_pos: Vector2i):
	player_grid_pos = grid_pos
	hero.global_position  = grid_pos*64 + hero_start_pos

#endregion


func _on_rule_button_1_toggled(toggled_on: bool) -> void:
	GameData.enable_rule_1 = toggled_on
	if toggled_on:
		rule_button_1.text = "√"
		grid_1.show()
		under.set_cell(rule1_start_map_pos, 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(1, 0), 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(2, 0), 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(0, 1), 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(1, 1), 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(2, 1), 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(0, 2), 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(1, 2), 0, Vector2i(1, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(2, 2), 0, Vector2i(1, 0))
	else:
		rule_button_1.text = "x"
		grid_1.hide()
		under.set_cell(rule1_start_map_pos, 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(1, 0), 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(2, 0), 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(0, 1), 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(1, 1), 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(2, 1), 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(0, 2), 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(1, 2), 0, Vector2i(0, 0))
		under.set_cell(rule1_start_map_pos + Vector2i(2, 2), 0, Vector2i(0, 0))

func _on_rule_button_2_toggled(toggled_on: bool) -> void:
	GameData.enable_rule_2 = toggled_on
	if toggled_on:
		rule_button_2.text = "√"
		grid_2.show()
		under.set_cell(rule2_start_map_pos, 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(1, 0), 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(2, 0), 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(0, 1), 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(1, 1), 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(2, 1), 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(0, 2), 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(1, 2), 0, Vector2i(1, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(2, 2), 0, Vector2i(1, 0))
	else:
		rule_button_2.text = "x"
		grid_2.hide()
		under.set_cell(rule2_start_map_pos, 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(1, 0), 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(2, 0), 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(0, 1), 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(1, 1), 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(2, 1), 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(0, 2), 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(1, 2), 0, Vector2i(0, 0))
		under.set_cell(rule2_start_map_pos + Vector2i(2, 2), 0, Vector2i(0, 0))
		
