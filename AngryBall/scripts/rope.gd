extends Path3D

@export var segments_per_unit: float = 50.0  # 每单位长度的分段数
@export var rope_radius: float = 0.1
@export var rope_material: Material
@export var update_in_runtime: bool = false
@export var max_pool_size: int = 200  # 对象池最大容量

var cylinder_pool: Array[MeshInstance3D] = []
var active_cylinders: Array[MeshInstance3D] = []
var last_curve_length: float = 0.0

func _ready():
	if not update_in_runtime:
		curve_changed.connect(generate_rope)
	set_process(update_in_runtime)
	initialize_pool()
	generate_rope()
	
func initialize_pool():
	# 初始创建一些圆柱体放入对象池
	var initial_pool_size = min(100, max_pool_size)
	for i in range(initial_pool_size):
		var cylinder = create_cylinder()
		cylinder.visible = false
		cylinder_pool.append(cylinder)

func create_cylinder() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = rope_radius
	cylinder.bottom_radius = rope_radius
	cylinder.radial_segments = 6  # 较低的细分提高性能
	
	mesh_instance.mesh = cylinder
	
	if rope_material:
		mesh_instance.material_override = rope_material
	
	return mesh_instance

func generate_rope():
	if not curve:
		push_warning("Path3D 没有设置 Curve3D")
		return
	
	var curve_length = curve.get_baked_length()
	
	last_curve_length = curve_length
	
	# 根据曲线长度计算分段数
	var segment_count = max(2, int(curve_length * segments_per_unit))
	
	# 确保对象池有足够圆柱体
	ensure_pool_size(segment_count)
	
	# 采样曲线点
	var points = sample_curve_points(curve_length, segment_count)
	
	# 激活并更新圆柱体
	update_cylinders(points, segment_count)

func sample_curve_points(curve_length: float, segment_count: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	
	# 采样曲线上的点
	for i in range(segment_count + 1):
		var distance = (i * curve_length) / segment_count
		points.append(curve.sample_baked(distance))
	
	return points

func ensure_pool_size(required_count: int):
	# 如果对象池不够大，添加新的圆柱体
	while cylinder_pool.size() < required_count and cylinder_pool.size() < max_pool_size:
		cylinder_pool.append(create_cylinder())
	
	# 如果对象池太大，移除多余的圆柱体
	while cylinder_pool.size() > required_count * 2 and cylinder_pool.size() > 10:
		var cylinder = cylinder_pool.pop_back()
		if is_instance_valid(cylinder):
			cylinder.queue_free()

func update_cylinders(points: Array[Vector3], segment_count: int):
	# 隐藏所有当前活动的圆柱体
	for cylinder in active_cylinders:
		cylinder.visible = false
	
	# 清空活动列表
	active_cylinders.clear()
	
	# 为每个分段获取或创建圆柱体
	for i in range(segment_count):
		var cylinder = get_cylinder_from_pool(i)
		if not cylinder:
			continue
			
		# 设置圆柱体的位置和旋转
		var start_point = points[i]
		var end_point = points[i + 1]
		setup_cylinder_between_points(cylinder, start_point, end_point)
		
		# 添加到活动列表
		active_cylinders.append(cylinder)
		cylinder.visible = true

func get_cylinder_from_pool(index: int) -> MeshInstance3D:
	if index < cylinder_pool.size():
		return cylinder_pool[index]
	
	# 如果池子不够大，创建新的圆柱体
	if cylinder_pool.size() < max_pool_size:
		var new_cylinder = create_cylinder()
		cylinder_pool.append(new_cylinder)
		return new_cylinder
	
	# 池子已满，返回null
	push_warning("对象池已满，无法创建更多圆柱体")
	return null

func setup_cylinder_between_points(cylinder: MeshInstance3D, start: Vector3, end: Vector3):
	var direction = end - start
	var distance = direction.length()
	
	if distance == 0:
		cylinder.visible = false
		return
	
	direction = direction.normalized()
	
	# 更新圆柱体高度
	var cylinder_mesh = cylinder.mesh as CylinderMesh
	if cylinder_mesh:
		cylinder_mesh.height = distance
	
	# 定位和旋转圆柱体
	cylinder.position = (start + end) / 2  # 中点
	
	# 计算旋转使圆柱体指向目标方向
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.9:
		up = Vector3.RIGHT  # 避免万向锁
		
	cylinder.look_at(cylinder.position + direction, up)
	cylinder.rotate_object_local(Vector3.RIGHT, PI / 2)  # 调整方向使圆柱体沿路径

func _process(_delta):
	if update_in_runtime:
		generate_rope()

# 清理函数，防止内存泄漏
func _exit_tree():
	for cylinder in cylinder_pool:
		if is_instance_valid(cylinder):
			cylinder.queue_free()
	cylinder_pool.clear()
	active_cylinders.clear()
