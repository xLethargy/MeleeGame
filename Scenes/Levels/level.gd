extends Node3D

@onready var camera = %MainCamera


var collider = null
var last_looked_position = Vector3()

func screen_point_to_ray():
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position() #finds mouse location
	
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 2000
	
	var ray_array = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1))
	
	if ray_array.has("position"):
		last_looked_position = ray_array["position"]
		return ray_array["position"]
	return Vector3()


func _on_frog_ability_two_bomb(pos):
	pass
