class_name EnemyIdle
extends State

@export var actor: LeveL

func Enter():
	var rest_timer: Timer = Timer.new()
	rest_timer.wait_time = 4.5 - actor.flag_prase
	rest_timer.name = "rest_timer"
	rest_timer.one_shot = true
	self.add_child(rest_timer)
	rest_timer.timeout.connect(out_state)
	rest_timer.start()

func out_state() -> void:
	var attack_method: int = randi_range(0, actor.flag_prase)
	var attack_name: String = "Attack" + str(attack_method)
	print(attack_name)
	Transitioned.emit(self, attack_name)
