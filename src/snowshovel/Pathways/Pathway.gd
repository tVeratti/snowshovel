extends Node3D


class_name Pathway

const MAX_COORD = pow(2,31)-1
const MIN_COORD = -MAX_COORD


@export var polygon:CSGPolygon3D


var id:String = UUID.v4()
var player_within:bool = false
var box_2D:Rect2


@onready var shovel_area:Area3D = %ShovelArea3D
@onready var shovel_collision:CollisionPolygon3D = %CollisionPolygon3D


func _ready():
	polygon.hide()
	shovel_collision.polygon = polygon.polygon
	shovel_collision.global_transform = polygon.global_transform
	set_rect()


func _on_shovel_area_3d_body_entered(body):
	if body is Player:
		player_within = true
		PathwayManager.player_entered_pathway.emit(self)


func _on_shovel_area_3d_body_exited(body):
	if body is Player:
		player_within = false
		PathwayManager.player_exited_pathway.emit(self)


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
