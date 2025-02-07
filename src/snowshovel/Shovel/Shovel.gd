extends Node3D


class_name Shovel


signal dump_started(direction)
signal dump_completed()


@export var snow_per_second:float = 10.0
@export var max_snow_accumulation:float = 1.0
@export var dump_duration:float = 1.0


@onready var player:Player = get_parent().get_parent()
@onready var dump_timer:Timer = %DumpTimer
@onready var animations:AnimationPlayer = $AnimationPlayer
@onready var accumulation_mesh:MeshInstance3D = %SnowAccumulation


var is_on_snow:bool = false
var accumulated_snow:float = 0.0
var next_snow_height:float = 0.0
var accumulated_percentage:float = 0.0


func _ready():
	SnowManager.shovel_snow_entered.connect(_on_snow_shovel_entered)
	SnowManager.shovel_snow_exited.connect(_on_snow_shovel_exited)
	player.dump_shovel.connect(_on_shovel_dumped)


func _process(delta):
	if player.is_dumping: return
	
	if player.is_shoveling:
		accumulated_snow += next_snow_height * 0.05
	else:
		accumulated_snow = 0
	
	if accumulated_snow == 0.0:
		accumulated_percentage = 0.0
	else:
		accumulated_percentage = min(1.0, accumulated_snow / max_snow_accumulation)


func _on_snow_shovel_entered(height:float) -> void:
	is_on_snow = true


func _on_snow_shovel_exited() -> void:
	is_on_snow = false


func _on_shovel_dumped(direction:Vector3) -> void:
	if not dump_timer.is_stopped(): return
	match(player.shovel_side):
		Vector3.LEFT: animations.play("DumpRight")
		Vector3.RIGHT: animations.play("DumpLeft")
	
	dump_timer.start(dump_duration)
	dump_started.emit(direction)


func _on_dump_timer_timeout():
	accumulated_snow = 0.0
	dump_completed.emit()
