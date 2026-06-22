extends Label

@export var stats_component: StatsComponent

# 血条显示百分比
func _on_stats_component_health_changed(_HP_before: int, _HP_now: int) -> void:
	var health_percent: float = 100 * float(stats_component.health) / float(stats_component.health_max)
	text = "%.1f" % health_percent + "%"
