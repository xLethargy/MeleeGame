extends Area3D
class_name Hitbox

@export var damage = 10

func _init():
	collision_layer = 2
	collision_mask = 0

func random_damage():
	damage = randi_range(7, 20)
	return damage
