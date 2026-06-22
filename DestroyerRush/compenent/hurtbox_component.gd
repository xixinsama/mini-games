## 受击碰撞盒组件，处理受击逻辑，联动stats组件
class_name HurtboxComponent
extends Area2D

# Create the is_invincible boolean
var is_invincible: bool = false :
	# Here we create an inline setter so we can disable and enable collision shapes on
	# the hurtbox when is_invincible is changed.
	# 在这里我们创建一个内联设置器，以便当 is_invincible 发生变化时
	# 我们可以禁用和启用 hurtbox 上的碰撞形状。
	set(value):
		is_invincible = value
		# Disable any collisions shapes on this hurtbox when it is invincible
		# And reenable them when it isn't invincible
		# 当此伤害箱处于无敌状态时，禁用其上的任何碰撞形状，
		# 当其不再处于无敌状态时，重新启用它们
		for child in get_children():
			if not child is CollisionShape2D and not child is CollisionPolygon2D: continue
			# Use call deferred to make sure this doesn't happen in the middle of the
			# physics process
			# 使用延迟调用来确保这种情况不会在物理过程的中间发生
			child.set_deferred("disabled", is_invincible)

# Create a signal for when this hurtbox is hit by a hitbox
signal hurt(hitbox)
