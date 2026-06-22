class_name bullet_2
extends Node2D

@onready var move_component: MoveComponent = $MoveComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@export_group("Base")
@export var frame : int = 0
@export var velocity: Vector2
@export var roll_velocity: Vector2 = Vector2()
@export_group("Roll")
@export var roll_origin_rad_1:float = 0.0 ##加入旋转的初始角度 旋转弹
@export var roll_vec_rad_1:float = -PI ##加入旋转的角度速度,正是顺时针，负是逆时针 旋转弹
@export var roll_vec_rad_2:float = 0.0 ##加入旋转的角度速度,正是顺时针，负是逆时针 旋转追踪弹
@export var roll_r_1:float = 0.0 ##旋转半径 旋转弹
@export_group("Trail")
@export var speed_trail_1:float = 0.0 ##追踪子弹速度 追踪弹
@export var speed_trail_2:float = 0.0 ##追踪子弹速度 直线追踪弹
@export var trail_pos: Vector2 = Status.player_position ##追踪谁
@export var trail_who: int = 0

func _ready() -> void:
	hitbox_component.hit_hurtbox.connect(queue_free.unbind(1))
	initialize()

func initialize(flag: int = 0) -> void:
	if move_component != null:
		move_component.velocity = velocity
		move_component.roll_velocity = roll_velocity
		move_component.roll_vec_rad_1 = roll_vec_rad_1
		move_component.roll_vec_rad_2 = roll_vec_rad_2
		move_component.roll_r_1 = roll_r_1
		move_component.speed_trail_1 = speed_trail_1
		move_component.speed_trail_2 = speed_trail_2
		move_component.roll_origin_rad_1=roll_origin_rad_1
		move_component.trail_pos = trail_pos
		move_component.trail_who = trail_who
