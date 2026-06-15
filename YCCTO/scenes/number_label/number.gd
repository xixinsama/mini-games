@tool
extends Node2D
class_name NumberLabel

@onready var label: Label = $Label

## 一位数字字符用80
## 二位数字，包括负号用64
## 三位数字，包括负号用48
## -999，❌用36
@export var num_int: int = 0:
	set(value):
		num_int = clampi(value, -999, 999)
		set_number()

func _ready() -> void:
	set_number()

func initialize(flag: int) -> void:
	num_int = flag

## 如果不是整数则为X
func set_number():
	if label:
		label.set("theme_override_colors/font_color", get_color_by_last_digit(num_int))
		label.text = str(num_int)

# 数字颜色数组（对应0-9）
var digit_colors = [
	Color.LIGHT_CYAN,    # 0
	Color.LIGHT_SKY_BLUE,    # 1: 蓝色
	Color.PALE_GREEN,    # 2: 绿色
	Color.LIGHT_CORAL,
	Color.LIGHT_STEEL_BLUE,
	Color.SANDY_BROWN,    # 5
	Color.BURLYWOOD,    # 6: 青色
	Color.BLUE_VIOLET,    # 7
	Color.PALE_VIOLET_RED,    # 8
	Color.MEDIUM_TURQUOISE  # 9
]

## 根据个位数获取颜色的函数
func get_color_by_last_digit(num: int) -> Color:
	# 获取个位数（取绝对值）
	var last_digit = abs(num) % 10
	# 返回对应的颜色
	return digit_colors[last_digit]
