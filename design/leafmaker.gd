extends Node2D

export(Texture) var square_node_tex
export(Texture) var circle_node_tex
export(Vector2) var node_scale = Vector2(0.1, 0.1)


onready var leaf_poly = $Polygon2D
onready var leaf_origin = $LeafOrigin
var leaf_points = []
var leaf_curve : Curve2D


class LeafPoint: 
	var mode : bool
	var node_vis : Sprite
	var pos : Vector2
	var curve_index : int
	
	func _init(set_mode : bool, set_vis : Sprite, set_pos : Vector2, set_idx : int):
		mode = set_mode
		node_vis = set_vis
		pos = set_pos
		curve_index = set_idx


func _ready():
	leaf_curve = Curve2D.new()
	leaf_curve.add_point(leaf_origin.position, leaf_origin.position, leaf_origin.position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print(event.position)
			print(event.button_index)
			if event.button_index == 1:
				print("Left Click")
				add_point(event.position)
			if event.button_index == 2:
				print("Right Click")
			if event.button_index == 3:
				print("Middle Click")


func add_point(pos : Vector2):
	leaf_curve.add_point(pos, pos, pos)
	var node_vis = Sprite.new()
	node_vis.texture = square_node_tex
	node_vis.position = pos
	node_vis.scale = node_scale
	self.add_child(node_vis)
	var index = leaf_curve.get_baked_points().find(pos)
	leaf_points.append(LeafPoint)
	draw_shape()


func draw_shape():
	if leaf_curve.get_point_count() >= 3:
		print("Leaf Valid")
		leaf_poly.visible = true
		var curve_points : PoolVector2Array = PoolVector2Array()
		for i in leaf_curve.get_point_count():
			curve_points.append(leaf_curve.get_point_position(i))
		leaf_poly.set_polygon(curve_points)
#		leaf_poly.set_polygon(leaf_curve.get_baked_points())
	else:
		leaf_poly.visible = false
		print("Leaf has too few points")
