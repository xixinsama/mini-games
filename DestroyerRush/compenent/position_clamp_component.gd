## 限制节点的位置在屏幕内
class_name PositionClampComponent
extends Node2D

@export var actor: Node2D

@export var margin: = 5 ## 边缘距离

# 获取项目的设置数值
# 如果缩放了倍数，则实际分辨率只有缩放后的大小
var proj_scale = ProjectSettings.get_setting("display/window/stretch/scale")

var left_border = 0
var right_border = ProjectSettings.get_setting("display/window/size/viewport_width") / proj_scale
var up_border = 0
var down_border = ProjectSettings.get_setting("display/window/size/viewport_height") / proj_scale

func _process(_delta):
	actor.global_position.x = clamp(actor.global_position.x, left_border+margin, right_border-margin)
	actor.global_position.y = clamp(actor.global_position.y, up_border+margin, down_border-margin)
