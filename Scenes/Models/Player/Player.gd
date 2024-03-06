extends CharacterBody3D

@onready var level_node = get_tree().current_scene
@onready var audio_player = $AudioStreamPlayer3D
@onready var frog_pivot = $Frog/Pivot

#TIMERS

@onready var time_until_in_air_timer = $TimeUntilInAir
@onready var no_movement_timer = $NoMovementTimer
@onready var slow_timer = $SlowTimer
@onready var ability_one_cooldown = $AbilityOneCooldown
@onready var ability_two_cooldown = $AbilityTwoCooldown

#MOVEMENT

const NORMAL_SPEED = 4
const SPRINT_SPEED = 6
const SLOW_SPEED = 2
var current_speed = NORMAL_SPEED
var slowed = false

var jump_impulse = 10
var fall_accelaration = 40

var is_in_air = false

var no_movement = false

var angular_accelaration = 7

var direction = Vector3.ZERO
var last_directions : Array = [direction]


#ABILITY ONE

var ability_one_activated = false
var can_use_ability_one = true

var collider = null
var distance_math_sum
var adjusted_scale

var original_tongue_scale_z = 5
var retract = false

#ABILITY TWO

var ability_two_jump_impulse = jump_impulse * 1.25
var ability_two_jump = false
var can_use_ability_two = true
var ability_two_charges = 2

func _ready():
	Global.player = self


func _process(delta):
	_player_movement(delta)
	
	_ability_one_tongue(delta)
	_vision_area_scanner()

func _input(event):
	if is_on_floor() and event.is_action_pressed("jump") and !slowed:
		_capture_jump_input()
	
	if is_on_floor() and event.is_action_pressed("ability_two") and can_use_ability_two:
		_ability_two()
	
	if ability_one_activated == false and retract == false and can_use_ability_one and event.is_action_pressed("ability_one"):
		_ability_one()
	
	if event.is_action_pressed("attack") and is_on_floor():
		_capture_attack_input()

func _player_movement(delta):
	_update_current_speed()
	_capture_movement_input()
	_update_velocity(delta)
	_apply_movement()
	_update_player_rotation(delta)


func _update_current_speed():
	if Input.is_action_pressed("sprint") and is_on_floor() and !slowed:
		current_speed = SPRINT_SPEED
	elif is_on_floor() and !slowed:
		current_speed = NORMAL_SPEED


func _capture_movement_input():
	var move_input_vector = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		0, 
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
		).normalized()
	
	if move_input_vector.length() > 0:
		direction = move_input_vector
		
		last_directions.insert(0, direction)
		if last_directions.size() > 15:
			last_directions.pop_back()
	else:
		direction = Vector3.ZERO


func _capture_jump_input():
	jump_impulse = 10
	velocity.y = jump_impulse
	time_until_in_air_timer.stop()
	time_until_in_air_timer.start()
	_play_fart_noise()


func _play_fart_noise():
	if randi() % 100 == 0:
		audio_player.pitch_scale = randf_range(0.5, 1.25)
		audio_player.play()


func _update_velocity(delta):
	velocity.y -= fall_accelaration * delta
	if !ability_two_jump:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	elif is_in_air and is_on_floor():
		ability_two_jump = false


func _capture_attack_input():
	no_movement = true
	no_movement_timer.stop()
	no_movement_timer.start()


func _apply_movement():
	if is_on_floor() and is_in_air == true:
		is_in_air = false
		slowed = true
		current_speed = SLOW_SPEED
		slow_timer.stop()
		slow_timer.start()
	elif !no_movement or !is_on_floor() or current_speed == SPRINT_SPEED:
		move_and_slide()


func _update_player_rotation(delta):
	global_rotation.x = 0
	self.rotation.y = lerp_angle(self.rotation.y, atan2(-last_directions[-1].x, -last_directions[-1].z), delta * angular_accelaration)

func _on_no_movement_timer_timeout():
	no_movement = false


func _on_time_until_in_air_timeout():
	is_in_air = true


func _on_slow_timer_timeout():
	slowed = false


func _ability_one():
	if %RayCast3D.get_collider() != null:
		collider = %RayCast3D.get_collider()
		if collider.is_in_group("Enemy"):
			if self.global_position.distance_to(collider.global_position) > 1 and collider.current_health > 0:
				ability_one_activated = true
				can_use_ability_one = false
				frog_pivot.scale.z = 0
				frog_pivot.visible = true
				no_movement = true
				
				ability_one_cooldown.start()
	
	

func _ability_one_tongue(delta):
	if frog_pivot.scale.z > 0.01 and retract:
		frog_pivot.scale.z -= 2.5 * delta
		ability_one_activated = false
	else:
		retract = false
	
	if ability_one_activated and collider != null:
		distance_math_sum = self.global_position.distance_to(collider.global_position)
		adjusted_scale = distance_math_sum / original_tongue_scale_z
		
		if frog_pivot.scale.z < adjusted_scale - 0.05:
			frog_pivot.scale.z += 2.5 * delta
			
			frog_pivot.look_at(Vector3(collider.global_position.x, 1, collider.global_position.z), Vector3.UP)
		else:
			if collider.is_in_group("Enemy"):
				collider.take_damage(30)
				no_movement = false
			retract = true

func _vision_area_scanner():
	var overlaps = $Frog/VisionArea.get_overlapping_bodies()
	var closest_enemy = null
	var closest_distance = INF
	
	
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("Enemy"):
				var distance = self.global_position.distance_to(overlap.global_position)
				
				if (closest_enemy == null or distance < closest_distance):
					closest_enemy = overlap
					closest_distance = distance
				else:
					closest_enemy = null
				
				if closest_enemy != null:
					%RayCast3D.look_at(Vector3(closest_enemy.global_position.x, 1, closest_enemy.global_position.z), Vector3.UP)


func _on_ability_one_cooldown_timeout():
	can_use_ability_one = true


func _ability_two():
	ability_two_charges -= 1
	if ability_two_charges == 0:
		can_use_ability_two = false
	
	var forward_direction = -last_directions[-1]
	var upward_force = Vector3(0, ability_two_jump_impulse, 0)
	var forward_force = -forward_direction * jump_impulse
	
	velocity += upward_force + forward_force
	
	ability_two_jump = true 
	
	time_until_in_air_timer.stop()
	time_until_in_air_timer.start()
	
	ability_two_cooldown.start()


func _on_ability_two_cooldown_timeout():
	ability_two_charges += 1
	can_use_ability_two = true
