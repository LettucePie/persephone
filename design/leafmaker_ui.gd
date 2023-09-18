extends Control

signal symmetry(mode)

var symmetry_mode : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_mode_item_selected(index):
	if index > 0:
		$table.mouse_filter = 2
	else:
		$table.mouse_filter = 0


func _on_symmetry_toggled(button_pressed):
	symmetry_mode = button_pressed
	emit_signal("symmetry", symmetry_mode)
