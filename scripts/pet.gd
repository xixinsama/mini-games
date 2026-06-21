extends Area2D
class_name Pet

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $CanvasLayer/NameLabel
@onready var dialogue: RichTextLabel = $CanvasLayer/Dialogue

func _ready():
	DeepSeekClient.response_received.connect(_on_ai_response)
	DeepSeekClient.error_occurred.connect(_on_ai_error)

func _on_ai_response(response: String):
	print("AI: ", response)
	dialogue.text = response
	animate_text(response)

func _on_ai_error(error_msg: String):
	print("AI Error: ", error_msg)
	dialogue.visible_characters = -1
	dialogue.text = "唔...奶龙走神了~ 等下再说吧！"

func animate_text(text: String):
	dialogue.visible_characters = 0
	dialogue.text = text
	for i in len(text):
		dialogue.visible_characters += 1
		await get_tree().create_timer(0.02).timeout

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
