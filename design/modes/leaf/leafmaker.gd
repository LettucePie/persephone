extends Node

signal update_points_on_resize(positions)

@export var leaf_texture_default: Texture2D
@onready var table : Control = $ui/table

## Sharable Data
## Append this all to a future data type class JSON THING
var leafpoint_position_percents : PackedVector2Array = []
var leaf_texture : Texture2D = null
var leaf_image : Image

func _ready():
	var target_positions = leafpoint_position_percents
	var target_texture = leaf_texture
	if target_positions.size() > 0:
		print("Load leafpoint position data")
		$canvas.load_data(target_positions, target_texture)
	else:
		print("Build Starter Leaf")
		$canvas.leaf_texture = leaf_texture_default
		$canvas.build_default()
	if target_texture != null:
		print("Load leaf_texture")
		$ui/coloring.load_texture(target_texture)
	else:
		print("Load default leaf texture")
		$ui/coloring.load_texture(leaf_texture_default)


func load_leaf(data):
	pass


func _on_canvas_ready():
	pass # Replace with function body.


func _on_ui_ready():
	$canvas.ui_control = $ui


func _on_canvas_update_point_percents(simple_positions):
	print("Updating leaf Percent Position data")
	leafpoint_position_percents.clear()
	for pos in simple_positions:
		var pos_flattened = pos - table.position
		var percent_position = Vector2(
			float(pos_flattened.x) / float(table.size.x),
			float(pos_flattened.y) / float(table.size.y)
		)
		leafpoint_position_percents.append(percent_position)


func apply_position_percents():
	print("Applying percent positions back onto canvas.leaf_points")
	var new_positions : PackedVector2Array = []
	for point in leafpoint_position_percents:
		var pos = Vector2(
			table.size.x * point.x,
			table.size.y * point.y
		)
		new_positions.append(pos + table.position)
	emit_signal("update_points_on_resize", new_positions)


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


func _on_ui_resized():
	if leafpoint_position_percents.size() > 0:
		apply_position_percents()

