extends Node


class_name PlayerController


const WALK_SPEED:float = 10.0
const SHOVEL_SPEED:float = 10.0

const ACCELERATION:float = 5.0
const DE_ACCELERATION:float = 8.0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var speed:float = WALK_SPEED
var direction:Vector3 = Vector3.ZERO


@onready var player:Player = get_parent()


# Q & E to dump snow L/R

func process_velocity(delta) -> Vector3:
	direction = _get_direction()
	
	var velocity = player.velocity
	speed = SHOVEL_SPEED if player.is_shoveling else WALK_SPEED
	
	var weight_multiplier:float = 1.0 - player.shovel.accumulated_percentage
	var destination = direction * speed * weight_multiplier
	var acceleration = DE_ACCELERATION
	
	var target_velocity = velocity
	if direction.dot(target_velocity) > 0:
		acceleration = ACCELERATION
	
	target_velocity = target_velocity.lerp(destination, acceleration * delta)
	
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	velocity.y -= gravity * delta
	
	return velocity


func _get_direction() -> Vector3:
	var dir = Vector3.ZERO
	
	if Input.is_action_pressed(PlayerActions.FORWARD):
		dir += Vector3.FORWARD
	if Input.is_action_pressed(PlayerActions.BACKWARD):
		dir += Vector3.BACK
	if Input.is_action_pressed(PlayerActions.LEFT):
		dir += Vector3.LEFT
	if Input.is_action_pressed(PlayerActions.RIGHT):
		dir += Vector3.RIGHT
	
	return dir.normalized()
