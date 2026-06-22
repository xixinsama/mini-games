extends TextureProgressBar


@export var enemy_stats: StatsComponent

# 敌人具有多层血量
# 循环使用每一个血量条
@onready var bar_2: TextureProgressBar = $Bar2
@onready var bar_3: TextureProgressBar = $Bar2/Bar3

# 血条染色变量
var layer: int # 总血量层数
var layer_times: int = 1 # 当前血量层数

func _ready():
	await get_tree().create_timer(0.1).timeout
	# 先计算要多少层血
	layer = floor(enemy_stats.health_max / max_value) + 1
	# 初始化血条,第一条血量额外突出
	# 第一条血量等于多出的加上100（未做）
	self.set_value_no_signal(enemy_stats.health_max - max_value * (layer - layer_times))
	bar_2.set_value_no_signal(bar_2.max_value) 
	bar_3.set_value_no_signal(bar_3.max_value)
	# 绑定信号，当血量变动时改变血条
	enemy_stats.health_changed.connect(update_bars.unbind(2))
	update_bars()

func update_bars():
	# 即时更新 Over 层 (直接掉血)
	# 归化到100之内
	#print(layer)
	#print(layer_times)
	var target_health: int = enemy_stats.health - max_value * (layer - layer_times)
	# 记录特殊的第一次
	if layer_times == 1:
		var over_health: int = target_health
		if enemy_stats.health_max - enemy_stats.health >= over_health:
			layer_times += 1
	else:
		# 记录layer_times
		if target_health <= 0:
			layer_times += 1
	if layer_times % 3 == 1:
		# 则当前最上层为bar1
		# 设置渲染次序
		self.set_z_index(0)
		bar_2.set_z_index(-1)
		bar_3.set_z_index(-2)
		# 更新血量
		self.set_value_no_signal(target_health)
		create_tween().tween_property(bar_2, "value", target_health, 0.3)
		create_tween().tween_property(bar_3, "value", max_value, 0.1)
	elif layer_times % 3 == 2:
		# 当前层为bar3
		# 设置渲染次序
		self.set_z_index(-1)
		bar_2.set_z_index(-2)
		bar_3.set_z_index(0)
		# 更新血量
		bar_3.set_value_no_signal(target_health)
		create_tween().tween_property(self, "value", target_health, 0.3)
		create_tween().tween_property(bar_2, "value", max_value, 0.1)
	elif layer_times % 3 == 0:
		# 当前层为bar2
		# 设置渲染次序
		self.set_z_index(-2)
		bar_2.set_z_index(0)
		bar_3.set_z_index(-1)
		# 更新血量
		bar_2.set_value_no_signal(target_health)
		create_tween().tween_property(bar_3, "value", target_health, 0.3)
		create_tween().tween_property(self, "value", max_value, 0.1)
	else:
		print("在敌人血条发生了奇怪的错误：", layer_times)
		return
