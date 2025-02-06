extends Character


class_name Player


signal start_shovel()
signal end_shovel()
signal dump_shovel(direction)

const SIDE_OFFSET:float = 0.6


var is_shoveling:bool = false
var is_dumping:bool = false
var shovel_side:Vector3 = Vector3.LEFT


@onready var shovel_root:Node3D = %ShovelRoot
@onready var shovel:Shovel = %Shovel
@onready var camera:PlayerCamera = $Camera3D
@onready var controller:PlayerController = $PlayerController


func _ready() -> void:
	shovel.dump_completed.connect(_on_dump_complete)


func _input(event):
	var camera_position_2D: = Vector2(camera.global_position.x, camera.global_position.z)
	var player_position_2D = Vector2(global_position.x, global_position.z)
	var direction_2D: = camera_position_2D.direction_to(player_position_2D)
	var forward_2D: = Vector2(global_basis.z.x, global_basis.z.z)
	
	var facing_with_camera:bool = forward_2D.dot(direction_2D) < 0
	
	if Input.is_action_just_pressed(PlayerActions.SHOVEL_RIGHT):
		shovel_side = Vector3.RIGHT if facing_with_camera else Vector3.LEFT
		_update_shovel_position()
		#var direction: = Vector3.RIGHT if rotation_degrees.y > 0 else Vector3.LEFT
		#_start_dumping(direction)
	
	if Input.is_action_just_pressed(PlayerActions.SHOVEL_LEFT):
		shovel_side = Vector3.LEFT if facing_with_camera else Vector3.RIGHT
		_update_shovel_position()
		#var direction: = Vector3.LEFT if rotation_degrees.y > 0 else Vector3.RIGHT
		#_start_dumping(direction)
	
	if Input.is_action_just_pressed(PlayerActions.SHOVEL):
		_start_shoveling()
	
	if Input.is_action_just_released(PlayerActions.SHOVEL):
		_end_shoveling()
	
	if Input.is_action_just_pressed(PlayerActions.DUMP):
		_start_dumping()


func _physics_process(delta):
	if is_dumping:
		velocity = Vector3.ZERO
	else:
		velocity = controller.process_velocity(delta)
	
	var horizontal_velocity:Vector3 = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() > 1.0:
		look_at(global_position - horizontal_velocity)
	
	move_and_slide()


func _update_shovel_position() -> void:
	shovel_root.position.x = shovel_side.x * SIDE_OFFSET


func _start_shoveling() -> void:
	if is_shoveling: return
	
	is_shoveling = true
	start_shovel.emit()


func _end_shoveling() -> void:
	if not is_shoveling: return
	if is_dumping: return
	
	is_shoveling = false
	end_shovel.emit()


func _start_dumping() -> void:
	is_dumping = true
	dump_shovel.emit(shovel_side)


func _on_dump_complete() -> void:
	is_dumping = false
	is_shoveling = false
	end_shovel.emit()
