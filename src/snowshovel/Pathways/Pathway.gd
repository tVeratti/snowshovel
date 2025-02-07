extends Node3D


class_name Pathway


@export var polygon:CSGPolygon3D

#@onready var shovel_area:Area2D = %ShovelArea3D


func _ready():
	polygon.hide()
