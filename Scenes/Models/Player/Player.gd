extends CharacterBody3D

@onready var level_node = get_tree().current_scene

@export var normal_speed = 5.0
@export var sprint_speed = 10.0
var current_speed = normal_speed

@export var jump_impulse = 5
@export var fall_accelaration = 75.0

var rotation_speed = 60

var look_at_mouse = false
var enemy_position = null
var enemy_look_at = false
var no_movement = false

var current_rotation_y

func _process(delta):
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("sprint") and !Input.is_action_pressed("jump") and is_on_floor():
		current_speed = sprint_speed
	elif is_on_floor():
		current_speed = normal_speed
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
		
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = jump_impulse
	
	velocity.y -= fall_accelaration * delta
	
	if look_at_mouse == false:
		current_rotation_y = global_rotation.y
	
	if Input.is_action_just_pressed("attack"):
		look_at(level_node.screen_point_to_ray(), Vector3.UP)
		no_movement = true
		$NoMovementTimer.stop()
		$NoMovementTimer.start()
	elif direction != Vector3.ZERO and !no_movement:
		#smooth rotation
		self.rotation.y = lerp_angle(self.rotation.y, atan2( -direction.x , -direction.z), delta * rotation_speed)
		
		#hard rotation
		#look_at(position + direction, Vector3.UP)
	
	if !no_movement or !is_on_floor() or current_speed == sprint_speed:
		move_and_slide()
	
	global_rotation.x = 0


func _on_no_movement_timer_timeout():
	no_movement = false
