extends Area3D
class_name KillZone
# KillZone - 当小球掉落出界时触发游戏结束

signal ball_out_of_bounds

func _ready():
	# 连接body_entered信号
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 检查是否是小球
	if body is PinBall3d or body.is_in_group("Ball"):
		print("Ball went out of bounds!")
		ball_out_of_bounds.emit()
		
		# 通知主场景
		var main_scene = get_tree().root.get_node("Main")
		if main_scene and main_scene.has_method("on_ball_out_of_bounds"):
			main_scene.on_ball_out_of_bounds()
