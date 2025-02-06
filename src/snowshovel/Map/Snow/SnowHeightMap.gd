extends SubViewport

## Number of pixels to lookahead of shovel mask for snow level.
const SHOVEL_FORWARD_OFFSET:float = 6
const SHOVEL_SIDE_OFFSET:float = 14

@export var snow_mesh:MeshInstance3D


var average_shovel_height:float
var previous_player_pixel:Color
var previous_shovel_position:Vector2 = Vector2.ZERO


@onready var shovel_root:Node2D = %ShovelRoot
@onready var snow_height_mask_offset:Node2D = %SnowHeightMaskOffset
@onready var snow_shovel_mask:Sprite2D = %SnowShovelMask
@onready var snow_shovel_mask_size:Vector2 = snow_shovel_mask.texture.get_size()
@onready var accumuluation_front_mask:Sprite2D = %AccumulationFrontMask
@onready var accumuluation_left_mask:Sprite2D = %AccumulationLeftMask
@onready var accumuluation_right_mask:Sprite2D = %AccumulationRightMask

@onready var snow_player_mask:Sprite2D = %SnowPlayerMask
@onready var reset_mask:TextureRect = %ResetMask

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
	
	# Read pixels fo the mask to get the snow height under the shovel.
	var shovel_start_position:Vector2 = shovel_position + snow_height_mask_offset.position + forward_offset
	shovel_start_position -= snow_shovel_mask_size / 2.0
	
	var shovel_pixel: = mask.get_pixelv(shovel_position + snow_height_mask_offset.position + forward_offset)

	# Get the average pixel color in front of the shovel.
	var average_height:float = 0
	for y in range(0, snow_shovel_mask_size.y):
		for x in range(0, snow_shovel_mask_size.x):
			var pixel := mask.get_pixel(
				shovel_start_position.x + x,
				shovel_start_position.y + y)
			average_height += pixel.r
			average_height /= 2.0
	
	var previous_height:float = average_shovel_height
	
	average_shovel_height = average_height
	
	var distance_moved: = shovel_position - previous_shovel_position
	var height_changed: = average_height - previous_height
	
	# How much snow was pushed?
	#distance_moved
	
	# Only update shovel mask if the character is actively shoveling.
	var velocity_2D: = _translate_position(player.velocity).normalized()
	var shovel_direction: = _translate_position(player.global_position).direction_to(shovel_position)
	var moving_in_shovel_direction: = velocity_2D.dot(shovel_direction)
	if player.is_shoveling and not distance_moved.is_zero_approx() and moving_in_shovel_direction >= 0:
		snow_shovel_mask.show()
		
		if not player.is_dumping:
			accumuluation_front_mask.modulate.a = 0.1 * player.shovel.accumulated_percentage
			accumuluation_front_mask.scale.y = 1.5 # + (1 * player.shovel.accumulated_percentage)
			
			if player.shovel.accumulated_percentage > 0.9:
				accumuluation_left_mask.modulate.a = 0.1 # left_pixel.r
				accumuluation_right_mask.modulate.a = 0.1 # right_pixel.r
	
	elif not player.is_dumping:
		snow_shovel_mask.hide()
	
	player.shovel.next_snow_height = average_shovel_height
	
	previous_shovel_position = shovel_position


func _get_mask_image() -> Image:
	var snow_mask_texture:ViewportTexture = snow_mesh.material_override.get_shader_parameter("snow_mask")
	return snow_mask_texture.get_image()


func _on_dump_shovel_started(direction:Vector3) -> void:
	# Flash the current accumulation BLACK in order to clear it out
	snow_shovel_mask.show()
	var saved_accumulation:float = average_shovel_height
	print(average_shovel_height)
	
	await get_tree().create_timer(player.shovel.dump_duration * 0.1).timeout
	
	accumuluation_front_mask.modulate = Color.BLACK
	
	await get_tree().create_timer(player.shovel.dump_duration * 0.4).timeout
	
	# Flash the shovel accumulation mask at its current pixel height in given direction
	var map: = _get_mask_image()
	accumuluation_front_mask.modulate = Color.WHITE
	accumuluation_front_mask.modulate.a = 0
	accumuluation_front_mask.position.x = direction.x * SHOVEL_SIDE_OFFSET * -1
	
	var receiving_snow_height: = map.get_pixelv(accumuluation_front_mask.global_position).r
	accumuluation_front_mask.modulate.a = min(1, saved_accumulation + receiving_snow_height)


func _on_dump_shovel_completed() -> void:
	accumuluation_front_mask.modulate.a = 0
	accumuluation_front_mask.position.x = 0
