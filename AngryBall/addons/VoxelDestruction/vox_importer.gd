# import_plugin.gd
@tool
extends EditorImportPlugin

enum Resource_type {
	DEFAULT = 0,
	COMPACT = 2
}

enum Presets { 
	SCALE,
	CHUNK_SIZE,
	RESOURCE_TYPE
}


func _get_preset_count():
	return Presets.size()


func _get_preset_name(preset_index):
	match preset_index:
		Presets.SCALE:
			return "Scale"
		Presets.CHUNK_SIZE:
			return "Chunk Size"
		Presets.RESOURCE_TYPE:
			return "Resource"
		_:
			return "Unknown"


func _get_import_options(path, preset_index):
	return [{
			   "name": "Scale",
			   "default_value": Vector3(.1, .1, .1)
			},
			{
			   "name": "Chunk_Size",
			   "default_value": Vector3(16, 16, 16)
			},
			{
			   "name": "Resource_type",
			   "default_value": Resource_type.DEFAULT,
			   "property_hint": PROPERTY_HINT_ENUM,
			   "hint_string": "Default,Compact"
			}]


func _get_option_visibility(path, option_name, options):
	return true


func _can_import_threaded() -> bool:
	return true


func _get_importer_name():
	return "vox_object.voxel_destruction"


func _get_visible_name():
	return "Voxel Object"


func _get_priority():
	return 1


func _get_import_order():
	return 0


func _get_recognized_extensions():
	return ["vox"]


func _get_save_extension():
	return "tres"


func _get_resource_type():
	return "VoxelResource"


func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var scale = options.Scale if options.has("Scale") else Vector3(.1, .1, .1)
	
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		push_error("Cannot open file: " + source_file)
		return FileAccess.get_open_error()
	
	var voxels = []
	var palette = []
	var size: Vector3
	
	# Initialize default palette
	for i in range(256):
		palette.append(Color(1, 1, 1, 1))
	
	# Read file header
	var magic = file.get_buffer(4).get_string_from_ascii()
	if magic != "VOX ":
		push_error("Invalid .vox file format! Magic: " + str(magic))
		file.close()
		return ERR_FILE_CORRUPT
	
	var version = file.get_32()
	print("VOX version: ", version)
	
	# Read MAIN chunk
	var main_chunk_id = file.get_buffer(4).get_string_from_ascii()
	var main_chunk_size = file.get_32()
	var main_child_chunks = file.get_32()
	
	if main_chunk_id != "MAIN":
		push_error("Expected MAIN chunk, got: " + main_chunk_id)
		file.close()
		return ERR_FILE_CORRUPT
	
	# Read all child chunks
	var voxel_data_found = false
	var size_data_found = false
	var palette_found = false
	
	while not file.eof_reached() and file.get_position() < file.get_length() - 8:
		var chunk_id = file.get_buffer(4).get_string_from_ascii()
		var chunk_size = file.get_32()
		var child_chunk_size = file.get_32()
		
		if chunk_id == "SIZE":
			var size_x = file.get_32()
			var size_y = file.get_32()
			var size_z = file.get_32()
			size = Vector3(size_x, size_z, size_y)
			size_data_found = true
			
		elif chunk_id == "XYZI":
			var num_voxels = file.get_32()
			
			for i in range(num_voxels):
				var x = file.get_8()
				var y = file.get_8()
				var z = file.get_8()
				var color_index = file.get_8()
				
				voxels.append({"position": Vector3(x, y, z), "color_index": color_index})
			
			voxel_data_found = true
			
		elif chunk_id == "RGBA":
			palette = []
			for i in range(256):
				var r = file.get_8() / 255.0
				var g = file.get_8() / 255.0
				var b = file.get_8() / 255.0
				var a = file.get_8() / 255.0
				palette.append(Color(r, g, b, a))
			palette_found = true
			
		elif chunk_id == "PACK":
			var num_models = file.get_32()
			
		else:
			file.seek(file.get_position() + chunk_size)
	
	file.close()
	
	# Validate data
	if not voxel_data_found:
		push_error("No voxel data (XYZI chunk) found!")
		return ERR_FILE_CORRUPT
	
	if not size_data_found:
		push_error("No size data (SIZE chunk) found!")
		return ERR_FILE_CORRUPT
	
	if voxels.is_empty():
		push_error("Voxels array is empty!")
		return ERR_FILE_CORRUPT
	
	print("Successfully parsed ", voxels.size(), " voxels")
	
	# Create VoxelResource
	var voxel_resource
	if options.has("Resource_type") and options.Resource_type == 1:
		voxel_resource = CompactVoxelResource.new()
	else:
		voxel_resource = VoxelResource.new()
	
	# Initialize arrays
	voxel_resource.colors = PackedColorArray()
	voxel_resource.color_index = PackedByteArray()
	voxel_resource.health = PackedByteArray()
	voxel_resource.positions = PackedVector3Array()
	voxel_resource.vox_chunk_indices = PackedVector3Array()
	voxel_resource.visible_voxels = PackedVector3Array()
	#voxel_resource.chunks = {}
	
	# Set basic properties
	voxel_resource.vox_count = voxels.size()
	voxel_resource.vox_size = scale
	voxel_resource.origin = size / Vector3(2, 2, 2)
	voxel_resource.size = size
	
	# Initialize health
	voxel_resource.health.resize(voxels.size())
	for i in range(voxel_resource.health.size()):
		voxel_resource.health[i] = 100
	
	# Process voxels
	var positions_dict_temp: Dictionary[Vector3i, int] = {}
	var index = 0
	
	for voxel in voxels:
		var color_idx = voxel["color_index"] - 1
		var color: Color
		
		if palette_found and color_idx >= 0 and color_idx < palette.size():
			color = palette[color_idx]
		else:
			color = Color(1, 1, 1, 1)
		
		# Add unique colors
		var existing_color_idx = voxel_resource.colors.find(color)
		if existing_color_idx == -1:
			voxel_resource.colors.append(color)
			existing_color_idx = voxel_resource.colors.size() - 1
		voxel_resource.color_index.append(existing_color_idx)
		
		# Convert coordinates: VOX (x,y,z) -> Godot (x,z,y)
		var pos = voxel["position"]
		var adjusted_position = Vector3i(pos.x, pos.z, pos.y)
		
		voxel_resource.positions.append(Vector3(adjusted_position))
		positions_dict_temp[adjusted_position] = index
		index += 1
	
	# Assign typed dictionary
	voxel_resource.positions_dict = positions_dict_temp
	
	print("Processed ", voxel_resource.positions.size(), " positions and ", voxel_resource.colors.size(), " unique colors")
	
	# Create chunks
	var chunk_size = options.Chunk_Size if options.has("Chunk_Size") else Vector3(16, 16, 16)
	var vox_chunk_indices = PackedVector3Array()
	var chunks_temp: Dictionary[Vector3, PackedVector3Array] = {}
	var voxel_set: Dictionary = {}
	
	for voxel_pos in voxel_resource.positions:
		var voxel_pos_i = Vector3i(voxel_pos)
		var chunk = Vector3(
			int(voxel_pos.x / chunk_size.x),
			int(voxel_pos.y / chunk_size.y), 
			int(voxel_pos.z / chunk_size.z)
		)
		vox_chunk_indices.append(chunk)
		
		if not chunks_temp.has(chunk):
			chunks_temp[chunk] = PackedVector3Array()
		chunks_temp[chunk].append(voxel_pos)
		
		voxel_set[voxel_pos_i] = true
	
	voxel_resource.vox_chunk_indices = vox_chunk_indices
	voxel_resource.chunks = chunks_temp
	
	# Create collision shapes
	var starting_shapes = []
	for chunk in chunks_temp:
		var boxes = create_boxes(chunks_temp[chunk])
		var shapes = create_shapes(boxes, scale, chunk)
		starting_shapes.append_array(shapes)
	
	voxel_resource.starting_shapes = starting_shapes
	
	# Calculate visible voxels
	var visible_voxels = PackedVector3Array()
	var offsets = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	
	for vox in voxel_resource.positions:
		var vox_i = Vector3i(vox)
		var is_visible = false
		
		for offset in offsets:
			var neighbor = vox_i + offset
			if not voxel_set.has(neighbor):
				is_visible = true
				break
		
		if is_visible:
			visible_voxels.append(vox)
	
	voxel_resource.visible_voxels = visible_voxels
	
	# Save resource
	var save_path_with_extension = "%s.%s" % [save_path, _get_save_extension()]
	print("Saving resource to: ", save_path_with_extension)
	
	var err = ResourceSaver.save(voxel_resource, save_path_with_extension)
	if err != OK:
		push_error("Failed to save resource: " + str(err))
		return err
	
	print("Resource saved successfully!")
	return OK


func create_boxes(chunk: PackedVector3Array) -> Array:
	var visited: Dictionary = {}
	var boxes = []

	var can_expand = func(box_min: Vector3, box_max: Vector3, axis: int, pos: int) -> bool:
		var start
		var end
		match axis:
			0: start = Vector3(pos, box_min.y, box_min.z); end = Vector3(pos, box_max.y, box_max.z)
			1: start = Vector3(box_min.x, pos, box_min.z); end = Vector3(box_max.x, pos, box_max.z)
			2: start = Vector3(box_min.x, box_min.y, pos); end = Vector3(box_max.x, box_max.y, pos)

		for x in range(int(start.x), int(end.x) + 1):
			for y in range(int(start.y), int(end.y) + 1):
				for z in range(int(start.z), int(end.z) + 1):
					var check_pos = Vector3(x, y, z)
					if not chunk.has(check_pos) or visited.get(check_pos, false):
						return false
		return true
	
	for pos in chunk:
		if visited.get(pos, false):
			continue
		
		var box_min = pos
		var box_max = pos
		
		for axis in range(3):
			while true:
				var next_pos = box_max[axis] + 1
				if can_expand.call(box_min, box_max, axis, next_pos):
					box_max[axis] = next_pos
				else:
					break

		for x in range(int(box_min.x), int(box_max.x) + 1):
			for y in range(int(box_min.y), int(box_max.y) + 1):
				for z in range(int(box_min.z), int(box_max.z) + 1):
					visited[Vector3(x, y, z)] = true

		boxes.append({"min": box_min, "max": box_max})

	return boxes


func create_shapes(boxes: Array, voxel_size: Vector3, chunk) -> Array:
	var shapes = []
	for box in boxes:
		var min_pos = box["min"]
		var max_pos = box["max"]
		
		var center = (min_pos + max_pos) * 0.5 * voxel_size
		var size = ((max_pos - min_pos) + Vector3.ONE) * voxel_size
		shapes.append({"extents": size * 0.5, "position": center, "chunk": chunk})
	
	return shapes
