extends Node3D


class_name Shovel


@export var snow_per_second:float = 10.0
@export var max_snow_accumulation:float = 1.0


@onready var player:Player = get_parent()


var is_on_snow:bool = false
var accumulated_snow:float = 0.0
var next_snow_height:float = 0.0
var accumulated_percentage:float = 0.0


func _ready():
	SnowManager.shovel_snow_entered.connect(_on_snow_shovel_entered)
	SnowManager.shovel_snow_exited.connect(_on_snow_shovel_exited)
	player.dump_shovel.connect(_on_shovel_dumped)


func _process(delta):
	if player.is_shoveling:
		show()
		var player_velocity: = Vector2(player.velocity.x, player.velocity.z).length()
		if player_velocity > 1.0:
			var movement_multiplier:float = player_velocity / PlayerController.WALK_SPEED
			accumulated_snow = next_snow_height
	else:
		accumulated_snow = 0
		hide()
	
	printt(next_snow_height, accumulated_snow)
	accumulated_percentage = min(1.0, max(0.01, accumulated_snow) / max_snow_accumulation)


func _on_snow_shovel_entered(height:float) -> void:
	#accumulated_snow = height
	is_on_snow = true


func _on_snow_shovel_exited() -> void:
	is_on_snow = false


func _on_shovel_dumped(direction:Vector3) -> void:
	accumulated_snow = 0
