extends Control

signal symmetry(mode)

var symmetry_mode : bool = false
enum EditorMode {MAIN_MODE, VEIN_MODE}
var control_mode : EditorMode = EditorMode.MAIN_MODE

# Called when the node enters the scene tree for the first time.
func _ready():
	$SymmetryLine.visible = symmetry_mode
	$main_controls.show()
	$vein_controls.hide()


func _on_mode_item_selected(index):
	if index > 0:
		$table.mouse_filter = 2
	else:
		$table.mouse_filter = 0


func _on_symmetry_toggled(button_pressed):
	symmetry_mode = button_pressed
	emit_signal("symmetry", symmetry_mode)
	$SymmetryLine.visible = symmetry_mode


func _on_vein_pressed():
	control_mode = EditorMode.VEIN_MODE
	$main_controls.hide()
	$vein_controls.show()


func _on_close_vein_pressed():
	control_mode = EditorMode.MAIN_MODE
	$main_controls.show()
	$vein_controls.hide()
