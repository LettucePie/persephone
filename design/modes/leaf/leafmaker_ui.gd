extends Control

signal symmetry(mode)
signal update_table_constraints(rect)
signal mode_changed(mode)

@onready var coloring : ColorTool = $coloring
var symmetry_mode : bool = false
enum EditorMode {MAIN_MODE, COLOR_MODE}
var control_mode : EditorMode = EditorMode.MAIN_MODE
@onready var point_edit_buttons : Array = [
	$main_controls/Add_Mode,
	$main_controls/Move_Mode,
	$main_controls/Remove_Mode
]

# Called when the node enters the scene tree for the first time.
func _ready():
	$SymmetryLine.visible = symmetry_mode
	$main_controls.show()
	$coloring.hide()
	adjust_table()


func _input(event):
	if control_mode == EditorMode.COLOR_MODE:
		coloring.color_input(event)


func adjust_table():
	print("adjust_table")
	var table : Control = $table
	var table_rect : Rect2i = Rect2i(table.get_rect())
	var safe_area : Rect2i = DisplayServer.get_display_safe_area()
	var difference = abs(table_rect.position.y - safe_area.position.y)
	table_rect.position.y = safe_area.position.y
	table_rect.size.y -= difference
	table.position = table_rect.position
	table.size.y = table_rect.size.y
	emit_signal("update_table_constraints", table_rect)


func _on_mode_item_selected(index):
	if index > 0:
		$table.mouse_filter = 2
	else:
		$table.mouse_filter = 0
	for i in point_edit_buttons.size():
		point_edit_buttons[i].button_pressed = (i == index)
		point_edit_buttons[i].update_state()


func _on_symmetry_toggled(button_pressed):
	symmetry_mode = button_pressed
	emit_signal("symmetry", symmetry_mode)
	$SymmetryLine.visible = symmetry_mode


func _on_color_pressed():
	control_mode = EditorMode.COLOR_MODE
	$main_controls.hide()
	$table.hide()
	$coloring.show()
	emit_signal("mode_changed", control_mode)


func _on_done_color_pressed():
	control_mode = EditorMode.MAIN_MODE
	$main_controls.show()
	$table.show()
	$coloring.hide()
	emit_signal("mode_changed", control_mode)


func _on_resized():
	emit_signal("update_table_constraints", $table.get_rect())
