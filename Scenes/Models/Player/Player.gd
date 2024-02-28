extends CharacterBody3D

@onready var level_node = get_tree().current_scene

@export var normal_speed = 4
@export var sprint_speed = 10.0
@export var slow_speed = 2.5
var slowed = false
var current_speed = normal_speed

@export var jump_impulse = 7
@export var fall_accelaration = 75.0

var no_movement = false

var look_at_to = Vector3.ZERO
var is_in_air = false

var angular_accelaration = 7
var direction = Vector3.ZERO
var last_directions : Array = [direction]

var collider = null
@onready var original_laser_scale_z = $Frog/RayCast3D/Pivot/Tongue.mesh.size.z

@onready var audio_player = $AudioStreamPlayer3D

func _ready():
	Global.player = self

func _process(delta):
	
	if Input.is_action_just_pressed("ability_one"):
		if %RayCast3D.get_collider() != null:
			
			collider = %RayCast3D.get_collider()
			var distance_math_sum = self.global_position.distance_to(collider.global_position)
			print (distance_math_sum)
			var adjusted_scale = distance_math_sum / original_laser_scale_z
			
			$Frog/RayCast3D/Pivot.scale.z = adjusted_scale
			$Frog/RayCast3D/Pivot.visible = !$Frog/RayCast3D/Pivot.visible
	
	_player_movement(delta)


func _player_movement(delta):
	if Input.is_action_pressed("sprint") and is_on_floor() and !slowed:
		current_speed = sprint_speed
	elif is_on_floor() and !slowed:
		current_speed = normal_speed
	
	if Input.is_action_pressed("move_forward") || Input.is_action_pressed("move_back") || Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
		direction = Vector3(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0, Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")).normalized()
		
		if last_directions.size() < 15:
			last_directions.insert(0, direction)
		else:
			last_directions.pop_back()
			last_directions.insert(0, direction)
	else:
		current_speed = 0
		
		
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if is_on_floor() and Input.is_action_pressed("jump"):
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
		#current_speed = normal_speed
