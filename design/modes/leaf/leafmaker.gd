extends Node

@export var leaf_texture_default: Texture2D

func _ready():
	$canvas.load_data(leaf_texture_default)
	$ui/coloring.load_texture(leaf_texture_default)


func load_leaf(data):
	pass


func _on_canvas_ready():
	pass # Replace with function body.


func _on_ui_ready():
	$canvas.ui_control = $ui


func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_R and event.pressed:
			print("Testing leafpoint.position scaling")
			var leafpoints = $canvas.leaf_points
			var table = $ui/table
			var index = 0
			for lp in leafpoints:
				var pos = lp.get_position()
				var pos_flattened = pos - table.position
				var percent_position = Vector2(
					float(pos_flattened.x) / float(table.size.x),
					float(pos_flattened.y) / float(table.size.y)
				)
				print(
					"\nLeafPoint: ", index, 
					"\nPosition: ", pos, 
					"\nTable_Scaled_Position: ", percent_position)
				index += 1
