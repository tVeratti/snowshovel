extends CharacterBody3D


class_name Character


@onready var controller:PlayerController = $PlayerController


func _physics_process(delta):
	velocity = controller.process_velocity(delta)
	
	var horizontal_velocity:Vector3 = Vector3(velocity.x, 0, velocity.z)
	if not horizontal_velocity.is_zero_approx():
		look_at(global_position - horizontal_velocity)
	
	move_and_slide()
