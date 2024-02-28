extends Area3D
class_name Hurtbox

var give_player_details = false
var player

var timer : Timer = Timer.new()

func _init():
	collision_layer = 0
	collision_mask = 2

func _ready():
	connect("area_entered", self._on_area_entered)


func _on_area_entered(hitbox : Hitbox):
	if hitbox == null:
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.random_damage())
	
	if hitbox.owner.owner.is_in_group("Player"):
		player = hitbox.owner.owner
