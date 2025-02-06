extends Camera3D


class_name PlayerCamera


const MOVE_SPEED:float = 10.0


@export var target:Node3D


var offset_override:Vector3 = Vector3.ZERO

@onready var initial_offset:Vector3 = position


func _ready():
	top_level = true


func _physics_process(delta):
	if is_instance_valid(target):
		var target_position:Vector3 = target.global_position + initial_offset + offset_override
		global_position = target_position # lerp(global_position, target_position, MOVE_SPEED * delta)
		
		look_at(target.global_position)
