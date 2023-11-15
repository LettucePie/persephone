extends CheckButton

@export var unchecked : Texture2D
@export var checked : Texture2D

func _ready():
	connect("pressed", update_state)
	update_state()

func update_state():
	if button_pressed:
		icon = checked
	else:
		icon = unchecked
