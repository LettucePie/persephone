extends Control

var symmetry_mode : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Symmetry_pressed():
	pass


func _on_mode_item_selected(index):
	if index > 0:
		$table.mouse_filter = 2
	else:
		$table.mouse_filter = 0
