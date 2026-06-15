extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_anime(anime: StringName):
	animation_player.play(anime)
	await animation_player.animation_finished
	animation_player.play("RESET")
