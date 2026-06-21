extends TileMapLayer

enum CellType { FLOOR = 0, WALL = 1, TARGET = -1 }

const tile_size: Vector2 = Vector2(64, 64)

# 根据世界坐标获取单元格类型
func get_cell_type(world_pos: Vector2) -> int:
	var map_pos = local_to_map(world_pos)
	var data = get_cell_tile_data(map_pos)  # 假设自定义数据在第0层
	
	if data:
		return data.get_custom_data("type")
	return CellType.WALL

# 检查是否为墙
func is_wall(world_pos: Vector2) -> bool:
	return get_cell_type(world_pos) == CellType.WALL

# 检查是否为目标点
func is_target(world_pos: Vector2) -> bool:
	return get_cell_type(world_pos) == CellType.TARGET

# 获取所有目标点位置（世界坐标）
func get_all_target_positions() -> Array:
	var targets = []
	var used_cells = get_used_cells()  # 获取第0层所有已用单元格
	
	for cell in used_cells:
		if get_cell_type(map_to_local(cell)) == CellType.TARGET:
			targets.append(map_to_local(cell) + tile_size / 2)
	
	return targets
