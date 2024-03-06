extends Node

var length_max : float = 1000
var trunk_start : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	var screen_size = Vector2(get_window().get_size())
	trunk_start = screen_size
	trunk_start.x *= 0.5
	trunk_start.y *= 0.7
	length_max = screen_size.length()
	create_branch(trunk_start, 0.2, 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func create_branch(start_point : Vector2, length : float, angle : float):
	var new_branch = Line2D.new()
	new_branch.add_point(start_point)
	var next_point = start_point
	var direction = Vector2.UP.rotated(angle)
	next_point += direction * (length * length_max)
	new_branch.add_point(next_point)
	$Node2D.add_child(new_branch)
