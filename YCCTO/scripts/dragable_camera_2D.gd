extends Camera2D
class_name DragableCamera

@export var zoom_range: Array[Vector2] = [Vector2(0.3, 0.3), Vector2(2, 2)]

var is_panning: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
@export var zoom_speed = Vector2(0.1, 0.1)
var joystick_index: int = 0
var joystick_right_speed = 50
var windows_size: Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

# 触摸控制相关变量
var touch_drag_index: int = -1
var touch_positions = {}  # 存储触摸点位置

signal click_left(click_position: Vector2) ## 鼠标左键点击的位置
signal click_right(click_position: Vector2) ## 鼠标右键点击的位置
signal scale_changed(scale_now: Vector2)
signal position_changed(pos_now: Vector2)

func _unhandled_input(event: InputEvent) -> void:
	# 处理桌面设备的鼠标和滚轮输入
	_handle_desktop_input(event)
	
	# 处理触摸输入 (Android/iOS)
	_handle_touch_input(event)
	
	# 处理手势输入
	_handle_gesture_input(event)

func _handle_desktop_input(event: InputEvent) -> void:
	# 按住鼠标中键平移
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			last_mouse_position = event.position
		# 使用鼠标滚轮放大缩小画面
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom + zoom_speed).clamp(zoom_range[0], zoom_range[1])
			send_zoom()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom - zoom_speed).clamp(zoom_range[0], zoom_range[1])
			send_zoom()
		if event.is_released():
			# 位置转化为TilemapLayer可用的形式
			var click_position: Vector2 = (event.position - windows_size / 2) / zoom + position
			if event.button_index == MOUSE_BUTTON_LEFT:
				click_left.emit(click_position) 
			if event.button_index == MOUSE_BUTTON_RIGHT:
				click_right.emit(click_position)
	elif event is InputEventMouseMotion and is_panning:
		var delta_pos = event.position - last_mouse_position
		translate(-delta_pos / zoom) # 位置与光标锁定
		last_mouse_position = event.position
		send_pos()

func _handle_touch_input(event: InputEvent) -> void:
	# 处理触摸事件
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_positions[event.index] = event.position
			# 如果是第一个触摸点，用于拖拽
			if touch_drag_index == -1:
				touch_drag_index = event.index
				last_mouse_position = event.position
				is_panning = true
		else:
			# 触摸结束
			touch_positions.erase(event.index)
			if event.index == touch_drag_index:
				touch_drag_index = -1
				is_panning = false
				
			# 发射点击信号 (模拟鼠标点击)
			var click_position: Vector2 = get_mouse_global_tilemap_position()
			#(event.position - windows_size / 2) / zoom + position
			if event.index == 0:  # 第一个触摸点视为左键点击
				click_left.emit(click_position)
			elif event.index == 1:  # 第二个触摸点视为右键点击
				click_right.emit(click_position)
	
	# 处理触摸拖拽
	elif event is InputEventScreenDrag:
		touch_positions[event.index] = event.position
		if event.index == touch_drag_index and is_panning:
			var delta_pos = event.position - last_mouse_position
			translate(-delta_pos / zoom)
			last_mouse_position = event.position
			send_pos()

func _handle_gesture_input(event: InputEvent) -> void:
	# 处理平移手势
	if event is InputEventPanGesture:
		# 使用手势的delta来移动摄像机
		translate(-event.delta / zoom)
		send_pos()
	
	# 处理缩放手势
	elif event is InputEventMagnifyGesture:
		# 使用手势的factor来缩放
		var new_zoom = zoom * event.factor
		new_zoom = new_zoom.clamp(Vector2(0.3, 0.3), Vector2(2, 2))
		
		# 计算缩放中心点
		var zoom_center = event.position
		var zoom_center_world = (zoom_center - windows_size / 2) / zoom + position
		
		# 应用缩放
		zoom = new_zoom
		
		# 调整摄像机位置以保持缩放中心不变
		var new_zoom_center_world = (zoom_center - windows_size / 2) / zoom + position
		position += zoom_center_world - new_zoom_center_world
		
		send_zoom()
		send_pos()

func get_mouse_global_tilemap_position() -> Vector2:
	return (get_viewport().get_mouse_position() - windows_size / 2) / zoom + position

func send_pos() -> void:
	position_changed.emit(position)

func send_zoom() -> void:
	scale_changed.emit(zoom)
