extends Control

signal modification_request(var_name, value)

# Called when the node enters the scene tree for the first time.
func _ready():
	var elements : Array = $scroller/list.get_children()
	if elements.size() > 0:
		for e in elements:
			e.connect("slider_value_changed", forward_request)


func forward_request(var_name : String, value : float):
	print("Received value change for var: ", var_name)
	emit_signal("modification_request", var_name, value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
