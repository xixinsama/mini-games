extends ParallaxBackground

@onready var space_layer = $SpaceLayer
@onready var far_star_layer = $FarStarLayer
@onready var close_star_layer = $CloseStarLayer

func _process(delta):
	space_layer.motion_offset.y += 1 * delta
	far_star_layer.motion_offset.y += 5 * delta
	close_star_layer.motion_offset.y += 80 * delta

# 记得开"motion_mirroring"
