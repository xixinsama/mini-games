## 使一个Node2D节点晃动的组件
class_name ShakeComponent
extends Node


# You should shake the sprite and not the root node or you'll get unexpected behavior
# since we are manipulating the position of the node and moving it to 0,0
# 你应该摇动精灵而不是根节点，否则你会得到意想不到的行为
# 因为我们正在操纵节点的位置并将其移动到 0,0 
# 就是相对位置和绝对位置，我们只希望调整其相对位置
@export var node: Node2D ## 摇晃目标
@export var shake_amount: float = 2.0 ## 震动幅度
@export var shake_duration: float = 0.4 ## 震动持续时间
@export var position_inheritance: bool = false ## 如果为true, 则只记录最开始的位置，详细见脚本原文

# Store the current amount we are shaking the node (this value will decrease over time)
# 存储当前震动幅度，将随时间减小
var shake = 0
var node_position_now: Vector2 #记录当前位置

func _ready() -> void:
	if position_inheritance == true:
		await get_tree().create_timer(0.1).timeout
		node_position_now = node.position
	else:
		return

func tween_shake():
	# Set the shake to the shake amount (shake is the value used in the process function to
	# shake the node)
	shake = shake_amount
	# 创造一个缓动效果，并最终降到0
	create_tween().tween_property(self, "shake", 0.0, shake_duration).from_current()

func _physics_process(_delta: float) -> void:
	# Manipulate the position of the node by the shake amount every physics frame
	# Use randf_range to pick a random x and y value using the shake value
	node.position = node_position_now + Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
