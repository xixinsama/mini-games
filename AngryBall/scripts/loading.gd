# loading_screen.gd
extends Control

@onready var loading_label: Label = $VBoxContainer/StateLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var tip_label: Label = $VBoxContainer/TipLabel

var scene_path: String = ""
var loader: ResourceLoader.ThreadLoadStatus
var loading: bool = false

# 可选的加载提示
var tips = [
	"Tip: Aim carefully for maximum destruction!",
	"Refresh the page and play again",
	"If it's lagging, it means your hardware is faulty:(",
	"This game has pitifully few resources(I'm too lazy to bother with it)",
	"The more destruction you cause, the higher your score.",
	"Tip: Don't let the ball fall out of bounds!",
	"I didn't optimize game at all."
]

func _ready():
	get_tree().scene_changed.connect(queue_free)
	loading_label.text = "Click the left mouse button to start."
	# 随机显示一个提示
	if tip_label:
		tip_label.text = "Scene loading may be slow, please wait."

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		tip_label.text = tips[randi() % tips.size()]
		if event.button_index == MOUSE_BUTTON_LEFT and not loading:
			loading_label.text = "loadiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiing"
			load_scene("res://scenes/main.tscn")

## 开始加载场景
func load_scene(path: String):
	scene_path = path
	
	#开始异步加载
	var error = ResourceLoader.load_threaded_request(scene_path, "PackedScene", true)
	if error != OK:
		push_error("Failed to start loading scene: " + scene_path)
		return
	else:
		loading = true
	#var main_scene := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	#get_tree().change_scene_to_packed(main_scene)
	# 开始更新进度
	set_process(true)

func _process(_delta):
	# 获取加载进度
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# 更新进度条
			if progress_bar:
				progress_bar.value = progress[0] * 100
		
		ResourceLoader.THREAD_LOAD_LOADED:
			# 加载完成
			progress_bar.value = 100
			_on_loading_complete()
		
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + scene_path)
			
		
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Invalid resource: " + scene_path)
			set_process(false)

func _on_loading_complete():
	set_process(false)
	loading = false
	
	# 获取加载的场景
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)
	
	if packed_scene:
		# 切换场景
		get_tree().change_scene_to_packed(packed_scene)
	else:
		push_error("Failed to get loaded scene")
