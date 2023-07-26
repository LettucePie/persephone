extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_SPACE:
				$Icon2.position = $Icon2.position.linear_interpolate($Icon3.position, 0.2)
			if event.scancode == KEY_N:
				$Icon2.position = $Icon2.position.linear_interpolate($Icon3.position, -0.2)
				print("YES! Negative Weight will effectively push away by linear percent.")
