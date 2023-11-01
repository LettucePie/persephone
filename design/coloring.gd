extends Control

@export var image_w : int = 1024
@export var image_h : int = 1024
@export var brush_tip_textures : Array[Texture2D]
#@export var brush_12 : Texture2D
#@export var brush_24 : Texture2D
#@export var brush_48 : Texture2D

class BrushTip:
	var tex : Texture
	var img : Image
	var pix : int


var canvas_img : Image
var brush_tips : Array[BrushTip]
var current_brush_tip : BrushTip
var current_color : Color = Color.WHITE
var brush_scale : float = 1.0

var brush_pressed : bool = false
var prev_point : Vector2


func _ready():
	print(size)
	make_brush_tips()
	canvas_img = Image.create(image_w, image_h, false, 5)
	display_image()
#	print(brush_size, " ", brush_size * brush_size)


func make_brush_tips():
	for btex in brush_tip_textures:
		var new_tip = BrushTip.new()
		new_tip.tex = btex
		new_tip.img = btex.get_image()
		new_tip.pix = new_tip.img.get_width()
		brush_tips.append(new_tip)
	current_brush_tip = brush_tips[0]


func color_brush_tip(brush_tip : BrushTip, color : Color):
	var dimension = brush_tip.img.get_size()
	## Refresh Image data by pulling from Tex again
	brush_tip.img = brush_tip.tex.get_image()
	for x in dimension.x:
		for y in dimension.y:
			var pix_color = brush_tip.img.get_pixel(x, y)
			if pix_color != Color(0, 0, 0, 0):
				pix_color.r = color.r
				pix_color.g = color.g
				pix_color.b = color.b
				pix_color.a = lerp(0.0, color.a, (pix_color.a / 1.0))
				brush_tip.img.set_pixel(x, y, pix_color)


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
	var center_offset = point - (Vector2(current_brush_tip.pix, current_brush_tip.pix) * 0.5)
	var dist = center_offset.distance_squared_to(prev_point)
	var gapcount = int(dist / current_brush_tip.pix)
	if gapcount > 0 and gapcount < 200:
		for gap_idx in gapcount:
			var percent = float(gap_idx + 1) / float(gapcount + 1)
			canvas_img.blend_rect(
				current_brush_tip.img, 
				Rect2i(Vector2i.ZERO, Vector2i(current_brush_tip.pix, current_brush_tip.pix)), 
				prev_point.lerp(center_offset, percent)
			)
	if gapcount >= 200:
		print("Draw Request too large")
		brush_pressed = false
	else:
		prev_point = center_offset
		canvas_img.blend_rect(
			current_brush_tip.img, 
			Rect2i(Vector2i.ZERO, Vector2i(current_brush_tip.pix, current_brush_tip.pix)), 
			center_offset)
	display_image()


func _on_brush_size_pressed(b_size : int):
	print("Changing BrushTip to Size: ", b_size)
	for b in brush_tips:
		if b.pix == b_size:
			current_brush_tip = b
			color_brush_tip(b, current_color)


func _on_color_picker_button_color_changed(color):
	print("Changing to Color: ", color)
	current_color = color


func _on_color_picker_button_popup_closed():
	print("Assigning Current Color: ", current_color, " to Current BrushTip.")
	color_brush_tip(current_brush_tip, current_color)
