extends Node2D

@export var default_curve : Curve
@export var influence_curve : Curve

class BranchLayer:
	var layer : int = 0
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
#	var target_points : PackedVector2Array = [Vector2.UP]
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
	var population : float = 0.0
	var growth_coverage : float = 0.0
	var growth_coverage_end_to_base : bool = true
	var force_symmetry : bool = false
	var leaf_size : float = 0.0
	var leaf_size_random : float = 0.0


class GrowthPoint:
	var point_position : Vector2 = Vector2.ZERO
	var point_width : float = 0.0


var branch_layers : Array
#var branches : Array


func _ready():
#	branches.clear()
	branch_layers.clear()
	make_trunk()
	draw_all_branches()
	var center = Vector2(get_window().get_size() / 2)
	print(center)
	var new_line : Line2D = Line2D.new()
	new_line.add_point(center)
	new_line.add_point(center + (Vector2.UP * 200))
	add_child(new_line)
	var new_branch : Branch = Branch.new()
	new_branch.line = new_line
#	branches.append(new_branch)
	set_branch_width_curve(new_branch, 20, 10)
	print(new_line.points)


func make_trunk():
	var trunk : Branch = Branch.new()
	var screen_size = Vector2(get_window().get_size())
	trunk.start_point = screen_size
	trunk.start_point.x *= 0.5
	trunk.start_point.y *= 0.7
	trunk.start_normal = Vector2.UP
	trunk.length = trunk.start_point.y - (screen_size.y * 0.2)
	make_layer(0, setup_branch_line(trunk))


func make_layer(layer_num : int, master_branch : Branch):
	if layer_num < branch_layers.size():
		print("ERROR** Layer Number: ", layer_num, " already occupied.")
		## Replace branch?
	else:
		var new_layer : BranchLayer = BranchLayer.new()
		new_layer.layer = layer_num
		new_layer.master_branch_copy = master_branch
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
		draw_all_branches()


func populate_layer(layer : BranchLayer, start_points : Array):
	print("Iterate over Start Points, making a new branch at each")


func map_out_growth_points(layer : BranchLayer):
	print("Iterate over fresh branches, gathering all viable growth points")


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
	for p in 2:
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
		bp += (sway_direction * flip_direction) * branch.jagginess
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
