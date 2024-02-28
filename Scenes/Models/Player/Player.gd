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

func _ready():
	#look_at(Vector3(1, 0, 0), Vector3.UP)
	Global.player = self

func _process(delta):
	
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
	
	velocity.y -= fall_accelaration * delta
	
	if Input.is_action_just_pressed("attack") and is_on_floor():
		no_movement = true
		$NoMovementTimer.stop()
		$NoMovementTimer.start()
	
	#elif direction != Vector3.ZERO and !no_movement:
		#look_at_to = Vector3(position.x, 0, position.z) + Vector3(direction.x, 0, 0)
		#var direction_vector = (look_at_to - position).normalized()
		
		#if abs(direction_vector.dot(Vector3.UP)) < 1 and look_at_to != position:
			#look_at(look_at_to, Vector3.UP)
		
		#look_at(position - -direction, Vector3.UP)
	
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
