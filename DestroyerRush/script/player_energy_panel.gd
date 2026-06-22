extends HBoxContainer

@onready var energy_progress_bar: TextureProgressBar = $EnergyProgressBar

@export var player_stats: StatsComponent

func _ready() -> void:
	player_stats.energy_changed.connect(update_energy.unbind(1)) # 上面有参数就不用信号来传递了
	update_energy()

func update_energy() -> void:
	# 转换为百分比
	var multi_point: float = energy_progress_bar.max_value / player_stats.energy_max
	energy_progress_bar.value = player_stats.energy * multi_point
	# print(energy_progress_bar.value)
