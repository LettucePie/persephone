extends Node2D


@export var leaf_point_object : PackedScene
@export var node_scale: Vector2 = Vector2(0.1, 0.1)
@export var leaf_gradient_default: Gradient
@export var leaf_texture_default: Texture2D
@export var vein_texture : Texture2D
#@export var grid_size : float = 10.0
@export var grid_density : int = 12
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



var ui_control : Control
enum EditorMode {SHAPE_MODE, VEIN_MODE, COLOR_MODE}
var editor_mode : EditorMode = EditorMode.SHAPE_MODE
enum Mode {ADD_MODE, EDIT_MODE, DELETE_MODE}
var current_mode = Mode.ADD_MODE
var symmetry_mode : bool = false
var screen_size : Vector2
var detection_grid_ready : bool = false
var detection_grid : Array = []
var screen_pressed : bool = false
var selected_point : LeafPoint
var leaf_points : Array = []
var vein_paths : Array = []
var vein_visuals : Array = []
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
	add_point(leaf_origin.position, -1, false)
	print("Building Rest of the Leaf")
	starting_leaf()
	build_detection_grid()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_R:
				print("Randomizing UV End")
				randomize()
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
	add_point(left_point, -1, false)
	add_point(top_point, -1, false)
	add_point(right_point, -1, false)
	add_point(leaf_origin.position, -1, false)


func build_detection_grid():
#	var x_mod = grid_size * screen_size.aspect()
#	var y_mod = grid_size
#	var mod_vec = Vector2(x_mod, y_mod)
#	print(mod_vec)
	var x_div = screen_size.x / grid_density
	var y_div = leaf_origin.position.y / grid_density
	var pos_array : PackedVector2Array = []
	for y_pos in range(1, grid_density - 1):
		for x_pos in range(1, grid_density - 1):
			pos_array.append(Vector2(x_pos * x_div, y_pos * y_div))
	if detection_grid.size() > 0:
		for d in detection_grid:
			d.queue_free()
	detection_grid.clear()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 2.5
	for p in pos_array:
		var new_area = Area2D.new()
		var new_coll_shape = CollisionShape2D.new()
		new_coll_shape.set_shape(circle_shape)
		new_area.add_child(new_coll_shape)
		new_area.monitoring = true
		new_area.input_pickable = false
		new_area.set_collision_layer_value(1, false)
		new_area.set_collision_layer_value(4, true)
		new_area.set_collision_mask_value(1, false)
		new_area.set_collision_mask_value(4, true)
		new_area.position = p
		new_area.name = "X_" + str(int(p.x)) + "_Y_" + str(int(p.y))
		detection_grid.append(new_area)
		add_child(new_area)
	detection_grid_ready = true


func _on_table_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print(event.position)
			print(event.button_index)
			if event.button_index == 1:
				print("Left Click")
				if editor_mode == EditorMode.SHAPE_MODE \
				and current_mode == Mode.ADD_MODE:
					if leaf_curve.get_point_count() > 3:
						detect_intersection(event.position, false)
					else:
						add_point(event.position, -1, false)
				## Used to check for Edit Mode and Delete Mode here
				## Decided to scrap that because using this system would require
				## Unnecessary filtering to find the closest leafpoint to target
				## with desired action.
				## By using the Built In input detections on each leaf point
				## instead, we can eliminate that entire process of filtering.
			if event.button_index == 2:
				print("Right Click")
			if event.button_index == 3:
				print("Middle Click")


func point_selected(visual : Area2D):
	print("Point Selected: ", visual)
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
	print("VisualNode Tapped: ", visual)
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
				leafpoint.symmetry_pair.visual_node.set_node_type(leafpoint.round_point)
				update_round_neighbors(leafpoint.symmetry_pair)
		elif editor_mode == EditorMode.VEIN_MODE:
			print("Tapping LeafPoint: ", leafpoint, " In Vein Editor Mode")
		update_leaf_visual(true)


func detect_intersection(pos : Vector2, sym_pair : bool):
	print("Looking for Intersection near point ", pos)
	var baked_points = leaf_curve.get_baked_points()
	print("Baked Points Size: ", baked_points.size())
	var target_point = leaf_curve.get_closest_point(pos)
	print("Target Point: ", target_point, " Click_Pos: ", pos)
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
				print("Baked Points cannot find ", c)
				var distance = 10000
				var baked_point = baked_points[0]
				for b in baked_points:
					var dist = b.distance_squared_to(c)
					if dist < distance:
						distance = dist
						baked_point = b
				print("Additional Filtering brought us point ", baked_point, " from baked_points")
				if baked_points.has(baked_point):
					baked_indeces.append(baked_points.find(baked_point))
				else:
					print("Literally what the fuck.")
		print("Baked Indeces pre-sort: ", baked_indeces)
		var baked_intersect_index = baked_indeces[0]
		baked_indeces.sort()
		print("Baked Indeces post-sort: ", baked_indeces)
		print("Intersection found at index, ", baked_intersect_index, " among baked points")
		var intersect_index = baked_indeces.find(baked_intersect_index)
		print("Intersect index rests between point, ", intersect_index - 1, " and ", intersect_index + 1)
		add_point(pos, intersect_index, sym_pair)


func add_point(pos : Vector2, idx : int, sym_pair : bool):
	print("Add Point Called with Pos ", pos, " and idx: ", idx)
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
	update_leaf_visual(true)
	update_leaf_shape()
	map_leaf_veins_v2()
	if symmetry_mode:
		if !sym_pair:
			print("Add in sym pair coords")
			var center = leaf_origin.get_position().x
			var flip = center - pos.x
			detect_intersection(Vector2(center + flip, pos.y), true)
		else:
			pair_symmetry_points()


func remove_point(leaf_point : LeafPoint):
	print("Remove LeafPoint: ", leaf_point)
	if leaf_points.size() > 4:
		var previous_index = leaf_point.curve_index - 1
		leaf_curve.remove_point(leaf_point.curve_index)
		leaf_points.remove_at(leaf_point.curve_index)
		leaf_point.queue_free()
		update_leaf_point_indeces(previous_index)
		update_round_neighbors(leaf_points[previous_index])
		update_leaf_visual(true)
		update_leaf_shape()
		map_leaf_veins_v2()


func update_leaf_point_indeces(range_start : int):
	for i in range(range_start, leaf_curve.get_point_count()):
		if is_instance_valid(leaf_points[i]):
			leaf_points[i].set_curve_index(i)


func pair_symmetry_points():
	print("Pairing Symmetry Points")
	var side_a = []
	var side_b = []
	var origin_a = 0
	var origin_b = leaf_points.size() - 1
	print("Origin A: ", origin_a, " Origin B: ", origin_b)
	var workable_point_count = origin_b - 1
	print("Workable Point Count: ", workable_point_count)
	var even = false
	var midpoint = (leaf_points.size() / 2) - 1
	print("midpoint Starting at: ", midpoint)
	if workable_point_count >= 2:
		print("Valid number of points")
		if workable_point_count % 2 == 0:
			print("Even number of workable points")
			even = true
		if !even:
			midpoint = leaf_points.size() / 2
			print(midpoint)
			print("midpoint Assigned to: ", midpoint)
		print("Even Number of Points: ", even)
		for i in leaf_points.size():
			if i != origin_a and i != origin_b:
				print(i, " valid!")
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
	print("SIDE A : ", side_a)
	print("SIDE B : ", side_b)
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
			if side_a[i].round_point != side_b[i].round_point:
				switch_point_type(side_b[i])
				side_b[i].visual_node.set_node_type(side_b[i].round_point)
				update_round_neighbors(side_b[i])
		if !even:
			var pos_center = leaf_curve.get_point_position(midpoint)
			pos_center.x = leaf_origin.position.x
			set_point_position(leaf_points[midpoint], pos_center)
			leaf_points[midpoint].midpoint = true
		update_leaf_visual(true)
	else:
		print("ERROR Symmetry Sides are uneven... somehow")


func break_symmetry_points():
	print("Breaking Symmetry Points")
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
	leafpoint.visual_node.translate(relative)
	if symmetry_mode:
		if leafpoint.symmetry:
			print("Moving Symm Pair")
			var new_pos = leafpoint.visual_node.position
			if leafpoint.side_a:
				print("Side A")
				new_pos.x = clamp(new_pos.x, 0, leaf_origin.position.x)
			else:
				print("Side B")
				new_pos.x = clamp(new_pos.x, leaf_origin.position.x, screen_size.x)
			var difference = leaf_origin.position.x - new_pos.x
			var mirror_pos = new_pos
			mirror_pos.x = leaf_origin.position.x + difference
			leaf_curve.set_point_position(leafpoint.symmetry_pair.curve_index, mirror_pos)
			leafpoint.symmetry_pair.set_position(mirror_pos)
			update_round_neighbors(leafpoint.symmetry_pair)
		elif leafpoint.midpoint:
			print("Moving Midpoint")
			leafpoint.visual_node.position.x = leaf_origin.position.x
	leaf_curve.set_point_position(leafpoint.curve_index, leafpoint.visual_node.position)
	update_round_neighbors(leafpoint)
	update_leaf_visual(true)
	update_leaf_shape()
	map_leaf_veins_v2()


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
	if leaf_point.round_point:
		leaf_curve.set_point_in(leaf_point.curve_index, Vector2.ZERO)
		leaf_curve.set_point_out(leaf_point.curve_index, Vector2.ZERO)
		leaf_point.round_point = false
	else:
		update_round_point(leaf_point)
		leaf_point.round_point = true


func map_leaf_veins():
	vein_paths.clear()
	print("Find Highest Point from Origin")
	var baked_points = leaf_curve.get_baked_points()
	var origin_pos : Vector2 = leaf_origin.position
	var high_center = origin_pos
	for bp in baked_points:
		if bp.x > origin_pos.x - 3 and bp.x < origin_pos.x + 3:
			if bp.y < high_center.y:
				high_center = bp
	print("Find Farthest Point from Origin")
	var farthest_point = leaf_points[0]
	var farthest_dist = 0.0
	for lp in leaf_points:
		var dist_to_point = lp.visual_node.position.distance_to(origin_pos)
		if dist_to_point > farthest_dist:
			farthest_point = lp
			farthest_dist = dist_to_point
	print("Find Midpoints for origin to Highest, and Highest to Farthest")
	var midpoint_origin = origin_pos.lerp(high_center, 0.5)
	var midpoint_farthest = farthest_point.visual_node.position.lerp(high_center, 0.5)
	print("Interpolate Points")
	var main_path : PackedVector2Array = []
	for i in 10:
		main_path.append(
			origin_pos.bezier_interpolate(
				midpoint_origin, 
				midpoint_farthest, 
				farthest_point.visual_node.position, 
				float(i) / 10.0)
		)
	vein_paths.append(main_path)


func map_leaf_veins_v2():
	vein_paths.clear()
	print("Find Highest Point from Origin")
	var baked_points = leaf_curve.get_baked_points()
	var origin_pos : Vector2 = leaf_origin.position
	var high_center = origin_pos
	for bp in baked_points:
		if bp.x > origin_pos.x - 3 and bp.x < origin_pos.x + 3:
			if bp.y < high_center.y:
				high_center = bp
	print("Find Farthest Point from Origin")
	var farthest_point = leaf_points[0]
	var farthest_dist = 0.0
	for lp in leaf_points:
		var dist_to_point = lp.visual_node.position.distance_to(origin_pos)
		if dist_to_point > farthest_dist:
			farthest_point = lp
			farthest_dist = dist_to_point
	print("Find Midpoints for origin to Highest, and Highest to Farthest")
	var midpoint_origin = origin_pos.lerp(high_center, 0.5)
	var midpoint_farthest = farthest_point.visual_node.position.lerp(high_center, 0.5)
	print("Interpolate Points")
	var main_path : PackedVector2Array = []
	var min_vec = farthest_point.visual_node.position
	var max_vec = origin_pos
	if min_vec > origin_pos:
		max_vec = min_vec
		min_vec = origin_pos
	var valid_points = $Area2D.bundle_relevant_points(min_vec, max_vec)
	for i in 10:
		var interpos = origin_pos.bezier_interpolate(
			midpoint_origin, 
			midpoint_farthest, 
			farthest_point.visual_node.position, 
			float(i) / 10.0)
		var smallest_dist = 100000
		var safest_point = interpos
		for vp in valid_points:
			var dist = interpos.distance_squared_to(vp)
			if dist < smallest_dist:
				smallest_dist = dist
				safest_point = vp
		main_path.append(safest_point)
		print("Try making this a test instead of a search")
		print("Initial curve looks good, make sure it's close enough to a valid point or set of points")
	vein_paths.append(main_path)


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
		print("Leaf has too few points")


func update_leaf_shape():
	var simple_points : PackedVector2Array = []
	simple_points.append(leaf_origin.position)
	for lp in leaf_points:
		var pos = lp.visual_node.position
		if pos != leaf_origin.position:
			simple_points.append(pos)
	$Area2D/CollisionPolygon2D.set_polygon(simple_points)


func draw_leaf_shape(points : PackedVector2Array):
#	print("Setting Leaf Shape")
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
	print("Current Mode: ", current_mode)


func _on_ui_symmetry(mode):
	symmetry_mode = mode
	if mode:
		pair_symmetry_points()
	else:
		break_symmetry_points()


func _on_ui_resized():
	if leaf_origin != null:
		recenter_origin()
	screen_size = get_window().get_size()


func _on_Maximize_pressed():
#	print("Maximize Curve Pressed")
	maximize_curve_scale(leaf_origin.position)


func _on_adjustment_slide_changed_value(target, value):
	if target == 0:
		in_tangent_height = value
	elif target == 1:
		out_tangent_height = value
	elif target == 2:
		in_dir_force = value
	elif target == 3:
		out_dir_force = value
	print("Updating Square_Point float params")
	for lp in leaf_points:
		if lp.round_point:
			update_round_point(lp)
	update_leaf_visual(true)


func _on_adjustment_slide_changed_round_value(target, value):
	if target == 0:
		in_tangent_height_round = value
	elif target == 1:
		out_tangent_height_round = value
	elif target == 2:
		in_dir_force_round = value
	elif target == 3:
		out_dir_force_round = value
	print("Updating Round_Point float params")
	for lp in leaf_points:
		if lp.round_point:
			update_round_point(lp)
	update_leaf_visual(true)
