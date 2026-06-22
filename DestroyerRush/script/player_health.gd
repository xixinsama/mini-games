extends Control


@export var player_stats: StatsComponent
@onready var spawner_component: SpawnerComponent = $SpawnerComponent

func _ready() -> void:
	player_stats.health_changed.connect(update_health)
	update_health(0, player_stats.health_max)

func update_health(HP_before, HP_now) -> void:
	if HP_before < HP_now:
		# 生成血量
		for i in HP_now - HP_before:
			var node = spawner_component.spawn(Vector2(24+40*(i+HP_before), 24), self)
			node.get_node("AnimationPlayer").play("generate")
	elif HP_before > HP_now:
		# 扣除血量
		for i in HP_before - HP_now:
			# 如果还有加血的敌方，可能序号就变了？
			var node_ani = self.get_child(HP_before)
			#print(get_child_count())
			#print(get_children())
			if node_ani != AnimationPlayer or node_ani != null: # 哎呀，求菩萨保佑
				node_ani.get_node("AnimationPlayer").play("deduction")
			else:
				return
