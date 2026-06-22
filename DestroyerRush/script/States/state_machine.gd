extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {} # 将所有状态作为该节点的孩子，

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transitioned.connect(_on_child_transition)
	# 初始状态
	if initial_state:
		initial_state.Enter()
		current_state = initial_state
	
func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.Physics_Update(delta)

# 状态转换
func _on_child_transition(state, new_state_name):
	if state != current_state:
		return
	# 在子节点中找新状态，如果没有就返回
	var new_state: State = states.get(new_state_name.to_lower())
	if !new_state:
		return
	
	# 退出当前状态，进入新状态
	if current_state:
		current_state.Exit()
	new_state.Enter()
	current_state = new_state
