extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = Vector2.UP
	print(dir)
	dir = dir.rotated(PI / -2)
	print(dir)
#	print(rad_to_deg(PI / 2))
#	print(dir.from_angle(PI / 2))
#	print(rad_to_deg(PI / 4))
#	print(dir.from_angle(PI / 4))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
