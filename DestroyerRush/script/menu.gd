extends Control

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var ALL_h_slider: HSlider = $CenterContainer/VSplitContainer/SettingContainer/ALL/HSlider
@onready var BGM_h_slider: HSlider = $CenterContainer/VSplitContainer/SettingContainer/BGM/HSlider
@onready var SFX_h_slider: HSlider = $CenterContainer/VSplitContainer/SettingContainer/SFX/HSlider
@onready var ALL_check_box: CheckBox = $CenterContainer/VSplitContainer/SettingContainer/ALL/CheckBox
@onready var BGM_check_box: CheckBox = $CenterContainer/VSplitContainer/SettingContainer/BGM/CheckBox
@onready var SFX_check_box: CheckBox = $CenterContainer/VSplitContainer/SettingContainer/SFX/CheckBox
@onready var BG_check_button: CheckButton = $CenterContainer/VSplitContainer/SettingContainer/Background/CheckButton
@onready var check_button: CheckButton = $CenterContainer/VSplitContainer/SettingContainer/Background/CheckButton

@onready var animated_sprite_2d_3: AnimatedSprite2D = $Node2D/AnimatedSprite2D3
@onready var animated_sprite_2d_4: AnimatedSprite2D = $Node2D/AnimatedSprite2D4
@onready var animated_sprite_2d_5: AnimatedSprite2D = $Node2D/AnimatedSprite2D5

#var text = "ABCDEFGHIJKLMNOPQRST"
#var max_jump_height = 20  # 跳动的最大高度
#var tween: Tween = create_tween().set_loops() ##无限循环

func _unhandled_input(event: InputEvent) -> void:
 	# 如果按下Esc，退出游戏
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _ready():
	ALL_h_slider.value_changed.connect(_on_ALL_value_changed)
	BGM_h_slider.value_changed.connect(_on_BGM_value_changed)
	SFX_h_slider.value_changed.connect(_on_SFX_value_changed)
	#var x_offset = 0
	#for i in range(text.length()):
		#var char = text[i]
#
		## 创建一个Label节点显示每个字母
		#var label = Label.new()
		#label.name = "jumping" + str(i)
		#label.text = char
		#label.position = Vector2(x_offset, 0)
		#label.label_settings = preload("res://fonts/jump_label.tres")
		#add_child(label)
#
		## 设置一个随机的跳动时间
		#var jump_time = randf_range(0.3, 0.6)
#
		## 添加跳动动画
		#tween.tween_property(label, "scale", Vector2(1.2, 1.2), jump_time).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
		#tween.tween_property(label, "position", label.position + Vector2(0, max_jump_height), jump_time).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
		#tween.tween_callback(jump.bind(label))
		#tween.tween_interval(0.1)
#
		#x_offset += label.size.x + 5  # 字母之间的间隔

func _process(_delta: float) -> void:
	#点击空格开始
	if Input.is_action_just_pressed("skill") or Input.is_action_just_pressed("roll"):
		if audio_stream_player.is_playing(): return #防止多次按键
		audio_stream_player.play()
		await audio_stream_player.finished
		var InventoryScene: PackedScene = preload("res://Levels/level_2.tscn")
		#Transitions.change_scene_to_instance(InventoryScene.instantiate(), 
		#Transitions.FadeType.CrossFade)
		Status.scene_into(InventoryScene)

#func jump(label: Label) -> void:
	#var jump_time = 0.2
	#var tween_label = create_tween()
	#tween_label.tween_property(label, "scale", Vector2(1.2, 1.2), jump_time).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	#tween_label.tween_property(label, "position", label.position - Vector2(0, 10), jump_time).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	#tween_label.tween_property(label, "position", label.position, jump_time).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)

func _on_ALL_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)
func _on_BGM_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, value)
func _on_SFX_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, value)
func _on_ALL_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, not toggled_on)
	if animated_sprite_2d_3.frame == 1:
		animated_sprite_2d_3.frame = 0
	else:
		animated_sprite_2d_3.frame = 1
func _on_BGM_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(1, not toggled_on)
	if animated_sprite_2d_4.frame == 1:
		animated_sprite_2d_4.frame = 0
	else:
		animated_sprite_2d_4.frame = 1
func _on_SFX_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(2, not toggled_on)
	if animated_sprite_2d_5.frame == 1:
		animated_sprite_2d_5.frame = 0
	else:
		animated_sprite_2d_5.frame = 1
	

func _on_Background_check_button_toggled(toggled_on: bool) -> void:
	SpaceBackground.visible = toggled_on
func _on_color_picker_button_color_changed(color: Color) -> void:
	RenderingServer.set_default_clear_color(color)
