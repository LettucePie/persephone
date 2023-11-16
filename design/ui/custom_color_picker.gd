extends ColorPickerButton

func _ready():
	connect("picker_created", simplify_colorpicker)
	connect("resized", color_picker_scale)
	simplify_colorpicker()
	color_picker_scale()

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


func color_picker_scale():
	print("Color Picker Scale")
	var new_scale = Vector2(0.8, 0.8).lerp(
	Vector2(1.8, 1.8), 
	inverse_lerp(1000, 4500, get_window().get_size().length())
	)
	get_picker().scale = new_scale
