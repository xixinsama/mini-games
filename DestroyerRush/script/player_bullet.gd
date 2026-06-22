extends Node2D


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready():
	# 超出屏幕则删除该节点，但是如果弹幕生成就在外面，则无法清除
	# 建议设置一个 killzone 套在外面一圈 
	#visible_on_screen_notifier_2d.screen_exited.connect(queue_free)
	# 击中消失（信号解绑）
	hitbox_component.hit_hurtbox.connect(queue_free.unbind(1))

func initialize(_flag: int) -> void:
	add_velocity()
	
func add_velocity() -> void:
	move_component.velocity.y -= abs(Status.player_velocity.y / 5)
