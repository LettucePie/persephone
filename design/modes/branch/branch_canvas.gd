extends Node2D

@export var default_curve : Curve

class Branch:
	## Branch Shape Properties
	var line : Line2D = null
	var start_point : Vector2 = Vector2.ZERO
	var target_points : PackedVector2Array = [Vector2.UP]
	var jagginess : float = 0.0
	var upward_influence : float = 0.0
	## Growth Point Properties
	var carries_leaves : bool = false
	var population : float = 0.0
	var growth_coverage : float = 0.0
	var force_symmetry : bool = false
	var leaf_size : float = 0.0

var branches : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	branches.clear()
	var center = Vector2(get_window().get_size() / 2)
	print(center)
	var new_line : Line2D = Line2D.new()
	new_line.add_point(center)
	new_line.add_point(center + (Vector2.UP * 200))
	add_child(new_line)
	var new_branch : Branch = Branch.new()
	new_branch.line = new_line
	branches.append(new_branch)
	set_branch_width_curve(new_branch, 20, 10)


func set_branch_width_curve(branch : Branch, start_w : float, end_w : float):
	var line : Line2D = branch.line
	line.width = start_w
	var lowest_percent : float = end_w / start_w
	var new_curve : Curve = default_curve.duplicate()
	new_curve.set_point_value(1, lowest_percent)
#	new_curve.min_value = end_w / start_w
	new_curve.bake()
	line.set_curve(new_curve)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
