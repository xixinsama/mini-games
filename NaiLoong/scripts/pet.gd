extends Area2D
class_name Pet

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: RichTextLabel = $CanvasLayer/NameLabel
@onready var dialogue: RichTextLabel = $CanvasLayer/Dialogue

var _hide_timer: SceneTreeTimer
var _anim_version: int = 0

func _ready():
	DeepSeekClient.response_received.connect(_on_ai_response)
	DeepSeekClient.error_occurred.connect(_on_ai_error)
	dialogue.visible_characters = 0

func _on_ai_response(response: String):
	print("AI: ", response)
	_cancel_hide_timer()
	_anim_version += 1
	dialogue.text = response
	animate_text(response, _anim_version)

func _on_ai_error(error_msg: String):
	print("AI Error: ", error_msg)
	_cancel_hide_timer()
	_anim_version += 1
	dialogue.visible_characters = -1
	dialogue.text = "唔...奶龙走神了~ 等下再说吧！"
	_schedule_hide(dialogue.text)

func animate_text(text: String, version: int):
	dialogue.visible_characters = 0
	dialogue.text = text
	for i in len(text):
		if version != _anim_version:
			return
		dialogue.visible_characters += 1
		await get_tree().create_timer(0.02).timeout
	# Only schedule hide if this animation is still current
	if version != _anim_version:
		return
	_schedule_hide(text)

func _schedule_hide(text: String):
	_cancel_hide_timer()
	var text_len = float(text.length())
	var duration = clamp(text_len * 0.08, 3.0, 15.0)
	_hide_timer = get_tree().create_timer(duration)
	_hide_timer.timeout.connect(_hide_dialogue)

func _hide_dialogue():
	dialogue.visible_characters = 0
	dialogue.text = ""

func _cancel_hide_timer():
	if _hide_timer and _hide_timer.time_left > 0:
		_hide_timer.timeout.disconnect(_hide_dialogue)

func _on_mouse_entered() -> void:
	name_label.visible = true

func _on_mouse_exited() -> void:
	name_label.visible = false

func anime_play(name: String, dir: Vector2) -> void:
	animated_sprite_2d.play(name)
	if dir.x < 0:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false
