extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var sword_hitbox = $Hitbox

func _input(event):
	if event.is_action_pressed("attack") and !animation_player.is_playing():
		animation_player.play("slash")
		owner.look_at_mouse = true


func _on_look_at_mouse_disabled():
	owner.look_at_mouse = false
