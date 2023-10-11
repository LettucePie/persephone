extends Node2D

@export var icon : Texture2D
@export var point_a : Vector2 = Vector2(100, 100)
@export var point_b : Vector2 = Vector2(800, 200)


# Called when the node enters the scene tree for the first time.
func _ready():
	var pos_1 = $control_1.get_position()
	var pos_2 = $control_2.get_position()
#	pos_1 = pos_2
	for i in 10:
		var new_sprite = Sprite2D.new()
		new_sprite.texture = icon
		var percent = float(i + 1.0) / 10.0
		var pos = point_a.bezier_interpolate(pos_1, pos_2, point_b, percent)
		new_sprite.position = pos
		add_child(new_sprite)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
