extends Character


class_name Player


signal start_shovel()
signal end_shovel()


var is_shoveling:bool = false


@onready var shovel = %Shovel
@onready var camera:Camera3D = $Camera3D
@onready var controller:PlayerController = $PlayerController



func _input(event):
	if Input.is_action_just_pressed(PlayerActions.SHOVEL):
		_start_shoveling()
	
	if Input.is_action_just_released(PlayerActions.SHOVEL):
		_end_shoveling()


func _physics_process(delta):
	velocity = controller.process_velocity(delta)
	
	var horizontal_velocity:Vector3 = Vector3(velocity.x, 0, velocity.z)
	if not horizontal_velocity.is_zero_approx():
		look_at(global_position - horizontal_velocity)
	
	move_and_slide()


func _start_shoveling() -> void:
	if is_shoveling: return
	
	is_shoveling = true
	start_shovel.emit()


func _end_shoveling() -> void:
	if not is_shoveling: return
	
	is_shoveling = false
	end_shovel.emit()
