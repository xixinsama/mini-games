extends Node
# 全局脚本
# 记录操作数和关卡用时
# 计时从第一步开始

var setps: int = 0
var used_time: float = 0
var start_time: float = 0
var end_time: float = 0

# 增加步数的函数（在玩家操作时调用）
func increment_steps():
	setps += 1
	# 当步数变为1时开始计时
	if setps == 1:
		start_time = Time.get_ticks_msec() / 1000.0  # 转换为秒
	
	# 实时更新用时
	update_used_time()

# 更新已用时间（在需要时调用）
func update_used_time():
	if start_time > 0:  # 已开始计时
		used_time = Time.get_ticks_msec() / 1000.0 - start_time
