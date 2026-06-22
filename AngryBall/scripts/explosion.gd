extends Node3D

@onready var debris: GPUParticles3D = $Debris
@onready var smoke: GPUParticles3D = $Smoke
@onready var fire: GPUParticles3D = $Fire
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func explode() -> void:
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	audio_stream_player_3d.play()
	await get_tree().create_timer(2.0).timeout
	queue_free()
