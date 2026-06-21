extends Label

func _process(delta: float) -> void:
	text = tr("STEP") + str(Records.setps) + "\n" \
	+ tr("TIME") + str(Records.used_time)
