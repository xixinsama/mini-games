extends State
class_name Attack3

@export var dia: Label

func Enter():
	var random_dia = randi_range(0, 2)
	if random_dia == 0:
		dia.text = "didn't lose anything by waiting"
	if random_dia == 1:
		dia.text = "wish farewell"
	if random_dia == 2:
		dia.text = "Worthy opponent"
	await get_tree().create_timer(0.3).timeout
	dia.text = " "
	Transitioned.emit(self, "EnemyIdle")
