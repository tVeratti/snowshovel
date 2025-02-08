extends Node3D


class_name Pathway

const MAX_COORD = pow(2,31)-1
const MIN_COORD = -MAX_COORD

const TARGET_HEIGHT:float = 0.1


@export var polygon:CSGPolygon3D


var id:String = UUID.v4()
var is_player_within:bool = false
var player_within:Player
var box_2D:Rect2
var progress:float = 1.0

@onready var shovel_area:Area3D = %ShovelArea3D
@onready var shovel_collision:CollisionPolygon3D = %CollisionPolygon3D
@onready var progress_label:Label3D = %Progress
@onready var progress_anchor:Node3D = %ProgressAnchor


func _ready():
	polygon.hide()
	set_rect()
	shovel_collision.polygon = polygon.polygon
	progress_anchor.top_level = true
	#var points:Array = []
	#for p in polygon.polygon:
		#points.append(p * 1.2)
	#shovel_collision.polygon = PackedVector2Array(points)
	#shovel_area.position += Vector3(box_2D.size.x, 0, box_2D.size.y) / 1.2


func _process(delta):
	if is_instance_valid(player_within):
		progress_label.text = "%s%%" % min(100.0, snapped(progress * 100, 0))
		progress_anchor.global_position = lerp(
			progress_anchor.global_position,
			player_within.global_position - Vector3(3,0, 3),
			2 * delta)


func _on_shovel_area_3d_body_entered(body):
	if body is Player:
		player_within = body
		is_player_within = true
		PathwayManager.player_entered_pathway.emit(self)
		_show_progress(true)


func _on_shovel_area_3d_body_exited(body):
	if body is Player:
		is_player_within = false
		player_within = null
		PathwayManager.player_exited_pathway.emit(self)
		_show_progress(false)


func _show_progress(do_show:bool) -> void:
	var tween: = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(progress_label, "position:y", 3.0 if do_show else -3.0, 2.0)


func minv(curvec,newvec):
	return Vector2(min(curvec.x,newvec.x),min(curvec.y,newvec.y))
	
	
func maxv(curvec,newvec):
	return Vector2(max(curvec.x,newvec.x),max(curvec.y,newvec.y))


func set_rect():
	var min_vec = Vector2(MAX_COORD,MAX_COORD)
	var max_vec = Vector2(MIN_COORD,MIN_COORD)
	for v in polygon.polygon:
		min_vec = minv(min_vec,v)
		max_vec = maxv(max_vec,v)
	box_2D = Rect2(min_vec,max_vec-min_vec)


func _on_check_timer_timeout():
	pass # Replace with function body.
