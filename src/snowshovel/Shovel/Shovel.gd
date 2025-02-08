extends Node3D


class_name Shovel


signal dump_started(direction)
signal dump_completed()


@export var shovel_loop_start:Array[AudioStream] = []
@export var shovel_loop_main:Array[AudioStream] = []
@export var shovel_scoop_audio:Array[AudioStream] = []

@export var snow_per_second:float = 10.0
@export var max_snow_accumulation:float = 2.0
@export var dump_duration:float = 1.0


var is_on_snow:bool = false
var accumulated_snow:float = 0.0
var next_snow_height:float = 0.0
var accumulated_percentage:float = 0.0


@onready var player:Player = get_parent().get_parent().get_parent()
@onready var dump_timer:Timer = %DumpTimer
@onready var animations:AnimationPlayer = $AnimationPlayer
@onready var accumulation_mesh:MeshInstance3D = %SnowAccumulation
@onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer


func _ready():
	player.start_shovel.connect(_on_start_shovel)
	player.end_shovel.connect(_on_end_shovel)
	player.dump_shovel.connect(_on_shovel_dumped)


func _process(delta):
	if player.is_dumping: return
	
	audio_player.volume_db = -30 * accumulated_percentage
	
	if player.is_shoveling:
		if next_snow_height > 0.2:
			accumulated_snow += next_snow_height * 0.05
		else:
			audio_player.volume_db = -30
			accumulated_snow += next_snow_height
	else:
		accumulated_snow = 0
	
	if accumulated_snow == 0.0:
		accumulated_percentage = 0.0
	else:
		accumulated_percentage = min(1.0, accumulated_snow / max_snow_accumulation)
	
	#var pitch_shift:AudioEffectPitchShift = AudioServer.get_bus_effect(1, 0)
	#var rand_pitch: = randf_range(-0.1, 0.1)
	#var accum_pitch:float = max(0.1, 2.0 - accumulated_percentage)
	#audio_player.pitch_scale = 1.0 / accum_pitch 
	#pitch_shift.pitch_scale = accum_pitch
	


func _on_shovel_dumped(direction:Vector3) -> void:
	if not dump_timer.is_stopped(): return
	match(player.shovel_side):
		Vector3.LEFT: animations.play("DumpRight")
		Vector3.RIGHT: animations.play("DumpLeft")
	
	audio_player.stream = shovel_scoop_audio.pick_random()
	audio_player.play()
	
	dump_timer.start(dump_duration)
	dump_started.emit(direction)


func _on_dump_timer_timeout():
	accumulated_snow = 0.0
	dump_completed.emit()


func _on_start_shovel() -> void:
	_play_shovel_loop(true)


func _on_end_shovel() -> void:
	_stop_audio_loop()


func _stop_audio_loop() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(audio_player, "volume_db", -20.0, 0.2)
	tween.tween_callback(func():
		audio_player.stop())


func _play_shovel_loop(initial_start:bool) -> void:
	if audio_player.playing: return
	
	if initial_start:
		var tween = get_tree().create_tween()
		tween.tween_property(audio_player, "volume_db", -10.0, 0.5)
		audio_player.stream = shovel_loop_start.pick_random()
	else:
		audio_player.stream = shovel_loop_main.pick_random()
	
	var rand_pitch: = randf_range(-0.2, 0.2)
	audio_player.pitch_scale = 1.0 + rand_pitch
	audio_player.play()


func _on_audio_stream_player_finished():
	if player.is_shoveling:
		_play_shovel_loop(false)
