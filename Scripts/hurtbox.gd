extends Area3D
class_name Hurtbox

var give_player_details = false
var player

var timer : Timer = Timer.new()

func _init():
	collision_layer = 0
	collision_mask = 2

func _process(delta):
	if give_player_details:
		player.enemy_position = self.global_position
		player.enemy_look_at = true

func _ready():
	connect("area_entered", self._on_area_entered)
	timer.one_shot = true
	timer.wait_time = 0.3
	timer.timeout.connect(_timer_timeout)
	add_child(timer)


func _on_area_entered(hitbox : Hitbox):
	if hitbox == null:
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.random_damage())
	
	if hitbox.owner.owner.is_in_group("Player"):
		player = hitbox.owner.owner
		give_player_details = true
		
		timer.stop()
		timer.start()

func _timer_timeout():
	give_player_details = false
	player.enemy_look_at = false
