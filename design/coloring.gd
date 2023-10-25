extends Control

@export var image_w : int = 1024
@export var image_h : int = 1024

var canvas_img : Image
var brush_tip : Image

var brush_pressed : bool = false

# Called when the node enters the scene tree for the first time.
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_canvas_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			brush_pressed = event.pressed
	if event is InputEventMouseMotion and brush_pressed:
		color_at(convert_to_image_space($canvas.get_local_mouse_position(), $canvas.size))


func _on_canvas_mouse_exited():
	brush_pressed = false


func convert_to_image_space(canvas_point : Vector2, dimension : Vector2):
	print("Canvas Point: ", canvas_point, " Dimension: ", dimension)
	var x = canvas_point.x / dimension.x
	var y = canvas_point.y / dimension.y
	return Vector2(int(image_w * x), int(image_h * y))


func color_at(point : Vector2):
#	canvas_img.set_pixel(point.x, point.y, Color.WHITE)
	canvas_img.blend_rect(brush_tip, Rect2i(Vector2i.ZERO, Vector2i(24, 24)), point)
	display_image()




