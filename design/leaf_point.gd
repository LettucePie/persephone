extends Area2D

signal clicked(n)

@export var square_node_tex : Texture2D
@export var circle_node_tex : Texture2D

var curve_index : int = 0

func spawn_node(visual_scale : Vector2):
	$Sprite2D.texture = square_node_tex
	$Sprite2D.scale = visual_scale


func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed:
			emit_signal("clicked", self)


func set_origin_visual():
	$Sprite2D.modulate = Color.RED
	$Sprite2D.scale *= 0.5


func set_curve_index(i):
	curve_index = i
