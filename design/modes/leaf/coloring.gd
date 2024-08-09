extends Control

class_name ColorTool

signal display_brush_image(tex)
signal apply_brush_image()

@export var image_w : int = 1024
@export var image_h : int = 1024
@export var brush_tip_textures : Array[Texture2D]

class BrushTip:
	var tex : Texture
	var img : Image
	var pix : int


var canvas_img : Image
var canvas_min : Vector2 = Vector2.ZERO
var canvas_max : Vector2 = size
var brush_img : Image
var merge_img : Image
var brush_tips : Array[BrushTip]
@onready var brush_tip_buttons : Array = [
	$HBoxContainer/brush_size_12,
	$HBoxContainer/brush_size_24,
	$HBoxContainer/brush_size_48
]
var current_brush_tip : BrushTip
var current_color : Color = Color.WHITE
var current_opac : float = 1.0
var brush_scale : float = 1.0

var brush_pressed : bool = false
var prev_point : Vector2


func _ready():
	print(size)
	make_brush_tips()
	update_opac_display()


func load_texture(tex : Texture2D):
	canvas_img = tex.get_image()
	image_w = tex.get_width()
	image_h = tex.get_height()
	if canvas_img.get_format() != 5:
		canvas_img.convert(5)
	setup_brush_image()


func make_brush_tips():
	for btex in brush_tip_textures:
		var new_tip = BrushTip.new()
		new_tip.tex = btex
		new_tip.img = btex.get_image()
		new_tip.pix = new_tip.img.get_width()
		brush_tips.append(new_tip)
	current_brush_tip = brush_tips.front()
	stretch_invert_brush_tip(current_brush_tip)


func setup_brush_image():
	brush_img = Image.create(image_w, image_h, false, canvas_img.get_format())
	brush_img.fill(Color(0.0, 0.0, 0.0, 0.0))
	merge_img = Image.create(image_w, image_h, false, canvas_img.get_format())
	merge_img.copy_from(canvas_img)


func color_brush_tip(brush_tip : BrushTip, color : Color):
	print("Color Brush Tip")
	var dimension = brush_tip.img.get_size()
	## Refresh Image data by pulling from Tex again, then reapply stretch
	brush_tip.img = brush_tip.tex.get_image()
	brush_tip.img.resize(dimension.x, dimension.y)
	for x in dimension.x:
		for y in dimension.y:
			var pix_color = brush_tip.img.get_pixel(x, y)
			if pix_color != Color(0, 0, 0, 0):
				pix_color.r = color.r
				pix_color.g = color.g
				pix_color.b = color.b
				pix_color.a = lerp(0.0, color.a, (pix_color.a / 1.0))
				brush_tip.img.set_pixel(x, y, pix_color)


func stretch_invert_brush_tip(brush_tip : BrushTip):
	print("Invert Stretch Brush Tip")
	var ratio_x = (canvas_max.x - canvas_min.x) / (canvas_max.y - canvas_min.y)
	var ratio_y = (canvas_max.y - canvas_min.y) / (canvas_max.x - canvas_min.x)
	var stretch_x = int(brush_tip.pix * ratio_y)
	var stretch_y = int(brush_tip.pix * ratio_x)
	brush_tip.img.resize(stretch_x, stretch_y)


func display_image():
	merge_img.copy_from(canvas_img)
	## Apply Opac to entire brush_img
	var brush_stroke = Image.new()
	brush_stroke.copy_from(brush_img)
	if current_opac < 0.99:
		for x in image_w:
			for y in image_h:
				var pix_color = brush_img.get_pixel(x, y)
				pix_color.a = lerp(0.0, current_opac, pix_color.a)
				brush_stroke.set_pixel(x, y, pix_color)
	merge_img.blend_rect(
		brush_stroke, 
		Rect2i(
			Vector2i.ZERO,
			Vector2i(image_w, image_h)),
		Vector2i.ZERO)
	emit_signal("display_brush_image", ImageTexture.create_from_image(merge_img))


func color_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			brush_pressed = event.pressed
			if event.pressed:
				#setup_brush_image()
				prev_point = center_to_brush(
					convert_to_image_space(
						get_local_mouse_position()
					)
				)
			else:
				emit_signal("apply_brush_image")
	if event is InputEventMouseMotion and brush_pressed:
		color_at(convert_to_image_space(get_local_mouse_position()))


func update_opac_display():
	$ColorPickerButton/opac_display.modulate = Color(
		1.0, 1.0, 1.0, 
		1.0 - current_opac 
		)


func _on_canvas_mouse_exited():
	brush_pressed = false


func convert_to_image_space(canvas_point : Vector2):
	var x = inverse_lerp(canvas_min.x, canvas_max.x, canvas_point.x)
	var y = inverse_lerp(canvas_min.y, canvas_max.y, canvas_point.y)
	return Vector2(int(image_w * x), int(image_h * y))


func center_to_brush(point : Vector2):
	return point - (Vector2(
		current_brush_tip.img.get_width(), current_brush_tip.img.get_height()) \
	* 0.5)


func color_at(point : Vector2):
	var center_offset = center_to_brush(point)
	var dist = center_offset.distance_squared_to(prev_point)
	var gapcount = int(dist / current_brush_tip.pix)
	if gapcount > 0 and gapcount < 200:
		for gap_idx in gapcount:
			var percent = float(gap_idx + 1) / float(gapcount + 1)
			brush_img.blend_rect(
				current_brush_tip.img, 
				Rect2i(Vector2i.ZERO, Vector2i(
					current_brush_tip.img.get_width(), 
					current_brush_tip.img.get_height())), 
				prev_point.lerp(center_offset, percent)
			)
	if gapcount >= 200:
		brush_pressed = false
	else:
		prev_point = center_offset
		brush_img.blend_rect(
			current_brush_tip.img, 
			Rect2i(Vector2i.ZERO, Vector2i(
				current_brush_tip.img.get_width(), 
				current_brush_tip.img.get_height())), 
			center_offset)
	display_image()


func _on_brush_size_pressed(b_size : int):
	for b in brush_tips:
		if b.pix == b_size:
			current_brush_tip = b
			color_brush_tip(b, current_color)
			stretch_invert_brush_tip(b)
	for button in brush_tip_buttons:
		var name_id = button.name.trim_prefix("brush_size_").to_int()
		if name_id == b_size:
			button.button_pressed = true
		else:
			button.button_pressed = false
		button.update_state()


func _on_color_picker_button_color_changed(color):
	current_color = color


func _on_color_picker_button_popup_closed():
	color_brush_tip(current_brush_tip, current_color)
	stretch_invert_brush_tip(current_brush_tip)


func _on_canvas_color_bounds(min : Vector2, max : Vector2):
	canvas_min = min
	canvas_max = max
	if current_brush_tip != null:
		stretch_invert_brush_tip(current_brush_tip)


func _on_brush_opac_value_changed(value):
	current_opac = float(value) / float(100)
	update_opac_display()
