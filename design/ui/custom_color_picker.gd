extends ColorPickerButton

@export var stylebox : StyleBox

func _ready():
	connect("picker_created", simplify_colorpicker)
	get_picker().get_parent().connect("visibility_changed", picker_window_scale)
	simplify_colorpicker()
	manipulate_color_picker_internals(get_picker())


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


func update_children_size_flags(children : Array):
	print("Manipulating ", children.size(), " children")
	var populated_children : Array = []
	for child in children:
		if child is Control:
			print(child)
			child.size_flags_horizontal = 3
			child.size_flags_vertical = 3
			if child.custom_minimum_size != Vector2.ZERO:
				child.custom_minimum_size = Vector2(400, 400)
			if child.get_child_count(true) > 0:
				populated_children += child.get_children(true)
	print("Returning ", populated_children.size(), " populated children")
	return populated_children


func manipulate_color_picker_internals(picker : ColorPicker):
	print("Starting Manipulations of ColorPicker: ", picker)
	get_picker().size_flags_horizontal = 3
	get_picker().size_flags_vertical = 3
	var backup_breaker = 10
	var layer = picker.get_children(true)
	while(layer.size() > 0 or backup_breaker > 0):
		backup_breaker -= 1
		layer = update_children_size_flags(layer)
		if backup_breaker == 0:
			print("Backup Breaking")


func picker_window_scale():
	var screen_size : Vector2i = get_window().get_size()
	var screen_center = screen_size / 2
	var new_scale = Vector2i(
		screen_size.x - 10, 
		clamp(screen_size.x - 10, 256, 424))
	var new_pos = Vector2i(5, screen_center.y - (new_scale.y / 2))
	if screen_size.x > screen_size.y:
		## scale by height
		new_scale = Vector2i(
			clamp(screen_size.y - 10, 256, 424), 
			clamp(screen_size.y - 10, 256, 424))
		new_pos.x = screen_center.x - (new_scale.x / 2)
	var win : Window = get_picker().get_parent()
	win.wrap_controls = false
	win.position = new_pos
	win.min_size = new_scale
