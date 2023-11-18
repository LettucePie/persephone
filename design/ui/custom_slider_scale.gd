extends Range

@export var min : int = 800
@export var max : int = 2800

@export var handle_textures : Array[Texture2D] = [
	preload("res://design/ui/brush_tip_small.png"),
	preload("res://design/ui/brush_tip_small.png"),
	preload("res://design/ui/brush_tip_small.png")
]
@export var slider_under_styles : Array[StyleBoxFlat] = [
	preload("res://design/theme/slider_scales/slider_under_x1.tres"),
	preload("res://design/theme/slider_scales/slider_under_x2.tres"),
	preload("res://design/theme/slider_scales/slider_under_x3.tres")
]
@export var slider_over_styles : Array[StyleBoxFlat] = [
	preload("res://design/theme/slider_scales/slider_over_x1.tres"),
	preload("res://design/theme/slider_scales/slider_over_x2.tres"),
	preload("res://design/theme/slider_scales/slider_over_x3.tres")
]


func _ready():
	connect("resized", rescale)
	rescale()


func rescale():
	var length = get_window().get_size().length()
	var index = int(lerp(
		0, handle_textures.size(), 
		inverse_lerp(min, max, length)))
	print("Rescale Length: ", length, " index: ", index)
#	self["theme_override_icons/grabber"] = handle_textures[index]
#	self["theme_override_icons/grabber_highlight"] = handle_textures[index]
	self["theme_override_styles/slider"] = slider_under_styles[index]
	self["theme_override_styles/grabber_area"] = slider_over_styles[index]
	self["theme_override_styles/grabber_area_highlight"] = slider_over_styles[index]
