extends SubViewport


@export var snow_mesh:MeshInstance3D


@onready var snow_height_mask_offset:Node2D = %SnowHeightMaskOffset
@onready var snow_height_mask:Sprite2D = %SnowHeightMask
@onready var player:Player = get_tree().get_first_node_in_group("player")


func _ready():
	var initial_position_offset = (size / 2.0)
	snow_height_mask_offset.position = initial_position_offset


func _process(delta):
	snow_height_mask.position = _translate_player_position()
	snow_height_mask.rotation_degrees = player.rotation_degrees.y + 90


func _translate_player_position() -> Vector2:
	var player_position_3D:Vector3 = player.global_position
	
	var player_position_2D: = Vector2(
		player_position_3D.x,
		player_position_3D.z) * 10
	
	return player_position_2D
