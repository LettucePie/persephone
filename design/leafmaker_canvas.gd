extends Node2D

export(Texture) var square_node_tex
export(Texture) var circle_node_tex
export(Vector2) var node_scale = Vector2(0.1, 0.1)

enum Mode {ADD_MODE, EDIT_MODE, DELETE_MODE}
export(bool) var debug_draw = false

onready var leaf_poly = $Polygon2D
onready var leaf_origin = $LeafOrigin
onready var leaf_curve : Curve2D = Curve2D.new()

var current_mode = Mode.ADD_MODE

func _ready():
	print("Centering Origin First Time")
	recenter_origin()
	print("Building Start of the Leaf")
	leaf_curve = Curve2D.new()
	leaf_curve.set_bake_interval(5)
	leaf_curve.add_point(leaf_origin.position, Vector2.ZERO, Vector2.ZERO)
	print("Building Rest of the Leaf")
	starting_leaf()


func _input(event):
	pass


func recenter_origin():
	var old_position = leaf_origin.position
	var new_position = OS.get_window_size()
	new_position.x *= 0.5
	new_position.y *= 0.75
	leaf_origin.position = new_position
	if leaf_curve.get_point_count() > 0:
		slide_curve(old_position - new_position)
		fit_curve(new_position, OS.get_window_size().x, new_position.y)


func slide_curve(offset : Vector2):
	for i in leaf_curve.get_point_count():
		leaf_curve.set_point_position(i, leaf_curve.get_point_position(i) - offset)


func fit_curve(anchor : Vector2, w : float, h : float):
	var bad_actors : Array = []
	for i in leaf_curve.get_point_count():
		## Filter out the Origin Point
		if i > 0:
			var i_pos = leaf_curve.get_point_position(i)
			if i_pos.x < 5 or i_pos.x > (w - 5):
				bad_actors.append(i)
				print(i_pos.x, " x")
			elif i_pos.y < 5 or i_pos.y > (h - 5):
				bad_actors.append(i)
				print(i_pos.y, " y")
	if bad_actors.size() > 0:
		print("Leaf Curve exceeds bounds, resize")


func scale_curve(anchor : Vector2, percent : float):
	pass


func starting_leaf():
	var top_point = leaf_origin.position
	top_point.y = 50
	var center_point = leaf_origin.position.linear_interpolate(top_point, 0.3)
	var left_point = center_point
	left_point.x = left_point.x * 0.7
	var right_point = center_point
	right_point.x = OS.get_window_size().x - left_point.x
	leaf_curve.add_point(left_point, Vector2.ZERO, Vector2.ZERO)
	leaf_curve.add_point(top_point, Vector2.ZERO, Vector2.ZERO)
	leaf_curve.add_point(right_point, Vector2.ZERO, Vector2.ZERO)
	update()


func _on_table_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print(event.position)
			print(event.button_index)
			if event.button_index == 1:
				print("Left Click")
				if current_mode is Mode.ADD_MODE:
					add_point(event.position)
			if event.button_index == 2:
				print("Right Click")
			if event.button_index == 3:
				print("Middle Click")


func add_point(pos : Vector2):
	leaf_curve.add_point(pos, Vector2.ZERO, Vector2.ZERO)
	var node_vis = Sprite.new()
	node_vis.texture = square_node_tex
	node_vis.position = pos
	node_vis.scale = node_scale
	self.add_child(node_vis)
	var index = leaf_curve.get_baked_points().find(pos)
#	draw_shape()
#	draw_curve_shape()
	update()
	debug_draw_curve_shape()


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


func draw_curve_shape():
	if leaf_curve.get_point_count() >= 3:
		leaf_poly.set_polygon(leaf_curve.get_baked_points())


func debug_draw_curve_shape():
	for trash in get_tree().get_nodes_in_group("Clear"):
		trash.queue_free()
	for baked_point in leaf_curve.get_baked_points():
		var dot = Sprite.new()
		dot.texture = circle_node_tex
		dot.scale = Vector2.ONE * 0.05
		dot.position = baked_point
		dot.add_to_group("Clear")
		add_child(dot)


func _draw():
	if leaf_curve.get_baked_points().size() > 3:
		draw_polygon(leaf_curve.get_baked_points(), PoolColorArray())


func _on_Mode_item_selected(index):
	current_mode = index
	print("Current Mode: ", current_mode)


func _on_ui_resized():
	print("UI Resized")
	recenter_origin()
