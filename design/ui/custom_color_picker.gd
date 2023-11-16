extends ColorPickerButton

func _ready():
	connect("picker_created", simplify_colorpicker)

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
