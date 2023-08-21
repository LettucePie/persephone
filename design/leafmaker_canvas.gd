extends Node2D


@export var square_node_tex: Texture2D
@export var circle_node_tex: Texture2D
@export var node_scale: Vector2 = Vector2(0.1, 0.1)
@export var leaf_gradient_default: Gradient
@export var leaf_texture_default: Texture2D


var ui_control : Control
enum Mode {ADD_MODE, EDIT_MODE, DELETE_MODE}
var current_mode = Mode.ADD_MODE
var screen_size : Vector2
@export var debug_draw: bool = false


class LeafPoint:
	var visual_node : Node2D
	var curve_index : int
	var symmetry : bool
	var symmetry_pair : LeafPoint
	func _init(_visual_node, _curve_index, _symmetry, _symmetry_pair):
		visual_node = _visual_node
		curve_index = _curve_index
		symmetry = _symmetry
		symmetry_pair = _symmetry_pair
	
	func associate_pair(pair : LeafPoint):
		symmetry = true
		symmetry_pair = pair
		pair.symmetry = true
		pair.symmetry_pair = self
	
	func break_pair():
		symmetry = false
		if symmetry_pair != null:
			symmetry_pair.symmetry = false
			symmetry_pair.symmetry_pair = null
			symmetry_pair = null


var leaf_points : Array = []
@onready var leaf_poly = $Polygon2D
@onready var leaf_origin = $LeafOrigin
@onready var leaf_curve : Curve2D = Curve2D.new()
@onready var leaf_color : Color = Color(0.2, 0.8, 0.1, 1.0)
@onready var leaf_gradient : Gradient = leaf_gradient_default
@onready var leaf_texture : Texture2D = leaf_texture_default


func _ready():
	screen_size = get_window().get_size()
	print("Centering Origin First Time")
	recenter_origin()
	print("Building Start of the Leaf")
	leaf_curve = Curve2D.new()
	leaf_curve.set_bake_interval(5)
	add_point(leaf_origin.position, -1)
	print("Building Rest of the Leaf")
	starting_leaf()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_R:
				print("Randomizing UV End")
				randomize()


func recenter_origin():
	print(leaf_origin)
	var old_position = leaf_origin.position
	var new_position = Vector2(get_window().get_size())
	new_position.x *= 0.5
	new_position.y *= 0.75
	leaf_origin.position = new_position
	if leaf_curve.get_point_count() > 0:
		slide_curve(old_position - new_position)
		maximize_curve_scale(new_position)
		fit_curve_scale(new_position, get_window().get_size().x, new_position.y)
		update_leaf_visual(true)


func slide_curve(offset : Vector2):
	for i in leaf_curve.get_point_count():
		leaf_curve.set_point_position(i, leaf_curve.get_point_position(i) - offset)
		leaf_points[i].visual_node.position -= offset


func fit_curve_scale(anchor : Vector2, w : float, h : float):
	var bad_actors : Array = []
	for i in leaf_curve.get_point_count():
		## Filter out the Origin Point
		if i > 0:
			var i_pos = leaf_curve.get_point_position(i)
			var safe = true
			var bound = i_pos
			if i_pos.x < 5:
				safe = false
				bound.x = 5
			if i_pos.x > (w - 5):
				safe = false
				bound.x = w - 5
			if i_pos.y < 5: 
				safe = false
				bound.y = 5
			if i_pos.y > (h - 5):
				safe = false
				bound.y = h - 5
			if !safe:
				bad_actors.append([i, i_pos, bound])
	if bad_actors.size() > 0:
		print("Leaf Curve exceeds bounds, resize curve.")
		## Find furthest bad actor, by comparing their position to their,
		## exceeded Boundary.
		var worst_actor : Array = bad_actors[0]
		var greatest_distance : float = 0
		for b in bad_actors:
			var distance = b[2].distance_to(b[1])
			if distance > greatest_distance:
				greatest_distance = distance
				worst_actor = b
		## Compare distance from bound to distance from anchor.
		## Use value to produce an offset percentage.
		var anchor_distance = anchor.distance_to(worst_actor[1])
		scale_curve(anchor, greatest_distance / anchor_distance)


func maximize_curve_scale(anchor : Vector2):
	var center = leaf_origin.position
	center.y *= 0.5
	var closest_distance : float = 100000
	var closest_point = null
	for i in leaf_curve.get_point_count():
		var bound = Vector2.ZERO
		var i_pos = leaf_curve.get_point_position(i)
		if i_pos.x <= center.x:
			bound.x = 5
		else:
			bound.x = DisplayServer.screen_get_size().x - 5
		if i_pos.y <= center.x:
			bound.y = 5
		else:
			bound.y = i_pos.y
		var distance = i_pos.distance_to(bound)
		if distance < closest_distance:
			closest_distance = distance
			closest_point = [i, i_pos, bound, distance]
	if closest_point != null:
		var anchor_distance = anchor.distance_to(closest_point[2])
		scale_curve(anchor, (closest_point[3] / anchor_distance) * -1.0)


func scale_curve(anchor : Vector2, percent : float):
	for i in leaf_curve.get_point_count():
		## Don't scale the origin
		if i > 0:
			leaf_curve.set_point_position(
					i, 
					leaf_curve.get_point_position(i).lerp(anchor, percent))
			leaf_points[i].visual_node.position = leaf_points[i].visual_node.position.lerp(anchor, percent)


func starting_leaf():
	var top_point = leaf_origin.position
	top_point.y = 60
	var center_point = leaf_origin.position.lerp(top_point, 0.3)
	var left_point = center_point
	left_point.x = left_point.x * 0.7
	var right_point = center_point
	right_point.x = get_window().get_size().x - left_point.x
	add_point(left_point, -1)
	add_point(top_point, -1)
	add_point(right_point, -1)


func _on_table_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print(event.position)
			print(event.button_index)
			if event.button_index == 1:
				print("Left Click")
				if current_mode == Mode.ADD_MODE:
					if leaf_curve.get_point_count() > 3:
						detect_intersection(event.position)
					else:
						add_point(event.position, -1)
			if event.button_index == 2:
				print("Right Click")
			if event.button_index == 3:
				print("Middle Click")


func detect_intersection(pos : Vector2):
	print("Looking for Intersection near point ", pos)
	var target_point = leaf_curve.get_closest_point(pos)
	if target_point.distance_squared_to(pos) < 1000:
		## Find Closest two
		var dist_a = 1000000
		var dist_b = 1000000
		var close_points = [leaf_curve.get_point_count() - 1, leaf_curve.get_point_count() - 1]
		for p in leaf_points:
			var dist = leaf_curve.get_point_position(p.curve_index).distance_squared_to(target_point)
			print(p.curve_index, " ", dist)
			if dist < dist_a:
				dist_b = dist_a
				dist_a = dist
				close_points[1] = close_points[0]
				close_points[0] = p.curve_index
			elif dist < dist_b:
				dist_b = dist
				close_points[1] = p.curve_index
		print(dist_a, " ", dist_b, " ", close_points)
		close_points.sort()
		close_points.reverse()
		print("Intersection found at index, ", close_points[0])
		add_point(pos, close_points[0])


func add_point(pos : Vector2, idx : int):
	print("Add Point Called with Pos ", pos, " and idx: ", idx)
	var node_vis = Sprite2D.new()
	node_vis.texture = square_node_tex
	node_vis.position = pos
	node_vis.scale = node_scale
	self.add_child(node_vis)
	leaf_curve.add_point(pos, Vector2.ZERO, Vector2.ZERO, idx)
	var curve_index = idx
	if idx < 0:
		curve_index = leaf_curve.get_point_count() - 1
	var new_point = LeafPoint.new(node_vis, curve_index, false, null)
	leaf_points.insert(curve_index, new_point)
	update_leaf_visual(true)
	if leaf_points.size() % 2 == 0:
		pair_symmetry_points()
	else:
		break_symmetry_points()


func update_leaf_point_indeces(range_start : int):
	for i in range(range_start, leaf_curve.get_point_count()):
		pass


func pair_symmetry_points():
	print("Pairing Symmetry Points")
	var side_a = []
	var side_b = []
	var half_index = (leaf_points.size() / 2)
	for i in leaf_points.size():
		if i != 0 and i != half_index:
			print(i, " valid!")
			if i < half_index:
				side_a.append(leaf_points[i])
			else:
				side_b.append(leaf_points[i])
	side_b.reverse()
	if side_a.size() == side_b.size():
		for i in side_a.size():
			side_a[i].associate_pair(side_b[i])
	else:
		print("ERROR Symmetry Sides are uneven... somehow")


func break_symmetry_points():
	print("Breaking Symmetry Points")
	for p in leaf_points:
		if p.symmetry:
			p.break_pair()


func insert_point():
	pass


func update_leaf_visual(hd : bool):
	if !debug_draw:
		if leaf_curve.get_point_count() >= 3:
			leaf_poly.visible = true
			var point_data : PackedVector2Array
			if hd:
				point_data = leaf_curve.get_baked_points()
			else:
				for i in leaf_curve.get_point_count():
					point_data.append(leaf_curve.get_point_position(i))
			draw_leaf_shape(point_data)
			draw_leaf_texture(point_data)
		else:
			leaf_poly.visible = false
			print("Leaf has too few points")


func draw_leaf_shape(points : PackedVector2Array):
	leaf_poly.set_polygon(points)


func draw_leaf_texture(points : PackedVector2Array):
	print("Polygon UV Data works on a scale of the Texture!")
	var count = points.size()
	var colors : PackedColorArray = PackedColorArray()
	var uvs : PackedVector2Array = PackedVector2Array()
	var screen_uv_0 = Vector2(5, 5)
	var screen_uv_1 = Vector2(DisplayServer.screen_get_size().x - 5, leaf_origin.position.y - 5)
	var space_uv_0 = points[0]
	var space_uv_1 = points[0]
	var texture_size = leaf_texture.get_size()
	for b in points:
		if b.x < space_uv_0.x:
			space_uv_0.x = b.x
		if b.x > space_uv_1.x:
			space_uv_1.x = b.x
		if b.y < space_uv_0.y:
			space_uv_0.y = b.y
		if b.y > space_uv_1.y:
			space_uv_1.y = b.y
	for i in count:
		var baked_point_pos = points[i]
		var percent = float(i) / float(count)
		var scale_position = Vector2(
				inverse_lerp(space_uv_0.x, space_uv_1.x, baked_point_pos.x),
				inverse_lerp(space_uv_0.y, space_uv_1.y, baked_point_pos.y))
		colors.append(leaf_gradient.sample(scale_position.x))
		var scale_texture = Vector2(
				lerp(0.0, texture_size.x, scale_position.x),
				lerp(0.0, texture_size.y, scale_position.y))
		uvs.append(scale_texture)
	leaf_poly.texture = leaf_texture
	leaf_poly.vertex_colors = colors
	leaf_poly.uv = uvs


func draw_curve_shape():
	if leaf_curve.get_point_count() >= 3:
		leaf_poly.set_polygon(leaf_curve.get_baked_points())


func debug_draw_curve_shape():
	for trash in get_tree().get_nodes_in_group("Clear"):
		trash.queue_free()
	for baked_point in leaf_curve.get_baked_points():
		var dot = Sprite2D.new()
		dot.texture = circle_node_tex
		dot.scale = Vector2.ONE * 0.05
		dot.position = baked_point
		dot.add_to_group("Clear")
		add_child(dot)


func _draw():
	if debug_draw and leaf_curve.get_baked_points().size() > 3:
		var baked_points = leaf_curve.get_baked_points()
		var count = baked_points.size()
		var colors : PackedColorArray = PackedColorArray()
		var uvs : PackedVector2Array = PackedVector2Array()
		var screen_uv_0 = Vector2(5, 5)
		var screen_uv_1 = Vector2(DisplayServer.screen_get_size().x - 5, leaf_origin.position.y - 5)
		var space_uv_0 = baked_points[0]
		var space_uv_1 = baked_points[0]
		for b in baked_points:
			if b.x < space_uv_0.x:
				space_uv_0.x = b.x
			if b.x > space_uv_1.x:
				space_uv_1.x = b.x
			if b.y < space_uv_0.y:
				space_uv_0.y = b.y
			if b.y > space_uv_1.y:
				space_uv_1.y = b.y
		for i in count:
			var baked_point_pos = baked_points[i]
			var percent = float(i) / float(count)
			colors.append(leaf_gradient.sample(percent))
			var scale_position = Vector2(
					inverse_lerp(space_uv_0.x, space_uv_1.x, baked_point_pos.x),
					inverse_lerp(space_uv_0.y, space_uv_1.y, baked_point_pos.y))
			uvs.append(scale_position)
		draw_polygon(leaf_curve.get_baked_points(), colors, uvs, leaf_texture)


func _on_Mode_item_selected(index):
	current_mode = index
	print("Current Mode: ", current_mode)


func _on_ui_resized():
#	print("UI Resized")
	if leaf_origin != null:
		recenter_origin()


func _on_Maximize_pressed():
#	print("Maximize Curve Pressed")
	maximize_curve_scale(leaf_origin.position)



