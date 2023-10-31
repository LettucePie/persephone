extends Control

@export var image_w : int = 1024
@export var image_h : int = 1024

var canvas_img : Image
var brush_tip : Image
var brush_size : int = 24
var brush_scale : float = 1.0

var brush_pressed : bool = false
var prev_point : Vector2


func _ready():
	print(size)
	make_brush_tips()
	canvas_img = Image.create(image_w, image_h, false, 5)
	display_image()
	print(brush_size, " ", brush_size * brush_size)


func make_brush_tips():
	var new_tip = Image.create(brush_size, brush_size, false, 5)
	new_tip.fill(Color.WHITE)
	brush_tip = new_tip


func display_image():
	$canvas.texture = ImageTexture.create_from_image(canvas_img)


func _process(delta):
	pass


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			brush_pressed = event.pressed
			if event.pressed:
				prev_point = convert_to_image_space($canvas.get_local_mouse_position(), $canvas.size)
	if event is InputEventMouseMotion and brush_pressed:
		color_at(convert_to_image_space($canvas.get_local_mouse_position(), $canvas.size))


func _on_canvas_mouse_exited():
	brush_pressed = false


func convert_to_image_space(canvas_point : Vector2, dimension : Vector2):
#	print("Canvas Point: ", canvas_point, " Dimension: ", dimension)
	var x = canvas_point.x / dimension.x
	var y = canvas_point.y / dimension.y
	return Vector2(int(image_w * x), int(image_h * y))


func color_at(point : Vector2):
	var center_offset = point - (Vector2(brush_size, brush_size) * 0.5)
	var dist = center_offset.distance_squared_to(prev_point)
	var gapcount = int(dist / brush_size)
	if gapcount > 0 and gapcount < 200:
		for gap_idx in gapcount:
			var percent = float(gap_idx + 1) / float(gapcount + 1)
			canvas_img.blend_rect(
				brush_tip, 
				Rect2i(Vector2i.ZERO, Vector2i(brush_size, brush_size)), 
				prev_point.lerp(center_offset, percent)
			)
	if gapcount >= 200:
		print("Draw Request too large")
		brush_pressed = false
	else:
		prev_point = center_offset
		canvas_img.blend_rect(
			brush_tip, 
			Rect2i(Vector2i.ZERO, Vector2i(brush_size, brush_size)), 
			center_offset)
	display_image()




