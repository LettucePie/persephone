extends ColorPickerButton

@export var stylebox : StyleBox

func _ready():
	connect("picker_created", simplify_colorpicker)
#	connect("resized", picker_window_scale)
	get_picker().get_parent().connect("visibility_changed", picker_window_scale)
	simplify_colorpicker()
#	manipulate_color_picker_internals(get_picker())
#	picker_window_scale()


func simplify_colorpicker():
#	if OS.has_feature("mobile"):
	var color_picker : ColorPicker = get_picker()
	color_picker.set_picker_shape(2)
	color_picker.set_can_add_swatches(false)
	color_picker.set_modes_visible(false)
	color_picker.set_hex_visible(false)
	color_picker.set_presets_visible(false)
	color_picker.set_sampler_visible(false)
	color_picker.set_sliders_visible(false)
#	picker_window_scale()


func update_children_size_flags(children : Array):
	print("Manipulating ", children.size(), " children")
	var populated_children : Array = []
	for child in children:
		if child is Control:
			print(child)
			child.size_flags_horizontal = 3
			child.size_flags_vertical = 3
			if child.get_child_count(true) > 0:
				populated_children += child.get_children(true)
	print("Returning ", populated_children.size(), " populated children")
	return populated_children


func manipulate_color_picker_internals(picker : ColorPicker):
	print("Starting Manipulations of ColorPicker: ", picker)
	get_picker().size_flags_horizontal = 3
	get_picker().size_flags_vertical = 3
#	var scope_goal = picker.get_child_count(true)
#	var current_scope = 0
	var backup_breaker = 10
	var layer = picker.get_children(true)
	while(layer.size() > 0 or backup_breaker > 0):
		backup_breaker -= 1
		layer = update_children_size_flags(layer)
		if backup_breaker == 0:
			print("Backup Breaking")


func picker_window_scale():
	var screen_size : Vector2i = get_window().get_size()
	var new_scale = Vector2i(screen_size.x - 10, screen_size.x - 10)
	if screen_size.x > screen_size.y:
		## scale by height
		new_scale = Vector2i(screen_size.y - 10, screen_size.y - 10)
	var new_pos = Vector2i(5, new_scale.y / 3)
	var win : Window = get_picker().get_parent()
	win.wrap_controls = false
#	win.content_scale_mode = 1
#	win.mode = 3
#	win.set_content_scale_factor(1.2)
	win.position = new_pos
#	win.size = new_scale
	win.min_size = new_scale
#	print("H_Flags : ", get_picker().size_flags_horizontal)
#	print("V_Flags : ", get_picker().size_flags_vertical)
#	panel["theme_override_styles/panel"] = stylebox
	var deep_children : Array = get_picker().get_children(true)
	for deep_child in deep_children:
		deep_child.size_flags_horizontal = 3
		deep_child.size_flags_vertical = 3
#	get_picker().pivot_offset = get_picker().size
#	var old_size = get_picker().size
#	var new_scale = Vector2(0.8, 0.8).lerp(
#	Vector2(2.0, 2.0), 
#	inverse_lerp(1000, 4500, get_window().get_size().length())
#	)
#	print("Color Picker Rect Before: ", get_picker().get_rect())
#	get_picker().scale = new_scale
#	get_picker().position += old_size - get_picker().size
#	get_picker().size = Vector2(1100, 1000)
#	get_picker().position = Vector2(-1000, -1000)
#	get_picker().custom_minimum_size = Vector2(800, 600)
#	print("Color Picker Scale : ", new_scale)
#	print("Color Picker Rect After: ", get_picker().get_rect())

