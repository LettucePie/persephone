extends Node2D

## Testing
@export var dot : PackedScene

@export var default_curve : Curve
@export var influence_curve : Curve

class BranchLayer:
	var layer : int = 0
	var layer_node : Node2D
	var master_branch_copy : Branch = null
	var population : float = 0.0
	var population_min : int = 1
	var population_max : int = 1
	var branches : Array = []
	var growth_points : Array = []


class Branch:
	var line : Line2D = null
	## Branch Shape Properties
	var start_point : Vector2 = Vector2.ZERO
	var start_normal : Vector2 = Vector2.RIGHT
	var length : float = 1.0
	var length_random : float = 0.0
	var jagginess : float = 0.0
	var upward_direction : Vector2 = Vector2.UP
	var upward_angle : float = 0.0
	var upward_influence : float = 0.0
	var start_width : float = 20.0
	var end_width : float = 1.0
	## Growth Point Properties
	var carries_leaves : bool = false
	var population : float = 0.4
	var cluster_random : bool = true
	var cluster_gap : int = 0
	var cluster_size : int = 0
	var growth_coverage : float = 0.5
	var growth_coverage_end_to_base : bool = true
	var force_symmetry : bool = false
	var leaf_size : float = 0.0
	var leaf_size_random : float = 0.0
	
	
	func duplicate():
		var new = Branch.new()
		new.line = line.duplicate()
		new.start_point = start_point
		new.start_normal = start_normal
		new.length = length
		new.length_random = length_random
		new.jagginess = jagginess
		new.upward_direction = upward_direction
		new.upward_angle = upward_angle
		new.upward_influence = upward_influence
		new.start_width = start_width
		new.end_width = end_width
		new.carries_leaves = carries_leaves
		new.population = population
		new.cluster_random = cluster_random
		new.cluster_gap  = cluster_gap
		new.cluster_size = cluster_size
		new.growth_coverage = growth_coverage
		new.growth_coverage_end_to_base = growth_coverage_end_to_base
		new.force_symmetry = force_symmetry
		new.leaf_size = leaf_size
		new.leaf_size_random = leaf_size_random
		return new
	
	
	func apply_new_settings(new : Branch, ignore_start : bool):
		if ignore_start == false:
			start_point = new.start_point
			start_normal = new.start_normal
			start_width = new.start_width
		length = new.length
		length_random = new.length_random
		jagginess = new.jagginess
		upward_direction = new.upward_direction
		upward_angle = new.upward_angle
		upward_influence = new.upward_influence
		end_width = new.end_width
		carries_leaves = new.carries_leaves
		population = new.population
		cluster_random = new.cluster_random
		cluster_gap = new.cluster_gap
		cluster_size = new.cluster_size
		growth_coverage = new.growth_coverage
		growth_coverage_end_to_base = new.growth_coverage_end_to_base
		force_symmetry = new.force_symmetry
		leaf_size = new.leaf_size
		leaf_size_random = new.leaf_size_random


class GrowthPoint:
	var point_position : Vector2 = Vector2.ZERO
	var point_normal : Vector2 = Vector2.RIGHT
	var point_width : float = 0.0


var branch_layers : Array
#var branches : Array


func _ready():
	branch_layers.clear()
	make_trunk()
	draw_all_branches()


func make_trunk():
	var trunk : Branch = Branch.new()
	var screen_size = Vector2(get_window().get_size())
	trunk.start_point = screen_size
	trunk.start_point.x *= 0.5
	trunk.start_point.y *= 0.7
	trunk.start_normal = Vector2.UP
	trunk.length = trunk.start_point.y - (screen_size.y * 0.2)
#	trunk.jagginess = 1.0
#	trunk.jagginess = 0.5
	trunk.jagginess = 0.15
	trunk.cluster_random = false
	trunk.cluster_gap = 2
	trunk.cluster_size = 0
	make_layer(0, setup_branch_line(trunk))


func make_default_branch_layer():
	var branch : Branch = Branch.new()
	


func make_layer(layer_num : int, master_branch : Branch):
	if layer_num < branch_layers.size():
		print("ERROR** Layer Number: ", layer_num, " already occupied.")
		## Replace branch?
	else:
		var new_layer : BranchLayer = BranchLayer.new()
		new_layer.layer = layer_num
		new_layer.master_branch_copy = master_branch
		var new_layer_node = Node2D.new()
		new_layer_node.name = "Layer" + str(layer_num)
		new_layer.layer_node = new_layer_node
		add_child(new_layer_node)
		var previous_layer_growth_points = []
		if layer_num == 0:
			## Trunk Layer
			new_layer.population_min = 1
			new_layer.population_max = 1
			new_layer.population = 1.0
		else:
			previous_layer_growth_points = branch_layers.back().growth_points
			new_layer.population_min = 2 * layer_num
			new_layer.population_max = 18 * layer_num
			new_layer.population = 1.0
		populate_layer(new_layer, previous_layer_growth_points)
		map_out_growth_points(new_layer)
		branch_layers.append(new_layer)
#		draw_all_branches()


func populate_layer(layer : BranchLayer, growth_points : Array):
	print("Iterate over Start Points, making a new branch at each")
	if layer.layer == 0:
		print("Populating Trunk Layer... Ignore Start Points")
		var new_branch_copy = layer.master_branch_copy.duplicate()
		layer.layer_node.add_child(new_branch_copy.line)
		layer.branches.append(new_branch_copy)
	else:
		for growth_point in growth_points:
			var new_branch_copy = layer.master_branch_copy.duplicate()
			new_branch_copy.start_point = growth_point.point_position
			new_branch_copy.start_normal = growth_point.point_normal
			new_branch_copy.start_width = growth_point.point_width
			var modified_branch = setup_branch_line(new_branch_copy)
			layer.layer_node.add_child(modified_branch.line)
			layer.branches.append(modified_branch)


func bake_out_points(line : Line2D):
	var curve_trick : Curve2D = Curve2D.new()
	curve_trick.bake_interval = 10.0
	for p in line.points:
		curve_trick.add_point(p, Vector2.ZERO, Vector2.ZERO)
	return curve_trick.get_baked_points()
	curve_trick.free()


func map_out_growth_points(layer : BranchLayer):
	print("Iterate over fresh branches, gathering all viable growth points")
	for b in layer.branches:
		var baked_points = bake_out_points(b.line)
		if b.growth_coverage_end_to_base:
			baked_points.reverse()
		var end = baked_points.size() - 1
		var covered_points : PackedVector2Array = baked_points.slice(
			0,
			int(lerp(0, end, b.growth_coverage)))
		var coverage_range = range(0, covered_points.size())
		##
		## Apply gap
		## Objective is to allow player to make evenly spaced growth \
		## points.
		##
		if b.cluster_gap > 0:
			var counter = b.cluster_gap
			var removal_list = []
			for coverage_index in coverage_range:
				if counter <= 0:
#					print("Remove ", coverage_index)
					removal_list.append(coverage_index)
					counter = b.cluster_gap
				else:
					counter -= 1
			if removal_list.size() > 0:
				for remove in removal_list:
					coverage_range.erase(remove)
#			removal_list.free()
		##
		## Apply random
		## Objective is a bit self-explainatory. Shuffles all the \
		## available coverage area. 
		##
		if b.cluster_random:
			coverage_range.shuffle()
		##
		## Apply Cluster size within Population percent of Growth Coverage
		## Objective is iterate through a percent of the coverage area \
		## dictated by the float 0.0/1.0 "population". Upon reaching a \
		## point, add additional points dictated by "cluster_size".
		##
		## Hopefully, this allows groups/clusters of growth points.
		## This should work for wads/bundles of leaves.
		##
		var population_indeces : Array = []
		for i in range(0, int(lerp(0, coverage_range.size(), b.population))):
			## Spacing this out since it's a lot
			if !population_indeces.has(coverage_range[i]):
				population_indeces.append(coverage_range[i])
			##
			for cluster_i in range(
			coverage_range[i], 
			coverage_range[i] + b.cluster_size + 1):
				if !population_indeces.has(cluster_i) \
				and coverage_range.has(cluster_i):
					population_indeces.append(cluster_i)
		##
		var growth_points : Array = []
		##
		for p in population_indeces:
			##
			var new_growth_point : GrowthPoint = GrowthPoint.new()
			##
			var point_pos = covered_points[p]
			var angle_adjust = PI / 2
			if randf() > 0.5:
				angle_adjust = PI / -2
			var compare_point = p - 1
			if p == 0:
				compare_point = p + 1
			##
			var point_dir = point_pos.direction_to(covered_points[compare_point])
			point_dir = point_dir.rotated(angle_adjust)
			##
			var point_wid = b.start_width
			var baked_index_percent = float(p + 1) / float(end + 1)
			if b.growth_coverage_end_to_base:
				point_wid = lerp(b.end_width, b.start_width, baked_index_percent)
			else:
				point_wid = lerp(b.start_width, b.end_width, baked_index_percent)
			##
			new_growth_point.point_position = point_pos
			new_growth_point.point_normal = point_dir
			new_growth_point.point_width = point_wid
			growth_points.append(new_growth_point)
			##
			var test_dot = dot.instantiate()
			test_dot.position = point_pos
			add_child(test_dot)
		##
		if b.force_symmetry:
			for gp in growth_points:
				var mirrored_point : GrowthPoint = GrowthPoint.new()
				mirrored_point.point_position = gp.point_position
				mirrored_point.point_normal = Vector2(gp.point_normal)
				mirrored_point.point_width = gp.point_width
				mirrored_point.point_normal = mirrored_point.point_normal.rotated(PI)
				growth_points.append(mirrored_point)
		##
		layer.growth_points = growth_points


func draw_all_branches():
	for b_l in branch_layers:
		if b_l.branches.size() == 0:
			print("Fresh Layer, has no branches")
			print("Initialize Branches")
			if b_l.layer <= 0:
				print("Drawing Trunk")
			
			## Okay ... so
			## if the branch coverage area / population changes
			## then we need to change the number of branches in Branch Layer
			## if the population percent in the Branch Layer changes
			## then we need to change the number of branches in Branch Layer
			## weird...
			
			## But also we shouldn't be remaking every branch every time, so...
			## we should ask if these values are different, or worth checking first.
			## then adjust all the branches in the branch_layer
			
			## if the branch layer is empty in the first place, we need a
			## check for that, and an initial populating function.
			


func branch_modified(layer : BranchLayer):
	if layer.branches.size() > 0:
		for branch in layer.branches:
			branch.apply_new_settings(true)
			branch = setup_branch_line(branch)
			map_out_growth_points(layer)
	for branch_layer in branch_layers:
		if branch_layer.layer > layer.layer:
			print("Making relative adjustments to layer ", layer.layer)
			var growth_points = clamp(
				branch_layer.layer - 1, 
				0, 
				branch_layers.size())
			populate_layer(branch_layer, growth_points)
			map_out_growth_points(branch_layer)


func setup_branch_line(branch : Branch):
	if branch.line != null:
		branch.line.clear_points()
	else:
		branch.line = Line2D.new()
	branch.line.add_point(branch.start_point)
	var direction = branch.start_normal.slerp(
		Vector2.UP, 
		branch.upward_angle)
	var branch_points : PackedVector2Array = []
	var segment_length = branch.length / 3.0
	for p in 3:
		var reference = branch.start_point
		if branch_points.size() > 0:
			reference = branch_points[branch_points.size() - 1]
		var segment_percent = float(p + 1) / 3.0
		var influence = influence_curve.sample(segment_percent) \
		* branch.upward_influence
		direction = direction.slerp(branch.upward_direction, influence)
		branch_points.append(reference + (direction * segment_length))
	var sway_direction = \
		branch.start_point.direction_to(branch_points[2]).rotated(PI / 2)
	var flip_direction = 1
	for bp in branch_points:
		bp += (sway_direction * (branch.length / 6.0) * flip_direction) \
		* branch.jagginess
		if flip_direction > 0:
			flip_direction = -1
		else:
			flip_direction = 1
		branch.line.add_point(bp)
	set_branch_width_curve(branch)
	return branch


func set_branch_width_curve(branch : Branch):
	var line : Line2D = branch.line
	line.width = branch.start_width
	var lowest_percent : float = branch.end_width / branch.start_width
	var new_curve : Curve = default_curve.duplicate()
	new_curve.set_point_value(1, lowest_percent)
	new_curve.bake()
	line.set_curve(new_curve)


func _process(delta):
	pass
