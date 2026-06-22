## 生成子节点
class_name SpawnerComponent
extends Node2D

# Export the dependencies for this component
# The scene we want to spawn
@export var scene: PackedScene


# 在全局位置下生成一个节点
# 生成的子节点可在第二个输入中选择，默认主场景
# 激光类的可以直接挂在目标节点上
func spawn(global_spawn_position: Vector2 = global_position, parent: Node = get_tree().current_scene, flag: int = 0) -> Node:
	assert(scene is PackedScene, "Error: The scene export was never set on this spawner component.")
	# Instance the scene
	var instance = scene.instantiate()
	# Add it as a child of the parent
	parent.add_child(instance)
	# Update the global position of the instance.
	# (This must be done after adding it as a child)
	instance.global_position = global_spawn_position
	
	# 将参数传递给子弹的脚本
	if instance.has_method("initialize"):
		instance.initialize(flag)
	
	# Return the instance in case we want to perform any other operations
	# on it after instancing it.
	return instance
