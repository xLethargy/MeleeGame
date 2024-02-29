extends CharacterBody3D

@onready var level_node = get_tree().current_scene
@onready var original_laser_scale_z = 5
@onready var audio_player = $AudioStreamPlayer3D

var normal_speed = 4
var sprint_speed = 6
var slow_speed = 2
var slowed = false
var current_speed = normal_speed

@export var jump_impulse = 10
@export var fall_accelaration = 40

var no_movement = false

var look_at_to = Vector3.ZERO
var is_in_air = false

var angular_accelaration = 7
var direction = Vector3.ZERO
var last_directions : Array = [direction]

var collider = null

var ability_one = false
var distance_math_sum
var adjusted_scale
var can_use_ability_one = true
var missed_ability_one = false

var left = false

var retract = false

func _ready():
	Global.player = self

func _process(delta):
	_ability_one(delta)
	
	_player_movement(delta)


func _player_movement(delta):
	if Input.is_action_pressed("sprint") and is_on_floor() and !slowed:
		current_speed = sprint_speed
	elif is_on_floor() and !slowed:
		current_speed = normal_speed
	
	if Input.is_action_pressed("move_forward") || Input.is_action_pressed("move_back") || Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
		direction = Vector3(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0, Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")).normalized()
		
		if !is_on_floor() and (current_speed == 0 or slowed):
			current_speed = slow_speed
		
		if last_directions.size() < 15:
			last_directions.insert(0, direction)
		else:
			last_directions.pop_back()
			last_directions.insert(0, direction)
	else:
		current_speed = 0
		
		
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		if current_speed == normal_speed or current_speed == sprint_speed:
			jump_impulse = 10
		else:
			jump_impulse = 7
		velocity.y = jump_impulse
		$TimeUntilInAir.stop()
		$TimeUntilInAir.start()
		
		var fart_random = randi_range(0, 100)
		if fart_random == 100:
			audio_player.pitch_scale = randf_range(0.5, 1.25)
			audio_player.play()
		
	velocity.y -= fall_accelaration * delta
	
	if Input.is_action_just_pressed("attack") and is_on_floor():
		no_movement = true
		$NoMovementTimer.stop()
		$NoMovementTimer.start()
	
	if is_on_floor() and is_in_air == true:
		is_in_air = false
		slowed = true
		current_speed = slow_speed
		$SlowTimer.stop()
		$SlowTimer.start()
	elif !no_movement or !is_on_floor() or current_speed == sprint_speed:
		move_and_slide()
	
	global_rotation.x = 0
	self.rotation.y = lerp_angle(self.rotation.y, atan2(-last_directions[-1].x, -last_directions[-1].z), delta * angular_accelaration)

func _on_no_movement_timer_timeout():
	no_movement = false


func _on_time_until_in_air_timeout():
	is_in_air = true


func _on_slow_timer_timeout():
	var jump_pressed = false
	if Input.is_action_pressed("jump"):
		jump_pressed = true
	
	if jump_pressed == false:
		slowed = false


func _ability_one(delta):
	if $Frog/Pivot.scale.z > 0.01 and retract:
		$Frog/Pivot.scale.z -= 2.5 * delta
		ability_one = false
	else:
		retract = false
	
	
	if ability_one == false and retract == false and can_use_ability_one:
		if Input.is_action_just_pressed("ability_one"):
			if %RayCast3D.get_collider() != null:
				
				collider = %RayCast3D.get_collider()
				
				if collider.is_in_group("Enemy"):
					if self.global_position.distance_to(collider.global_position) > 1 and collider.current_health > 0:
						ability_one = true
						can_use_ability_one = false
						$Frog/Pivot.scale.z = 0
						$Frog/Pivot.visible = true
						no_movement = true
						
						$AbilityOneCooldown.start()
			else:
				$Frog/Pivot.rotation = Vector3(0, 0, 0)
				missed_ability_one = true
				can_use_ability_one = false
				$Frog/Pivot.scale.z = 0
				$Frog/Pivot.visible = true
				no_movement = true
				
				$MissedAbilityOneCooldown.start()
	
	
	if ability_one:
		if collider == null:
			return
		
		distance_math_sum = self.global_position.distance_to(collider.global_position)
		adjusted_scale = distance_math_sum / original_laser_scale_z
		
		if $Frog/Pivot.scale.z < adjusted_scale - 0.05:
			$Frog/Pivot.scale.z += 2.5 * delta
			
			$Frog/Pivot.look_at(Vector3(collider.global_position.x, 1, collider.global_position.z), Vector3.UP)
		else:
			if collider.is_in_group("Enemy"):
				collider.take_damage(30)
				no_movement = false
			retract = true
		
	elif missed_ability_one:
		if $Frog/Pivot.scale.z < 0.5:
			$Frog/Pivot.scale.z += 2.5 * delta
		else:
			no_movement = false
			retract = true
			missed_ability_one = false
			print ("retract")


func _on_vision_timer_timeout():
	var overlaps = $Frog/VisionArea.get_overlapping_bodies()
	var closest_enemy = null
	var closest_distance = INF # Use GDScript's infinity constant as the initial closest distance
	
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("Enemy"):
				var distance = self.global_position.distance_to(overlap.global_position)
				
				if (closest_enemy == null or distance < closest_distance) and overlap.current_health > 0:
					closest_enemy = overlap
					closest_distance = distance
				else:
					closest_enemy = null
				
				if closest_enemy != null:
					%RayCast3D.look_at(Vector3(closest_enemy.global_position.x, 1, closest_enemy.global_position.z), Vector3.UP)
	else:
		closest_enemy = null
	


func _on_ability_one_cooldown_timeout():
	can_use_ability_one = true


func _on_missed_ability_one_cooldown_timeout():
	can_use_ability_one = true
