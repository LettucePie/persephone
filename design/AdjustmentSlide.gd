extends HBoxContainer

@export_enum("In_Height", "Out_Height", "In_Force", "Out_Force") var adjustment : int
@export var round : bool = false
signal changed_value(target, value)
signal changed_round_value(target, value)

func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_h_slider_value_changed(value):
	$value.text = str(value)
	if round:
		emit_signal("changed_round_value", adjustment, value)
	else:
		emit_signal("changed_value", adjustment, value)
