extends SubViewport

## Number of pixels to lookahead of shovel mask for snow level.
const SHOVEL_FORWARD_OFFSET:float = 8
const SHOVEL_SIDE_OFFSET:float = 14
const MAP_SCALE_MULTIPLIER:float = 10.0


const DEFAULT_FULL_SNOW_HEIGHT:float = 0.8
const DEFAULT_PATH_SNOW_HEIGHT:float = 0.4

const DEFAULT_FULL_SNOW:Color = Color(
	DEFAULT_FULL_SNOW_HEIGHT,
	DEFAULT_FULL_SNOW_HEIGHT,
	DEFAULT_FULL_SNOW_HEIGHT,
	1)

const DEFAULT_PATH_SNOW:Color = Color(
	DEFAULT_PATH_SNOW_HEIGHT,
	DEFAULT_PATH_SNOW_HEIGHT,
	DEFAULT_PATH_SNOW_HEIGHT,
	1)


@export var snow_mesh:MeshInstance3D


var average_shovel_height:float
var previous_player_pixel:Color
var previous_shovel_position:Vector2 = Vector2.ZERO
var pre_dump_height:float

var pathways_data:Dictionary = {}
var current_pathway:Pathway
var current_pathway_polygon:Polygon2D


@onready var height_root:Node2D = %HeightMapRoot
@onready var shovel_root:Node2D = %ShovelRoot
@onready var snow_height_mask_offset:Node2D = %SnowHeightMaskOffset
@onready var snow_shovel_mask:Sprite2D = %SnowShovelMask
@onready var snow_shovel_mask_size:Vector2 = snow_shovel_mask.texture.get_size()
@onready var accumuluation_front_mask:Sprite2D = %AccumulationFrontMask
@onready var dump_receive_area:Sprite2D = %DumpReceiveArea

@onready var player_root:Node2D = %PlayerRoot
@onready var snow_player_mask:Sprite2D = %SnowPlayerMask
@onready var reset_mask:TextureRect = %ResetMask
@onready var obstacles_root:Node2D = %Obstacles
@onready var pathways_root:Node2D = %Pathways

@onready var player:Player = get_tree().get_first_node_in_group("player")


func _ready():
	var initial_position_offset = (size / 2.0)
	snow_height_mask_offset.position = initial_position_offset
	
	# Register all 3D nodes that also mask the snow
	var snow_mask_image: = _get_mask_image()
	_register_houses()
	_register_pathways()
	
	reset_mask.self_modulate = DEFAULT_FULL_SNOW
	reset_mask.show()
	
	# Connect Signals
	player.shovel.dump_started.connect(_on_dump_shovel_started)
	player.shovel.dump_completed.connect(_on_dump_shovel_completed)
	player.step.connect(_on_step_connect)
	
	PathwayManager.player_entered_pathway.connect(_on_player_entered_pathway)
	PathwayManager.player_exited_pathway.connect(_on_player_exited_pathway)
	
	# Hide all initial masks after they render out
	await get_tree().create_timer(1).timeout
	reset_mask.hide()
	obstacles_root.hide()
	pathways_root.hide()


func _process(_delta):
	var snow_mask_image: = _get_mask_image()
	
	var player_position:Vector2 = _translate_position(player.global_position)
	player_root.position = player_position
	var player_rotation = _translate_rotation(player)
	player_root.rotation_degrees = player_rotation
	_check_player_pixel(snow_mask_image, player_position)
	
	var shovel_root_offset:Vector2 = _translate_position(player.shovel_root.position)
	shovel_root.position = shovel_root_offset
	shovel_root.position.x *= -1
	
	var shovel_position:Vector2 = _translate_position(player.shovel.global_position)
	_check_shovel_pixel(snow_mask_image, shovel_position)
	
	_check_pathway_average_height(snow_mask_image)


## Get 2D heightmap position of 3D node
func _translate_position(position_3D:Vector3) -> Vector2:
	var position_2D: = Vector2(
		position_3D.x,
		position_3D.z) * MAP_SCALE_MULTIPLIER
	
	return position_2D


## Get 2D rotation of a 3D node on the Map
func _translate_rotation(node_3D:Node3D) -> float:
	return rad_to_deg(Vector2(node_3D.basis.z.x, node_3D.basis.z.z).angle()) + 90


#region Check Pixel Heights
# --------------------------

## Get the texture being passed to the snow for its heightmap
func _get_mask_image() -> Image:
	var snow_mask_texture:ViewportTexture = snow_mesh.material_override.get_shader_parameter("snow_mask")
	return snow_mask_texture.get_image()


## Check the current height of snow underneath player
func _check_player_pixel(mask:Image, player_position:Vector2) -> void:
	var player_pixel: = mask.get_pixelv(player_position + snow_height_mask_offset.position)
	snow_player_mask.scale = (0.25 - player.mesh_root.position.y) * Vector2(4, 4)
	
	var is_on_snow:bool = player_pixel.r > 0
	var is_previous_on_snow:bool = previous_player_pixel.r > 0
	
	var did_enter_snow:bool = is_on_snow and not is_previous_on_snow
	var did_exit_snow:bool = not is_on_snow and is_previous_on_snow
	
	previous_player_pixel = player_pixel
	player.snow_height = player_pixel.r


## Check the current height of snow underneath shovel
func _check_shovel_pixel(mask:Image, shovel_position:Vector2) -> void:
	# Get the average pixel color in front of the shovel.
	var degrees:float = deg_to_rad(snow_player_mask.rotation_degrees)
	var forward_offset: = Vector2.UP.rotated(degrees) * SHOVEL_FORWARD_OFFSET
	var average_height:float = _get_average_height(mask, snow_shovel_mask,  Vector2.UP * SHOVEL_FORWARD_OFFSET)
	
	var previous_height:float = average_shovel_height
	average_shovel_height = average_height
	
	var distance_moved: = shovel_position - previous_shovel_position
	
	# Only update shovel mask if the character is actively shoveling.
	var velocity_2D: = _translate_position(player.velocity).normalized()
	var shovel_direction: = _translate_position(player.global_position).direction_to(shovel_position)
	var moving_in_shovel_direction: = velocity_2D.dot(shovel_direction)
	if player.is_shoveling and not distance_moved.is_zero_approx() and moving_in_shovel_direction >= 0:
		snow_shovel_mask.show()
		
		if not player.is_dumping:
			accumuluation_front_mask.show()
			
			var new_height = player.shovel.accumulated_percentage
			accumuluation_front_mask.self_modulate = Color(new_height, new_height, new_height, 1)
	
	elif not player.is_dumping:
		snow_shovel_mask.hide()
	
	player.shovel.next_snow_height = average_shovel_height * distance_moved.length()
	previous_shovel_position = shovel_position


## Get the average height of all pixels under a sprite mask
func _get_average_height(map:Image, mask:Sprite2D, offset:Vector2 = Vector2.ZERO) -> float:
	var mask_center: = mask.global_position
	var mask_offset: = offset.rotated(mask.global_rotation)
	var mask_direction: = Vector2.UP.rotated(mask.global_rotation).normalized()
	var mask_size: = mask.texture.get_size()
	var mask_start: = mask_center - (mask_direction * (mask_size/ 2.0))
	
	var average_height:float = 0
	for y in range(0, mask_size.y):
		for x in range(0, mask_size.x):
			var pixel := map.get_pixel(
				mask_start.x + mask_offset.x + (x * mask_direction.x),
				mask_start.y + mask_offset.y + (y * mask_direction.y))
			
			average_height += pixel.r
			average_height /= 2.0
	
	return average_height


#endregion


func _on_dump_shovel_started(direction:Vector3) -> void:
	snow_shovel_mask.show()
	pre_dump_height = average_shovel_height
	
	var map: = _get_mask_image()
	
	# Measure the avg. height of the receiving area.
	dump_receive_area.position.x = direction.x * SHOVEL_SIDE_OFFSET * -1
	var receiving_snow_height: = _get_average_height(map, dump_receive_area)
	
	await get_tree().create_timer(player.shovel.dump_duration * 0.1).timeout
	
	# Flash the current accumulation BLACK in order to clear it out
	accumuluation_front_mask.self_modulate = Color.BLACK
	accumuluation_front_mask.show()
	
	await get_tree().create_timer(player.shovel.dump_duration * 0.8).timeout
	
	# Now flash the accumulation in the drop area with the receiving and accumulated snow values added.
	var new_height:float = min(1, pre_dump_height + receiving_snow_height)
	dump_receive_area.modulate = Color(new_height, new_height, new_height, 1)
	
	# Let the new color render on the map for a blip of time before hiding it again
	await get_tree().create_timer(0.1).timeout
	call_deferred("_reset_shovel_mask")


func _on_dump_shovel_completed() -> void:
	pass


#region Houses
# --------------------------

func _register_houses() -> void:
	var houses = get_tree().get_nodes_in_group("house")
	for house in houses:
		var position:Vector2 = _translate_position(house.global_position)
		var house_size:Vector2 = Vector2(22, 22) * MAP_SCALE_MULTIPLIER
		var footprint:ColorRect = ColorRect.new()
		footprint.custom_minimum_size = house_size 
		footprint.color = DEFAULT_PATH_SNOW
		footprint.pivot_offset = house_size / 2.0
		footprint.position = position - footprint.pivot_offset
		footprint.rotation_degrees = _translate_rotation(house)
		obstacles_root.add_child(footprint)

#endregion


#region Pathways
# --------------------------

func _register_pathways() -> void:
	var map: = _get_mask_image()
	
	var pathways = get_tree().get_nodes_in_group("pathway")
	for pathway in pathways:
		var csg:CSGPolygon3D = pathway.polygon
		var position:Vector2 = _translate_position(csg.global_position)
		var offset_points:Array = []
		for point in csg.polygon:
			var offset_point:Vector2 = point * MAP_SCALE_MULTIPLIER
			offset_points.append(offset_point * Vector2(1, -1))
		
		var footprint: = Polygon2D.new()
		footprint.polygon = PackedVector2Array(offset_points)
		footprint.color = DEFAULT_PATH_SNOW
		footprint.position = position
		pathways_root.add_child(footprint)
		footprint.set_name(pathway.id)
		
		call_deferred("_cache_pathways_pixels", pathway, footprint)


func _check_pathway_average_height(map:Image) -> void:
	if not is_instance_valid(current_pathway): return
	
	var pixel_positions:Array = pathways_data[current_pathway.id]
	
	var average_height:float = 0.0
	var centroid:Vector2 = Vector2.ZERO
	for point in pixel_positions:
		var offset_point:Vector2 = point
		var pixel = map.get_pixelv(offset_point)
		
		average_height += pixel.r
		average_height /= 2.0
		
		centroid += offset_point
		centroid /= 2


func _cache_pathways_pixels(pathway:Pathway, pathway_polygon:Polygon2D) -> void:
	var polygon_size: = pathway.box_2D.size
	
	var new_image:Image = Image.create_empty(1600, 1600, false, Image.FORMAT_RGBA8)
	
	pathways_data[pathway.id] = []
	for y in range(-polygon_size.y, polygon_size.y):
		for x in range(-polygon_size.x, polygon_size.x):
			
			var point_local:Vector2 = Vector2(x, -y) * MAP_SCALE_MULTIPLIER
			var point_global:Vector2 = snow_height_mask_offset.position + pathway_polygon.position + point_local
			
			if Geometry2D.is_point_in_polygon(point_local, pathway_polygon.polygon):
				pathways_data[pathway.id].append(point_global)


func _on_player_entered_pathway(pathway:Pathway) -> void:
	current_pathway = pathway
	current_pathway_polygon = pathways_root.get_node(pathway.id)


func _on_player_exited_pathway(pathway:Pathway) -> void:
	current_pathway = null
	current_pathway_polygon = null


#endregion


func _on_step_connect() -> void:
	pass
	#snow_player_mask.self_modulate.a = 1.0
	#snow_player_mask.scale = Vector2(2, 2)
	#
	#var tween: = get_tree().create_tween()
	#tween.tween_property(snow_player_mask, "scale", Vector2(0.5, 0.5), 0.15)
	#tween.tween_callback(func():
		#snow_player_mask.self_modulate.a = 0.0
		#snow_player_mask.scale.x = 1)
	


func _reset_shovel_mask() -> void:
	snow_shovel_mask.hide()
	dump_receive_area.modulate.a = 0
	dump_receive_area.position.x = 0
	
