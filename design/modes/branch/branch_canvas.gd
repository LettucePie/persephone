extends Node2D

@export var default_curve : Curve
@export var influence_curve : Curve

class BranchLayer:
	var layer : int = 0
	var master_branch_copy : Branch
	var population : float = 0.0
	var length_random : float = 0.0
	var branches : Array = []


class Branch:
	## Branch Type Properties
	var layer : int = 0
	## Branch Shape Properties
	var line : Line2D = null
	var start_point : Vector2 = Vector2.ZERO
	var start_normal : Vector2 = Vector2.RIGHT
#	var target_points : PackedVector2Array = [Vector2.UP]
	var length : float = 1.0
	var jagginess : float = 0.0
	var upward_angle : float = 0.0
	var upward_influence : float = 0.0
	## Growth Point Properties
	var carries_leaves : bool = false
	var population : float = 0.0
	var growth_coverage : float = 0.0
	var force_symmetry : bool = false
	var leaf_size : float = 0.0

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
#	trunk.target_points.append(Vector2(screen_size.x / 2, screen_size.y * 0.3))
	make_layer(0, trunk)


func make_layer(layer_num : int, master_branch : Branch):
	if layer_num < branch_layers.size():
		print("ERROR** Layer Number: ", layer_num, " already occupied.")
		## Replace branch?
	else:
		var new_layer : BranchLayer = BranchLayer.new()
		new_layer.layer = layer_num
		new_layer.master_branch_copy = master_branch
		branch_layers.append(new_layer)


func set_branch_width_curve(branch : Branch, start_w : float, end_w : float):
	var line : Line2D = branch.line
	line.width = start_w
	var lowest_percent : float = end_w / start_w
	var new_curve : Curve = default_curve.duplicate()
	new_curve.set_point_value(1, lowest_percent)
#	new_curve.min_value = end_w / start_w
	new_curve.bake()
	line.set_curve(new_curve)


func create_branch_line(branch : Branch):
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
		direction = direction.slerp(Vector2.UP, influence)
		branch_points.append(reference + (direction * segment_length))
	## For Jagginess:
	## Find direction from Start to last branch_points[]
	## Calc the 90 degree positive and negative of that angle, called up and down
	## re-iterate over the branch_points[] and add up and down direction, 
	## multiplied by jagginess value.


func draw_all_branches():
	for b_l in branch_layers:
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
			


func _process(delta):
	pass
