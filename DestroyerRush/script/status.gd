extends Node

# 局内信息
var player_position: Vector2 = Vector2(360, 1100)
var player_health: int
var player_velocity: Vector2
var enemy_position: Vector2
var enemy_health: int

# 通关信息
const SAVE_PATH = "user://save.cfg"
const TEST_SAVE_PATH = "res://save.cfg"
var save_path = TEST_SAVE_PATH

var times_win_level1: int # level_2
var times_win_level2: int # level_1
var times_win_level3: int # level_0
var times_win_level4: int # level_3
var times_win_level5: int # level_5

func load_gamefile() -> void:
	var config = ConfigFile.new()
	var error = config.load(save_path)
	if error != OK: return
	times_win_level1 = config.get_value("TimesOfWin", "Level1")
	times_win_level2 = config.get_value("TimesOfWin", "Level2")
	times_win_level3 = config.get_value("TimesOfWin", "Level3")
	times_win_level4 = config.get_value("TimesOfWin", "Level4")
	times_win_level5 = config.get_value("TimesOfWin", "Level5")

func save_gamefile() -> void:
	var config = ConfigFile.new()
	config.set_value("TimesOfWin", "Level1", times_win_level1)
	config.set_value("TimesOfWin", "Level2", times_win_level2)
	config.set_value("TimesOfWin", "Level3", times_win_level3)
	config.set_value("TimesOfWin", "Level4", times_win_level4)
	config.set_value("TimesOfWin", "Level5", times_win_level5)
	config.save(save_path)

# 随机过场效果
func scene_into(next_scene: PackedScene, flag: int = 0) -> void:
	var out_effect: int = randi_range(1, 16)
	if flag != 0 and flag in range(1, 17):
		out_effect = flag
	if out_effect == 1:
		FancyFade.wipe_left(next_scene.instantiate())
	elif out_effect == 2:
		FancyFade.wipe_right(next_scene.instantiate())
	elif out_effect == 3:
		FancyFade.wipe_up(next_scene.instantiate())
	elif out_effect == 4:
		FancyFade.wipe_down(next_scene.instantiate())
	elif out_effect == 5:
		FancyFade.wipe_square(next_scene.instantiate())
	elif out_effect == 6:
		FancyFade.wipe_conical(next_scene.instantiate())
	elif out_effect == 7:
		FancyFade.circle_in(next_scene.instantiate())
	elif out_effect == 8:
		FancyFade.circle_out(next_scene.instantiate())
	elif out_effect == 9:
		FancyFade.noise(next_scene.instantiate())
	elif out_effect == 10:
		FancyFade.pixelated_noise(next_scene.instantiate())
	elif out_effect == 11:
		FancyFade.blurry_noise(next_scene.instantiate())
	elif out_effect == 12:
		FancyFade.cell_noise(next_scene.instantiate())
	elif out_effect == 13:
		FancyFade.horizontal_paint_brush(next_scene.instantiate())
	elif out_effect == 14:
		FancyFade.vertical_paint_brush(next_scene.instantiate())
	elif out_effect == 15:
		FancyFade.swirl(next_scene.instantiate())
	elif out_effect == 16:
		FancyFade.tile_reveal(next_scene.instantiate())
	else:
		print("没有效果")
		return
