extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var damage_label = $Label3D

var max_health = 100
var current_health = max_health

var normal_speed = 1.5
var sprint_speed = 6
var current_speed = normal_speed

var left = false

var immunity_timer : Timer = Timer.new()
var hit_timer : Timer = Timer.new()

var immune = false
var hits_taken = 0

func _ready():
	immunity_timer.one_shot = true
	immunity_timer.wait_time = 1
	immunity_timer.timeout.connect(_immunity_timer_timeout)
	add_child(immunity_timer)
	
	hit_timer.one_shot = true
	hit_timer.wait_time = 1
	hit_timer.timeout.connect(_hit_timer_timeout)
	add_child(hit_timer)


func _immunity_timer_timeout():
	immune = false
	current_speed = normal_speed

func _hit_timer_timeout():
	hits_taken = 0

func take_damage(amount : int):
	if !immune:
		hit_timer.stop()
		hit_timer.start()
		hits_taken += 1
		if hits_taken == 3 and current_health > 0:
			immune = true
			immunity_timer.start()
			hits_taken = 0
			current_speed = sprint_speed
		
		animation_player.stop()
		animation_player.play("hit")
		
		if amount >= 15:
			damage_label.modulate = Color(0.769, 0.773, 0.22, 1)
		else:
			damage_label.modulate = Color(1, 1, 1, 1)
		
		damage_label.text = str(amount)
		damage_label.show()
		
		current_health -= amount
		print (current_health)
		if current_health <= 0:
			die()

func die():
	await animation_player.animation_finished
	$Meshes/Hurtbox/CollisionShape3D.disabled = true
	animation_player.play("die")
	await animation_player.animation_finished
	queue_free()

func _physics_process(delta):
	if !animation_player.is_playing():
		if !left and position.x >= 5:
			left = true
		elif left and position.x <= -5:
			left = false

		# Move based on the direction indicated by 'left'
		if left:
			position.x -= 1 * current_speed * delta # Move left
		else:
			position.x += 1 * current_speed * delta # Move right
