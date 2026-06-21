extends Camera2D


var is_panning: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var zoom_speed = Vector2(0.1, 0.1)
var joystick_index: int = 0
var joystick_right_speed = 50
var windows_size: Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

signal click_left(click_position: Vector2) ## 鼠标左键点击的位置
signal click_right(click_position: Vector2) ## 鼠标右键点击的位置

func _unhandled_input(event: InputEvent) -> void:
	# 按住鼠标中键平移
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			last_mouse_position = event.position
		# 使用鼠标滚轮放大缩小画面
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += zoom_speed
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= zoom_speed
		zoom = zoom.clamp(Vector2(0.1, 0.1), Vector2(2, 2))
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

#func _process(delta):
	## 手柄右摇杆移动镜头
	#var axis_right_x: float = Input.get_joy_axis(joystick_index, JOY_AXIS_RIGHT_X)
	#var axis_right_y: float = Input.get_joy_axis(joystick_index, JOY_AXIS_RIGHT_Y)
	#var movement: Vector2 = Vector2(axis_right_x * joystick_right_speed * delta, axis_right_y * joystick_right_speed * delta)
	#translate(movement)

### 移动到主塔位置
#func _on_kt_button_pressed() -> void:
	#var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	#tween.tween_property(self, "position", GameTileStats.tile_self.map_to_local(GameTileStats.start_location), 0.2)
#func _on_cn_button_pressed() -> void:
	#var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	#tween.tween_property(self, "position", Vector2(0, 0), 0.2)
