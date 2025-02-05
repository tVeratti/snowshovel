extends Character


class_name Player


signal start_shovel()
signal end_shovel()
signal dump_shovel(direction)


var is_shoveling:bool = false
var is_dumping:bool = false


@onready var shovel_root:Node3D = %ShovelRoot
@onready var shovel:Shovel = %Shovel
@onready var camera:Camera3D = $Camera3D
@onready var controller:PlayerController = $PlayerController



func _input(event):
	if Input.is_action_just_pressed(PlayerActions.SHOVEL):
		_start_shoveling()
	
	if Input.is_action_just_released(PlayerActions.SHOVEL):
		_end_shoveling()
	
	if Input.is_action_just_pressed(PlayerActions.DUMP_LEFT):
		pass
		
	if Input.is_action_just_pressed(PlayerActions.DUMP_RIGHT):
		dump_shovel.emit(Vector3.RIGHT)
	
	if Input.is_action_just_pressed(PlayerActions.DUMP_LEFT):
		dump_shovel.emit(Vector3.LEFT)


func _physics_process(delta):
	if is_dumping:
		velocity = Vector3.ZERO
	else:
		velocity = controller.process_velocity(delta)
	
	var horizontal_velocity:Vector3 = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() > 1.0:
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
