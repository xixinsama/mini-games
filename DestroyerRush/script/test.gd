extends Node2D
@onready var timer_2: Timer = $Timer2
@onready var timer: Timer = $Timer
@onready var spawner_component: SpawnerComponent = $SpawnerComponent


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var xiaoluo : Bullet
	timer.timeout.connect(luoruixin)
	timer_2.timeout.connect(son_luoruixin)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func luoruixin() :
	var luo: Bullet
	luo = spawner_component.spawn(Vector2(160,900),self,0)
	luo.name = "luorui"
	luo.velocity = Vector2(50,0)
	timer_2.start()

func son_luoruixin():
	var luo: Bullet
	luo=get_node("luorui");
	var bullet_luo_son1 : Bullet = spawner_component.spawn(luo.global_position,self,0)
	bullet_luo_son1.velocity = Vector2(-50,-50)
	var bullet_luo_son2 : Bullet = spawner_component.spawn(luo.global_position,self,0)
	bullet_luo_son2.velocity = Vector2(0,-50)
	var bullet_luo_son3 : Bullet = spawner_component.spawn(luo.global_position,self,0)
	bullet_luo_son3.velocity = Vector2(50,-50)
