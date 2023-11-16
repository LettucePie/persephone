extends Area2D

signal clicked(n)
signal tapped(n)

@export var square_node_tex : Texture2D
@export var circle_node_tex : Texture2D

var curve_index : int = 0
var mouse_time = 0


func spawn_node(visual_scale : Vector2):
	$Sprite2D.texture = square_node_tex
	$Sprite2D.scale = visual_scale


func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed:
			mouse_time = Time.get_ticks_msec()
			emit_signal("clicked", self)
			print("Mouse Pressed: ", mouse_time)
		else:
			print("Mouse Released: ", Time.get_ticks_msec(), " " , mouse_time)
			if Time.get_ticks_msec() - mouse_time < 500:
				print("Emitting Tapped Status")
				emit_signal("tapped", self)


func set_origin_visual():
	$Sprite2D.modulate = Color.RED
	$Sprite2D.scale *= 0.5


func clamped_translate(relative : Vector2, clamp_rect : Rect2i):
	translate(relative)
	position = position.clamp(clamp_rect.position, clamp_rect.size)


func set_curve_index(i):
	curve_index = i


func set_node_type(_round):
	if _round:
		$Sprite2D.texture = circle_node_tex
	else:
		$Sprite2D.texture = square_node_tex
	$in.visible = _round
	$out.visible = _round


func set_in_out_points(in_pos : Vector2, out_pos : Vector2):
	$in.position = in_pos
	$out.position = out_pos


func set_color(c):
	modulate = c


func set_point_scale(s):
	$Sprite2D.scale = s
