extends Control

@export var image_w : int = 1024
@export var image_h : int = 1024

var canvas_img : Image
var brush_tip : Image

var brush_pressed : bool = false
var brush_stroke : Array
var stroke_progress : int


func _ready():
	print(size)
	make_brush_tips()
	canvas_img = Image.create(image_w, image_h, false, 5)
	display_image()


func make_brush_tips():
	var new_tip = Image.create(24, 24, false, 5)
	new_tip.fill(Color.WHITE)
	brush_tip = new_tip


func display_image():
	$canvas.texture = ImageTexture.create_from_image(canvas_img)


func _process(delta):
	if stroke_progress < brush_stroke.size() - 2:
		var current = brush_stroke[stroke_progress]
		var next = brush_stroke[stroke_progress + 1]
		var dist = current.distance_squared_to(next)
		var scry = dist > 10
		var steps = int(dist / 2)
		if stroke_progress + 2 < brush_stroke.size() and scry:
			## Scry forward for curve
			var ahead = brush_stroke[stroke_progress + 2]
			var angle = current.direction_to(ahead).angle_to(current.direction_to(next))
			var anchor = current + (current.direction_to(ahead).rotated(angle) * ((ahead - current).length() * 0.5))
			for i in range(1, dist):
				color_at(current.bezier_interpolate(anchor, anchor, next, float(i) / float(steps)))
			stroke_progress += 1
		elif !scry:
			color_at(current)
			stroke_progress += 1


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			brush_pressed = event.pressed
			if event.pressed:
				brush_stroke.clear()
				stroke_progress = 0
	if event is InputEventMouseMotion and brush_pressed:
		brush_stroke.append(convert_to_image_space($canvas.get_local_mouse_position(), $canvas.size))
#		color_at(convert_to_image_space($canvas.get_local_mouse_position(), $canvas.size))


func _on_canvas_mouse_exited():
	brush_pressed = false


func convert_to_image_space(canvas_point : Vector2, dimension : Vector2):
	print("Canvas Point: ", canvas_point, " Dimension: ", dimension)
	var x = canvas_point.x / dimension.x
	var y = canvas_point.y / dimension.y
	return Vector2(int(image_w * x), int(image_h * y))


func color_at(point : Vector2):
	canvas_img.blend_rect(brush_tip, Rect2i(Vector2i.ZERO, Vector2i(24, 24)), point)
	display_image()




