extends HBoxContainer

class_name SliderElement

signal slider_value_changed(varName : String, value : float)

@export var label : String = "Label"
@export var var_name : String = "varName"
@export var default_value : float = 1.0
@export var min_value : float = 0.0
@export var max_value : float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	$label.text = label
	$value.text = str(default_value)
	$slider.min_value = min_value
	$slider.max_value = max_value
	$slider.value = default_value


func _on_slider_value_changed(value):
	$value.text = str(value)
	var s : String = var_name
	if s == "varName":
		s = label
	emit_signal("slider_value_changed", s, value)
