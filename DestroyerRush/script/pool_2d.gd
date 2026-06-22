extends Node


# MIT License
# -----------------------------------------------------------------------
#                       This file is part of:                           
#                     GODOT Polygon 2D Fracture                         
#           https://github.com/SoloByte/godot-polygon2d-fracture          
# -----------------------------------------------------------------------
# Copyright (c) 2021 David Grueneis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.




#!!!----All pooled instances need these 2 things----!!!
#func despawn() -> called when instance is finished
#signal Despawn(self) -> instance emits this signal when finished to let the pool know to despawn it
#-----------------------------------------------------


#if pool is added to scene tree from the editor use this or setup the pool via code later
@export var placed_in_level: bool = false ## 在关卡中设置。如果你要在代码中设置，设置为false
@export var instance_template: PackedScene ## 要实例化的场景
@export var max_amount: int = 0 ## 最大数量
@export var instantiate_new_on_empty: bool = false ##
@export var keep_instances_in_tree: bool = false ## 


#all instances are a child of this node
#所有实例都挂在这个节点下面
@onready var _instance_parent := $Instances


var template : PackedScene
var max_size : int = 0
var instantiate_new : bool = false
var keep_in_tree : bool = false
#if normal clearPool is used 
#-> the pool waits for instances to be despawned before queue free is called on them
var clear_in_process : bool = false


var instances_ready : Array = []
var instances_in_use : Array = []


func _ready() -> void:
	if placed_in_level:
		setup(instance_template, max_amount, true, instantiate_new_on_empty, keep_instances_in_tree)

##  退出
func _exit_tree() -> void:
	clearPoolInstant()


func setup(template : PackedScene, max_size : int, ready_on_start : bool, instantiate_new : bool = false, keep_in_tree : bool = false) -> void:
	self.template = template
	self.max_size = max_size
	self.instantiate_new = instantiate_new
	self.keep_in_tree = keep_in_tree
	
	if ready_on_start:
		fillPool()


func getParent():
	return _instance_parent

## 获取实例
func getInstance():
	if instances_ready.size() <= 0:
		if instantiate_new:
			addSingleInstance()
			var instance = instances_ready.pop_back()
			instances_in_use.push_back(instance)
			if not keep_in_tree:
				_instance_parent.add_child(instance)
			max_size += 1
			return instance
		else:
			return null
	else:
		var instance = instances_ready.pop_back()
		instances_in_use.push_back(instance)
		if not keep_in_tree:
			_instance_parent.add_child(instance)
		return instance

## 填充对象池
func fillPool() -> void:
	if max_size <= 0: return
	var cur_size : int = instances_ready.size() + instances_in_use.size()
	addInstances(max(max_size - cur_size, 0))

## 立即清除对象池
func clearPoolInstant() -> void:
	for instance in instances_in_use:
		instance.queue_free()
	
	for instance in instances_ready:
		if keep_in_tree:
			instance.queue_free()
		else:
			instance.free()


func clearPool() -> void:
	if clear_in_process: return 
	if instances_in_use.size() > 0:
		clear_in_process = true
	
	for instance in instances_ready:
		if keep_in_tree:
			instance.queue_free()
		else:
			instance.free()


func resizePool(amount : int) -> void:
	if amount == 0: return
	if amount > 0:
		max_size += amount
		addInstances(amount)
	else:
		max_size -= min(amount, max_size)
		removeInstances(max_size)

## 根据数量添加实例
func addInstances(amount : int) -> void:
	for i in range(amount):
		addSingleInstance()

## 添加单个实例
func addSingleInstance():
	var instance = template.instantiate()
	instances_ready.push_back(instance)
	if keep_in_tree:
		_instance_parent.add_child(instance)
	instance.Despawn.connect(On_Instance_Despawn)
	return instance


func removeInstances(amount : int) -> void:
	for i in range(abs(amount)):
		if instances_ready.size() > 0:
			var instance = instances_ready.pop_back()
			if keep_in_tree:
				instance.queue_free()
			else:
				instance.free()
		elif instances_in_use.size() > 0:
			var instance = instances_in_use.pop_back()
			instance.queue_free()
		else:
			return

func On_Instance_Despawn(instance) -> void:
	if clear_in_process:
		var index : int = instances_in_use.find(instance)
		if index >= 0:
			instances_in_use.remove_at(index)
			instance.queue_free()
		
			if instances_in_use.size() <= 0:
				clear_in_process = false
	else:
		var index : int = instances_in_use.find(instance)
		if index >= 0:
			instances_in_use.remove_at(index)
			instances_ready.append(instance)
			
			if instance.has_method("despawn"):
				instance.despawn()
			
			if not keep_in_tree:
				_instance_parent.remove_child(instance)
