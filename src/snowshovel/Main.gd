extends Node3D

const PLAY_ANIMATION_DURATION:float = 2.0


@onready var player:Player = $Player
@onready var menu:Control = %MenuInterface


func _ready():
	# Zoom the initial camera view out, so when the game starts, it can zoom IN
	player.camera.offset_override = player.camera.initial_offset * 2.0
	player.camera.fov = 80
	
	pause_player(true)


func pause_player(is_paused) -> void:
	player.set_process(!is_paused)
	player.set_physics_process(!is_paused)
	player.set_process_input(!is_paused)


func _on_play_pressed():
	var camera:PlayerCamera = player.camera
	
	var tween: = get_tree().create_tween()
	tween.tween_property(menu, "modulate", Color(1, 1, 1, 0), PLAY_ANIMATION_DURATION) 
	tween.parallel().tween_property(camera, "offset_override", Vector3.ZERO, PLAY_ANIMATION_DURATION)
	tween.parallel().tween_property(camera, "fov", 75, PLAY_ANIMATION_DURATION)
	tween.tween_callback(func():
		pause_player(false)
		menu.queue_free())
