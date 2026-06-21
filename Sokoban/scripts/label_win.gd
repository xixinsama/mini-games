extends Label

@export var game_manager: GameManager  # 在编辑器中拖拽GameManager节点到这里

func _ready() -> void:
	game_manager.youwin.connect(show_message)

func show_message():
	show()
	Records.end_time = Time.get_ticks_msec() / 1000.0
