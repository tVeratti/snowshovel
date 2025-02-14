extends Character


class_name Player


signal start_shovel()
signal end_shovel()
signal dump_shovel(direction)
signal step()

const SIDE_OFFSET:float = 0.7


@export var step_audio:Array[AudioStream] = []


var is_shoveling:bool = false
var is_dumping:bool = false
var shovel_side:Vector3 = Vector3.LEFT
var snow_height:float = 0.0


@onready var mesh_root:Node3D = %MeshRoot
@onready var shovel_root:Node3D = %ShovelRoot
@onready var shovel:Shovel = %Shovel
@onready var camera:PlayerCamera = $Camera3D
@onready var controller:PlayerController = $PlayerController
@onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer
@onready var animation_player:AnimationPlayer = $AnimationPlayer


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
	
	if Input.is_action_just_pressed(PlayerActions.SHOVEL_LEFT):
		shovel_side = Vector3.LEFT if facing_with_camera else Vector3.RIGHT
		_update_shovel_position()
	
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
		animation_player.speed_scale = horizontal_velocity.length() / PlayerController.WALK_SPEED
		if not animation_player.is_playing():
			animation_player.play("Walk")
	
	move_and_slide()


func _update_shovel_position() -> void:
	var target_x: = shovel_side.x * SIDE_OFFSET
	if abs(target_x - shovel_root.position.x) < 0.1: return
	
	var mid_point: = Vector3(target_x / 2.0, 0.5, 0)
	var end_point: = Vector3(target_x, 0.0, 0)
	var tween: = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(shovel, "rotation:x", deg_to_rad(30), 0.25)
	tween.parallel().tween_property(shovel_root, "position", mid_point, 0.3)
	tween.tween_property(shovel_root, "position", end_point, 0.3)
	tween.parallel().tween_property(shovel, "rotation:x", 0, 0.25)


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


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Walk":
		if snow_height >= 0.18:
			var rand_pitch: = audio_player.pitch_scale + randf_range(-0.1, 0.1)
			audio_player.pitch_scale = clamp(rand_pitch, 0.95, 1.05)
			audio_player.stream = step_audio.pick_random()
			audio_player.play()
		
		step.emit()
