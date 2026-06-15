extends Node2D
class_name DrawPortalLine

var portal_line: Array = []
var walk_path: Array = []

func _ready() -> void:
	portal_line.clear()

func _draw() -> void:
	for i in range(portal_line.size() - 1):
		draw_dashed_line(portal_line[i],
				portal_line[i+1], 
				Color(0.11764706, 0.5647059, 1, 0.6)
			, 2, 5)
	if walk_path.size() >= 2:
		draw_polyline(walk_path, Color(0.6784314, 1, 0.18431373, 0.6), 2)
