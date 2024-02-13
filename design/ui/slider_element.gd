extends HBoxContainer

class_name SliderElement

signal slider_value_changed(varName : String, value : float, reconstructive : bool)

@export var label : String = "Label"
@export var var_name : String = "varName"
@export var default_value : float = 1.0
@export var min_value : float = 0.0
@export var max_value : float = 1.0
@export var step : float = 0.05
@export var reconstructive : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$label.text = label
	$value.text = str(default_value)
	$slider.min_value = min_value
	$slider.max_value = max_value
	$slider.value = default_value
	$slider.step = step


func _on_slider_value_changed(value):
	## if max_value == 1.0
	## convert string to percent
	$value.text = str(value)
	var s : String = var_name
	if s == "varName":
		s = label
	emit_signal("slider_value_changed", s, value)
