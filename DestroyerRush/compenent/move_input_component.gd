## 获取输入控制节点移动的组件
class_name MoveInputComponent
extends Node


@export var stats_component: StatsComponent # 从该组件获取Speed信息
@export var move_component: MoveComponent # 输出到该组件进行

signal roll_start
signal roll_finish

# 能否翻滚
var roll_enable: bool = false

func _unhandled_input(_event: InputEvent) -> void:
	# 如果按下Esc，退出游戏
	#if event is InputEventKey:
		#if event.pressed and event.keycode == KEY_ESCAPE:
			#get_tree().quit()
	# 控制方向
	var input_axis_horizonal = Input.get_axis("ui_left", "ui_right")
	var input_axis_vertical = Input.get_axis("ui_up", "ui_down") #"")
	var direction: Vector2 = Vector2(input_axis_horizonal, input_axis_vertical).normalized()
	#if direction == Vector2() and move_component.velocity != Vector2():
	#	move_component.velocity = Vector2()
	var now_velocity: Vector2 = direction * stats_component.speed
	move_component.velocity = now_velocity

	# 翻滚
	# 执行过程中再次按键会被新的tween打断
	# 把CD（能量）加上
	if Input.is_action_just_pressed("roll") or Input.is_action_just_pressed("skill"): 
		if not direction == Vector2() and roll_enable == true:
			var tween = create_tween()
			tween.set_loops(1)
			var final_v = direction * stats_component.speed * stats_component.roll_speed
			roll_start.emit()
			tween.tween_property(move_component, "roll_velocity", final_v, 0.5)
			tween.tween_property(move_component, "roll_velocity", Vector2(), 0.2)
			tween.finished.connect(func() -> void:
				roll_enable = false
				roll_finish.emit()
				)
	# 格挡
	# 子弹时间
	# 主动清屏
	
