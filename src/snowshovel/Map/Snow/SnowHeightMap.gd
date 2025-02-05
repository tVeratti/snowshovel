extends SubViewport

## Number of pixels to lookahead of shovel mask for snow level.
const SHOVEL_FORWARD_OFFSET:float = 6
const SHOVEL_SIDE_OFFSET:float = 14

@export var snow_mesh:MeshInstance3D


var previous_player_pixel:Color
var previous_shovel_pixel:Color


@onready var shovel_root:Node2D = %ShovelRoot
@onready var snow_height_mask_offset:Node2D = %SnowHeightMaskOffset
@onready var snow_shovel_mask:Sprite2D = %SnowShovelMask
@onready var accumuluation_front_mask:Sprite2D = %AccumulationFrontMask
@onready var accumuluation_left_mask:Sprite2D = %AccumulationLeftMask
@onready var accumuluation_right_mask:Sprite2D = %AccumulationRightMask

@onready var snow_player_mask:Sprite2D = %SnowPlayerMask
@onready var reset_mask:ColorRect = %ResetMask

@onready var player:Player = get_tree().get_first_node_in_group("player")


func _ready():
	var initial_position_offset = (size / 2.0)
	snow_height_mask_offset.position = initial_position_offset
	
	player.shovel.dump_started.connect(_on_dump_shovel_started)
	player.shovel.dump_completed.connect(_on_dump_shovel_completed)
	
	reset_mask.show()
	await get_tree().create_timer(1).timeout
	reset_mask.hide()


func _process(_delta):
	var snow_mask_image: = _get_mask_image()
	
	var player_position:Vector2 = _translate_position(player.global_position)
	snow_player_mask.position = player_position
	var player_rotation = rad_to_deg(Vector2(player.basis.z.x, player.basis.z.z).angle()) + 90
	snow_player_mask.rotation_degrees = player_rotation
	_check_player_pixel(snow_mask_image, player_position)
	
	var shovel_root_offset:Vector2 = _translate_position(player.shovel_root.position)
	shovel_root.position = shovel_root_offset
	shovel_root.position.x *= -1
	
	var shovel_position:Vector2 = _translate_position(player.shovel.global_position)
	_check_shovel_pixel(snow_mask_image, shovel_position)


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
	var degrees:float = deg_to_rad(snow_player_mask.rotation_degrees)
	
	var forward_offset: = Vector2.UP.rotated(degrees) * SHOVEL_FORWARD_OFFSET
	var right_offset: = Vector2(1, 1).rotated(degrees) * (SHOVEL_FORWARD_OFFSET/2)
	var left_offset: = Vector2(-1, 1).rotated(degrees) * (SHOVEL_FORWARD_OFFSET/2)
	
	# Read pixels fo the mask to get the snow height under the shovel.
	var shovel_pixel: = mask.get_pixelv(shovel_position + snow_height_mask_offset.position + forward_offset)
	var left_pixel: = mask.get_pixelv(shovel_position + snow_height_mask_offset.position + left_offset)
	var right_pixel: = mask.get_pixelv(shovel_position + snow_height_mask_offset.position + right_offset)
	
	#var is_on_snow:bool = shovel_pixel.r > 0
	#var is_previous_on_snow:bool = previous_shovel_pixel.r > 0
	
	#var did_enter_snow:bool = is_on_snow and not is_previous_on_snow
	#var did_exit_snow:bool = not is_on_snow and is_previous_on_snow
	#
	#if did_enter_snow:
		#SnowManager.shovel_snow_entered.emit(shovel_pixel.r)
	#elif did_exit_snow:
		#SnowManager.shovel_snow_exited.emit()
	
	# Only update shovel mask if the character is actively shoveling.
	
	var velocity_2D: = _translate_position(player.velocity).normalized()
	var shovel_direction: = _translate_position(player.global_position).direction_to(shovel_position)
	var moving_in_shovel_direction: = velocity_2D.dot(shovel_direction)
	if player.is_shoveling and moving_in_shovel_direction >= 0:
		snow_shovel_mask.show()
		
		accumuluation_front_mask.modulate.a = 0.1  * player.shovel.accumulated_percentage
		accumuluation_front_mask.scale.y = 1.5 # + (1 * player.shovel.accumulated_percentage)
		
		if player.shovel.accumulated_percentage > 0.5:
			accumuluation_left_mask.modulate.a = left_pixel.r
			accumuluation_right_mask.modulate.a = right_pixel.r
	else:
		snow_shovel_mask.hide()
	
	player.shovel.next_snow_height = shovel_pixel.r
	previous_shovel_pixel = shovel_pixel


func _get_mask_image() -> Image:
	var snow_mask_texture:ViewportTexture = snow_mesh.material_override.get_shader_parameter("snow_mask")
	return snow_mask_texture.get_image()


func _on_dump_shovel_started(direction:Vector3) -> void:
	# Flash the current accumulation BLACK in order to clear it out
	accumuluation_front_mask.modulate = Color.BLACK
	
	await get_tree().create_timer(player.shovel.dump_duration * 0.5).timeout
	
	# Flash the shovel accumulation mask at its current pixel height in given direction
	accumuluation_front_mask.modulate = Color(1, 1, 1, player.shovel.accumulated_percentage)
	accumuluation_front_mask.position.x = direction.x * SHOVEL_SIDE_OFFSET


func _on_dump_shovel_completed() -> void:
	accumuluation_front_mask.modulate.a = 0
	accumuluation_front_mask.position.x = 0
