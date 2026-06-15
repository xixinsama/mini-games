extends TextureButton

# 动画参数
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)  # 悬停时放大倍数
@export var press_scale: Vector2 = Vector2(0.95, 0.95)  # 按下时缩小倍数
@export var animation_duration: float = 0.15  # 动画持续时间（秒）
@export var use_tween: bool = true  # 是否使用Tween进行动画

var original_scale: Vector2 = Vector2.ONE
var original_pivot_offset: Vector2
var tween: Tween

func _ready():
	# 保存原始尺寸和中心点
	original_scale = scale
	original_pivot_offset = pivot_offset
	
	# 确保按钮可以接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

# 鼠标悬停时放大
func _on_mouse_entered():
	if disabled:
		return
	
	if use_tween:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", hover_scale, animation_duration)
	else:
		scale = hover_scale

# 鼠标离开时恢复
func _on_mouse_exited():
	if disabled:
		return
	
	if use_tween:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", original_scale, animation_duration)
	else:
		scale = original_scale

# 鼠标按下时缩小
func _on_button_down():
	if disabled:
		return
	
	# 添加轻微的按下音效（可选）
	# $ClickSound.play()
	
	if use_tween:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(self, "scale", press_scale, animation_duration*0.7)

# 鼠标释放时恢复
func _on_button_up():
	if disabled:
		return
	
	if use_tween:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		# 根据鼠标是否还在按钮上决定恢复的目标尺寸
		var target_scale = hover_scale if is_hovered() else original_scale
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", target_scale, animation_duration)

# 添加一个点击音效功能（可选）
func add_click_sound(sound_stream: AudioStream):
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sound_stream
	audio_player.bus = "SFX"
	add_child(audio_player)
	
	# 修改按下和释放方法，在按下时播放音效
	# 注意：需要移除原来的信号连接并重新连接

# 便捷函数：快速应用预设效果
static func apply_preset(button: TextureButton, preset_name: String = "default"):
	var script = load("res://path_to_this_script.gd")
	button.set_script(script)
	
	match preset_name:
		"subtle":
			button.hover_scale = Vector2(1.05, 1.05)
			button.press_scale = Vector2(0.98, 0.98)
			button.animation_duration = 0.1
		"bouncy":
			button.hover_scale = Vector2(1.15, 1.15)
			button.press_scale = Vector2(0.9, 0.9)
			button.animation_duration = 0.2
		"default":
			pass  # 使用默认值
