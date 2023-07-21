extends Node2D

export(Texture) var square_node_tex
export(Texture) var circle_node_tex
export(Vector2) var node_scale = Vector2(0.1, 0.1)


onready var leaf_poly = $Polygon2D
var leaf_points = []


class LeafPoint: 
	var mode : bool
	var node_vis : Sprite
	var pos : Vector2


func _ready():
	pass # Replace with function body.


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
	var new_point = LeafPoint.new()
	new_point.mode = false
	var polygon = leaf_poly.get_polygon()
	polygon.append(pos)
	leaf_poly.set_polygon(polygon)
	new_point.pos = pos
	var new_node = Sprite.new()
	new_node.texture = square_node_tex
	new_node.position = pos
	new_node.scale = node_scale
	self.add_child(new_node)
	new_point.node_vis = new_node
	leaf_points.append(new_point)
	
