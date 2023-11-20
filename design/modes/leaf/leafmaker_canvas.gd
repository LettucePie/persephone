extends Node2D

signal color_bounds(min, max)
signal update_canvas_tex(tex)

@export var leaf_point_object : PackedScene
@export var node_scale: Vector2 = Vector2(0.1, 0.1)
@export var stretch_x : bool = false
@export var stretch_y : bool = false
@export var vein_texture : Texture2D
@export var round_points_enabled : bool = false
@export var in_tangent_height : float = 0.75
@export var out_tangent_height : float = 0.75
@export var in_dir_force : float = 0.5
@export var out_dir_force : float = 0.5
@export var in_tangent_height_round : float = 1.0
@export var out_tangent_height_round : float = 1.0
@export var in_dir_force_round : float = 0.35
@export var out_dir_force_round : float = 0.35


class LeafPoint:
	var visual_node : Node2D
	var round_point : bool
	var curve_index : int
	var symmetry : bool
	var side_a : bool = false
	var midpoint : bool = false
	var symmetry_pair : LeafPoint
	var vein_target : bool = false
	var hidden = false
	
	func _init(_visual_node, _round_point, _curve_index, _symmetry, _symmetry_pair):
		visual_node = _visual_node
		round_point = _round_point
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
		side_a = false
		midpoint = false
		visual_node.set_color(Color.WHITE)
		if symmetry_pair != null:
			symmetry_pair.symmetry = false
			symmetry_pair.visual_node.set_color(Color.WHITE)
			symmetry_pair.symmetry_pair = null
			symmetry_pair = null
	
	func set_curve_index(i):
		curve_index = i
		visual_node.set_curve_index(i)
	
	func set_position(pos):
		visual_node.position = pos
	
	func get_position():
		return visual_node.position
	
	func hide_point():
		hidden = true
		visual_node.visible = false
	
	func show_point():
		hidden = false
		visual_node.visible = true



var ui_control : Control
enum EditorMode {SHAPE_MODE, COLOR_MODE}
var editor_mode : EditorMode = EditorMode.SHAPE_MODE
enum Mode {ADD_MODE, EDIT_MODE, DELETE_MODE}
var current_mode = Mode.ADD_MODE
var symmetry_mode : bool = false
var screen_size : Vector2
var table_rect : Rect2i
var detection_grid_ready : bool = false
var detection_grid : Array = []
var screen_pressed : bool = false
var selected_point : LeafPoint
var leaf_points : Array[LeafPoint] = []
var vein_paths : Array = []
var vein_visuals : Array = []
@onready var leaf_poly = $Polygon2D
@onready var leaf_origin = $LeafOrigin
@onready var leaf_curve : Curve2D = Curve2D.new()
@onready var leaf_color : Color = Color(0.2, 0.8, 0.1, 1.0)
@onready var leaf_texture : Texture2D


func _ready():
	screen_size = get_window().get_size()
	recenter_origin()


func load_data(data):
	leaf_texture = data
	build_default()


func build_default():
	leaf_curve = Curve2D.new()
	leaf_curve.set_bake_interval(5)
	add_point(leaf_origin.position, -1, false)
	starting_leaf()


func _input(event):
	if event is InputEventMouseButton:
		screen_pressed = event.pressed
		if screen_pressed == false:
			selected_point = null
		if current_mode > 0:
			pass
	if event is InputEventMouseMotion:
		if editor_mode == EditorMode.SHAPE_MODE:
			if screen_pressed and selected_point != null:
				move_point(selected_point, event.relative)


func _on_ui_resized():
	if leaf_origin != null:
		recenter_origin()
	screen_size = get_window().get_size()
	node_scale = Vector2(0.1, 0.1).lerp(
		Vector2(1.0, 1.0), 
		inverse_lerp(1000, 4500, screen_size.length())
		)
	if leaf_points.size() > 0:
		for lp in leaf_points:
			lp.visual_node.set_point_scale(node_scale)


func _on_ui_update_table_constraints(rect):
	table_rect = rect


func recenter_origin():
	var old_position = leaf_origin.position
	var new_position = Vector2(get_window().get_size())
#	if table_rect.size != Vector2i(0, 0):
#		new_position = Vector2(table_rect.size)
	new_position.x *= 0.5
	new_position.y *= 0.75
	leaf_origin.position = new_position
	if leaf_curve.get_point_count() > 0:
		slide_curve(old_position - new_position)
		maximize_curve_scale(new_position)
		fit_curve_scale(new_position, get_window().get_size().x, new_position.y)
		update_leaf_visual(round_points_enabled)


func slide_curve(offset : Vector2):
	for i in leaf_curve.get_point_count():
		leaf_curve.set_point_position(i, leaf_curve.get_point_position(i) - offset)
		leaf_points[i].visual_node.position -= offset


func maximize_curve_scale(anchor : Vector2):
	var center = leaf_origin.position
	center.y *= 0.5
#	center.y = lerp(float(table_rect.position.y), leaf_origin.position.y, 0.5)
	var closest_distance : float = 100000
	var closest_point = null
	for i in leaf_curve.get_point_count():
		var bound = Vector2.ZERO
		var i_pos = leaf_curve.get_point_position(i)
		if i_pos.x <= center.x:
			bound.x = 5
		else:
			bound.x = DisplayServer.screen_get_size().x - 5
		if i_pos.y <= center.y:
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


func fit_curve_scale(anchor : Vector2, w : float, h : float):
	var bad_actors : Array = []
	var safe_area_top = DisplayServer.get_display_safe_area().position.y
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
			if i_pos.y < safe_area_top: 
				safe = false
				bound.y = safe_area_top
			if i_pos.y > (h - 5):
				safe = false
				bound.y = h - 5
			if !safe:
				bad_actors.append([i, i_pos, bound])
	if bad_actors.size() > 0:
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
	top_point.y = DisplayServer.get_display_safe_area().position.y + 60
	var center_point = leaf_origin.position.lerp(top_point, 0.3)
	var left_point = center_point
	left_point.x = left_point.x * 0.7
	var right_point = center_point
	right_point.x = get_window().get_size().x - left_point.x
	add_point(left_point, -1, false)
	add_point(top_point, -1, false)
	add_point(right_point, -1, false)
	add_point(leaf_origin.position, -1, false)


func _on_table_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == 1:
				if editor_mode == EditorMode.SHAPE_MODE \
				and current_mode == Mode.ADD_MODE:
					if leaf_curve.get_point_count() > 3:
						detect_intersection(event.position, false)
					else:
						add_point(event.position, -1, false)


func point_selected(visual : Area2D):
	var leaf_point = null
	leaf_point = find_leafpoint_from_visual(visual)
	if leaf_point != null:
		if visual.position != leaf_origin.position:
			selected_point = leaf_point
		else:
			selected_point = null
		if editor_mode == EditorMode.SHAPE_MODE \
		and current_mode == Mode.DELETE_MODE:
			remove_point(leaf_point)


func point_tapped(visual : Area2D):
	if round_points_enabled:
		var leafpoint = null
		leafpoint = find_leafpoint_from_visual(visual)
		if leafpoint != null and visual.position != leaf_origin.position:
			if editor_mode == EditorMode.SHAPE_MODE \
			and current_mode == Mode.EDIT_MODE:
				switch_point_type(leafpoint)
				visual.set_node_type(leafpoint.round_point)
				update_round_neighbors(leafpoint)
				if symmetry_mode and leafpoint.symmetry:
					switch_point_type(leafpoint.symmetry_pair)
					leafpoint.symmetry_pair.visual_node.set_node_type
					(
						leafpoint.round_point
					)
					update_round_neighbors(leafpoint.symmetry_pair)
			update_leaf_visual(round_points_enabled)
	else:
		print("round_points_enabled == false")


func detect_intersection(pos : Vector2, sym_pair : bool):
	var baked_points = leaf_curve.get_baked_points()
	var target_point = leaf_curve.get_closest_point(pos)
	if target_point.distance_squared_to(pos) < 10000:
		## Find Closest two
		## Start by getting each Baked Point
		## Add in the index of our Target Point from the Baked Point Array to a new List
		## Then Go through each Point of the Leaf Curve, and find the closest baked point.
		## Add the Index of the that closest baked point into the List, and Sort.
		## Index Position of the Target Point should mirror the desired index position \
		## for the intersection.
		var closest_points = [target_point]
		for i in leaf_curve.get_point_count() - 1:
			var point_position = leaf_curve.get_point_position(i)
			var closest_baked_point = leaf_curve.get_closest_point(point_position)
			closest_points.append(closest_baked_point)
		var baked_indeces = []
		for c in closest_points:
			if baked_points.has(c):
				baked_indeces.append(baked_points.find(c))
			else:
				var distance = 10000
				var baked_point = baked_points[0]
				for b in baked_points:
					var dist = b.distance_squared_to(c)
					if dist < distance:
						distance = dist
						baked_point = b
				if baked_points.has(baked_point):
					baked_indeces.append(baked_points.find(baked_point))
				else:
					print("Thumbs Down Emoji")
		var baked_intersect_index = baked_indeces[0]
		baked_indeces.sort()
		var intersect_index = baked_indeces.find(baked_intersect_index)
		add_point(pos, intersect_index, sym_pair)


func add_point(pos : Vector2, idx : int, sym_pair : bool):
	var leaf_point_node = leaf_point_object.instantiate()
	leaf_point_node.spawn_node(node_scale)
	leaf_point_node.clicked.connect(Callable(self, "point_selected"))
	leaf_point_node.tapped.connect(Callable(self, "point_tapped"))
	leaf_point_node.position = pos
	if pos == leaf_origin.position:
		leaf_point_node.set_origin_visual()
	self.add_child(leaf_point_node)
	leaf_curve.add_point(pos, Vector2.ZERO, Vector2.ZERO, idx)
	var curve_index = idx
	if idx < 0:
		curve_index = leaf_curve.get_point_count() - 1
	var new_point = LeafPoint.new(leaf_point_node, false, curve_index, false, null)
	leaf_points.insert(curve_index, new_point)
	update_leaf_point_indeces(curve_index)
#	update_round_neighbors(new_point)
	update_leaf_visual(round_points_enabled)
	update_leaf_shape()
	if symmetry_mode:
		if !sym_pair:
			var center = leaf_origin.get_position().x
			var flip = center - pos.x
			detect_intersection(Vector2(center + flip, pos.y), true)
		else:
			pair_symmetry_points()


func hide_points(points : Array[LeafPoint]):
	for lp in points:
		lp.hide_point()


func show_points(points : Array[LeafPoint]):
	for lp in points:
		lp.show_point()


func remove_point(leaf_point : LeafPoint):
	if leaf_points.size() > 4:
		var previous_index = leaf_point.curve_index - 1
		leaf_curve.remove_point(leaf_point.curve_index)
		leaf_points.remove_at(leaf_point.curve_index)
		leaf_point.queue_free()
		update_leaf_point_indeces(previous_index)
		if round_points_enabled:
			update_round_neighbors(leaf_points[previous_index])
		update_leaf_visual(round_points_enabled)
		update_leaf_shape()


func update_leaf_point_indeces(range_start : int):
	for i in range(range_start, leaf_curve.get_point_count()):
		if is_instance_valid(leaf_points[i]):
			leaf_points[i].set_curve_index(i)


func pair_symmetry_points():
	var side_a = []
	var side_b = []
	var origin_a = 0
	var origin_b = leaf_points.size() - 1
	var workable_point_count = origin_b - 1
	var even = false
	var midpoint = (leaf_points.size() / 2) - 1
	if workable_point_count >= 2:
		if workable_point_count % 2 == 0:
			even = true
		if !even:
			midpoint = leaf_points.size() / 2
		for i in leaf_points.size():
			if i != origin_a and i != origin_b:
				if even:
					if i <= midpoint:
						side_a.append(leaf_points[i])
					else:
						side_b.append(leaf_points[i])
				else:
					if i < midpoint:
						side_a.append(leaf_points[i])
					elif i > midpoint:
						side_b.append(leaf_points[i])
	side_b.reverse()
	if side_a.size() == side_b.size():
		for i in side_a.size():
			var rand_color = Color.from_hsv(randf(), 0.8, 0.8, 1.0)
			side_a[i].associate_pair(side_b[i])
			side_a[i].side_a = true
			side_a[i].visual_node.set_color(rand_color)
			side_b[i].visual_node.set_color(rand_color)
			var pos_a = leaf_curve.get_point_position(side_a[i].curve_index)
			if pos_a.x > leaf_origin.position.x:
				pos_a.x += leaf_origin.position.x - pos_a.x
				set_point_position(side_a[i], pos_a)
			var pos_b = pos_a
			pos_b.x = leaf_origin.position.x
			pos_b.x += leaf_origin.position.x - pos_a.x
			set_point_position(side_b[i], pos_b)
			if side_a[i].round_point != side_b[i].round_point and round_points_enabled:
				switch_point_type(side_b[i])
				side_b[i].visual_node.set_node_type(side_b[i].round_point)
				update_round_neighbors(side_b[i])
		if !even:
			var pos_center = leaf_curve.get_point_position(midpoint)
			pos_center.x = leaf_origin.position.x
			set_point_position(leaf_points[midpoint], pos_center)
			leaf_points[midpoint].midpoint = true
		update_leaf_visual(round_points_enabled)
	else:
		print("ERROR Symmetry Sides are uneven... somehow")


func break_symmetry_points():
	for p in leaf_points:
		p.break_pair()


func find_leafpoint_from_visual(visual : Area2D):
	if leaf_points.size() > 0:
		for lp in leaf_points:
			if lp.visual_node == visual:
				return lp
				break


func update_round_point(leaf_point):
	## Establish working points
	var before_pos = leaf_curve.get_point_position(leaf_point.curve_index - 1)
	var after_pos = leaf_curve.get_point_position(leaf_point.curve_index + 1)
	var leaf_point_pos = leaf_curve.get_point_position(leaf_point.curve_index)
	## Find the Floor and Height of the super-imposed rectangle
	var mid_lower_pos = before_pos.lerp(after_pos, 0.5)
	var height_vector = (leaf_point_pos - mid_lower_pos)
	var vec_to_mid = mid_lower_pos - before_pos
	var angle_to_height = vec_to_mid.angle_to(height_vector)
	var outer_curve = angle_to_height <= 0.0
	var mag = height_vector.length()
	var dir = vec_to_mid.normalized()
	var clamped_tan_vec = dir.rotated(PI / 2 * -1 if outer_curve else PI / 2) * mag
	## Differentiate influence to corners based on neighbors
	var before_influence = in_dir_force
	var after_influence = out_dir_force
	var before_height = in_tangent_height
	var after_height = out_tangent_height
	if leaf_points[leaf_point.curve_index - 1].round_point:
		before_influence = in_dir_force_round
		before_height = in_tangent_height_round
	if leaf_points[leaf_point.curve_index + 1].round_point:
		after_influence = out_dir_force_round
		after_height = out_tangent_height_round
	## Find the upper corners of the super-imposed rectangle
	var before_tang = before_pos + (clamped_tan_vec * before_height)
	var after_tang = after_pos + (clamped_tan_vec * after_height)
	## Calculate Vector Normal to the corners
	var before_target = leaf_point_pos.lerp(before_tang, before_influence) - leaf_point_pos
	var after_target = leaf_point_pos.lerp(after_tang, after_influence) - leaf_point_pos
	leaf_curve.set_point_in(leaf_point.curve_index, before_target)
	leaf_curve.set_point_out(leaf_point.curve_index, after_target)
	leaf_point.visual_node.set_in_out_points(before_target, after_target)


func move_point(leafpoint : LeafPoint, relative : Vector2):
#	leafpoint.visual_node.translate(relative)
	leafpoint.visual_node.clamped_translate(relative, table_rect)
	if symmetry_mode:
		if leafpoint.symmetry:
			var new_pos = leafpoint.visual_node.position
			if leafpoint.side_a:
				new_pos.x = clamp(new_pos.x, 0, leaf_origin.position.x)
			else:
				new_pos.x = clamp(new_pos.x, leaf_origin.position.x, screen_size.x)
			var difference = leaf_origin.position.x - new_pos.x
			var mirror_pos = new_pos
			mirror_pos.x = leaf_origin.position.x + difference
			leaf_curve.set_point_position(
				leafpoint.symmetry_pair.curve_index, mirror_pos)
			leafpoint.symmetry_pair.set_position(mirror_pos)
			if round_points_enabled:
				update_round_neighbors(leafpoint.symmetry_pair)
		elif leafpoint.midpoint:
			leafpoint.visual_node.position.x = leaf_origin.position.x
	leaf_curve.set_point_position(
		leafpoint.curve_index, 
		leafpoint.visual_node.position)
	if round_points_enabled:
		update_round_neighbors(leafpoint)
	update_leaf_visual(round_points_enabled)
	update_leaf_shape()


func set_point_position(leafpoint, pos):
	leafpoint.set_position(pos)
	leaf_curve.set_point_position(leafpoint.curve_index, pos)


func update_round_neighbors(leafpoint : LeafPoint):
	## Update Neighbor points first!
	if leaf_points[leafpoint.curve_index - 1].round_point:
		update_round_point(leaf_points[leafpoint.curve_index - 1])
	if leaf_points[leafpoint.curve_index + 1].round_point:
		update_round_point(leaf_points[leafpoint.curve_index + 1])
	if leaf_points[leafpoint.curve_index].round_point:
		update_round_point(leaf_points[leafpoint.curve_index])


func switch_point_type(leaf_point):
	if round_points_enabled:
		if leaf_point.round_point:
			leaf_curve.set_point_in(leaf_point.curve_index, Vector2.ZERO)
			leaf_curve.set_point_out(leaf_point.curve_index, Vector2.ZERO)
			leaf_point.round_point = false
		else:
			update_round_point(leaf_point)
			leaf_point.round_point = true


func update_leaf_visual(hd : bool):
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
		draw_leaf_veins()
	else:
		leaf_poly.visible = false


func update_leaf_shape():
	var simple_points : PackedVector2Array = []
	simple_points.append(leaf_origin.position)
	for lp in leaf_points:
		var pos = lp.visual_node.position
		if pos != leaf_origin.position:
			simple_points.append(pos)
	$Area2D/CollisionPolygon2D.set_polygon(simple_points)


func draw_leaf_shape(points : PackedVector2Array):
	leaf_poly.set_polygon(points)


func draw_leaf_texture(points : PackedVector2Array):
	var count = points.size()
	var uvs : PackedVector2Array = PackedVector2Array()
	var screen_uv_0 = table_rect.position
	var screen_uv_1 = table_rect.size
	screen_uv_1.y = leaf_origin.position.y
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
	var coord_a = screen_uv_0
	var coord_b = screen_uv_1
	if stretch_x:
		coord_a.x = space_uv_0.x
		coord_b.x = space_uv_1.x
	if stretch_y:
		coord_a.y = space_uv_0.y
		coord_b.y = space_uv_1.y
	emit_signal("color_bounds", coord_a, coord_b)
	var printout_array = []
	for i in count:
		var baked_point_pos = points[i]
		var percent = float(i) / float(count - 1)
		var scale_position = Vector2(
				inverse_lerp(screen_uv_0.x, screen_uv_1.x, baked_point_pos.x),
				inverse_lerp(screen_uv_0.y, screen_uv_1.y, baked_point_pos.y))
		if stretch_x:
			scale_position.x = inverse_lerp(
				space_uv_0.x, space_uv_1.x, baked_point_pos.x
			)
		if stretch_y:
			scale_position.y = inverse_lerp(
				space_uv_0.y, space_uv_1.y, baked_point_pos.y
			)
		var scale_texture = Vector2(
				lerp(0.0, texture_size.x, scale_position.x),
				lerp(0.0, texture_size.y, scale_position.y))
		uvs.append(scale_texture)
	leaf_poly.texture = leaf_texture
	leaf_poly.uv = uvs


func draw_curve_shape():
	if leaf_curve.get_point_count() >= 3:
		leaf_poly.set_polygon(leaf_curve.get_baked_points())


func draw_leaf_veins():
	if vein_visuals.size() > 0:
		for vis in vein_visuals:
			vis.queue_free()
		vein_visuals.clear()
	if vein_paths.size() > 0:
		for vp in vein_paths:
			for vec in vp:
				var new_vein_sprite = Sprite2D.new()
				new_vein_sprite.texture = vein_texture
				new_vein_sprite.position = vec
				new_vein_sprite.scale = Vector2(0.3, 0.3)
				vein_visuals.append(new_vein_sprite)
				add_child(new_vein_sprite)


func _on_Mode_item_selected(index):
	current_mode = index


func _on_ui_symmetry(mode):
	symmetry_mode = mode
	if mode:
		pair_symmetry_points()
	else:
		break_symmetry_points()


func _on_Maximize_pressed():
	maximize_curve_scale(leaf_origin.position)


func _on_coloring_display_brush_image(tex):
	leaf_poly.texture = tex


func _on_coloring_apply_brush_image():
	leaf_texture = leaf_poly.texture
	emit_signal("update_canvas_tex", leaf_texture)



func _on_ui_mode_changed(mode):
	editor_mode = mode
	if leaf_points.size() > 0:
		if mode == EditorMode.COLOR_MODE:
			hide_points(leaf_points)
		elif mode == EditorMode.SHAPE_MODE:
			show_points(leaf_points)
