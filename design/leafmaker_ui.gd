extends Control

signal symmetry(mode)

var symmetry_mode : bool = false
enum EditorMode {MAIN_MODE, COLOR_MODE}
var control_mode : EditorMode = EditorMode.MAIN_MODE

# Called when the node enters the scene tree for the first time.
func _ready():
	$SymmetryLine.visible = symmetry_mode
	$main_controls.show()
	$coloring.hide()


func _on_mode_item_selected(index):
	if index > 0:
		$table.mouse_filter = 2
	else:
		$table.mouse_filter = 0


func _on_symmetry_toggled(button_pressed):
	symmetry_mode = button_pressed
	emit_signal("symmetry", symmetry_mode)
	$SymmetryLine.visible = symmetry_mode


func _on_color_pressed():
	control_mode = EditorMode.COLOR_MODE
	$main_controls.hide()
	$table.hide()
	$coloring.show()


func _on_done_color_pressed():
	control_mode = EditorMode.MAIN_MODE
	$main_controls.show()
	$table.show()
	$coloring.hide()
