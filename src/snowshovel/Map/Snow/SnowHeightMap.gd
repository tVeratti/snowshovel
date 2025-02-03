extends SubViewport


@export var snow_mesh:MeshInstance3D


var previous_player_pixel:Color
var previous_shovel_pixel:Color


@onready var snow_height_mask_offset:Node2D = %SnowHeightMaskOffset
@onready var snow_shovel_mask:Sprite2D = %SnowShovelMask
@onready var snow_player_mask:Sprite2D = %SnowPlayerMask
@onready var player:Player = get_tree().get_first_node_in_group("player")


func _ready():
	var initial_position_offset = (size / 2.0)
	snow_height_mask_offset.position = initial_position_offset


func _process(_delta):
	var snow_mask_image: = _get_mask_image()
	
	var player_position:Vector2 = _translate_position(player.global_position)
	snow_player_mask.position = player_position
	_check_player_pixel(snow_mask_image, player_position)
	
	var shovel_position:Vector2 = _translate_position(player.shovel.global_position)
	_check_shovel_pixel(snow_mask_image, shovel_position)
	
	# Only update shovel mask if the character is actively shoveling.
	if player.is_shoveling:
		snow_shovel_mask.position = player_position
		snow_shovel_mask.rotation_degrees = player.rotation_degrees.y + 90


func _translate_position(position_3D:Vector3) -> Vector2:
	var position_2D: = Vector2(
		position_3D.x,
		position_3D.z) * 10
	
	return position_2D


func _check_player_pixel(mask:Image, player_position:Vector2) -> void:
	var player_pixel: = mask.get_pixelv(player_position + snow_height_mask_offset.position)
	
	var is_on_snow:bool = player_pixel.r > 0
	var is_previous_on_snow:bool = previous_player_pixel.r > 0
	
	var did_enter_snow:bool = is_on_snow and not is_previous_on_snow
	var did_exit_snow:bool = not is_on_snow and is_previous_on_snow
	
	if did_enter_snow:
		SnowManager.player_snow_entered.emit()
	elif did_exit_snow:
		SnowManager.player_snow_exited.emit()
	
	previous_player_pixel = player_pixel


func _check_shovel_pixel(mask:Image, shovel_position:Vector2) -> void:
	var shovel_pixel: = mask.get_pixelv(shovel_position + snow_height_mask_offset.position)
	
	var is_on_snow:bool = shovel_pixel.r > 0
	var is_previous_on_snow:bool = previous_shovel_pixel.r > 0
	
	var did_enter_snow:bool = is_on_snow and not is_previous_on_snow
	var did_exit_snow:bool = not is_on_snow and is_previous_on_snow
	
	if did_enter_snow:
		SnowManager.shovel_snow_entered.emit()
	elif did_exit_snow:
		SnowManager.shovel_snow_exited.emit()
	
	previous_shovel_pixel = shovel_pixel


func _get_mask_image() -> Image:
	var snow_mask_texture:ViewportTexture = snow_mesh.material_override.get_shader_parameter("snow_mask")
	return snow_mask_texture.get_image()
