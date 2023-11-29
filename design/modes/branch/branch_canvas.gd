extends Node2D

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


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
