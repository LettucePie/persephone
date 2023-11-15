extends Node

@export var leaf_texture_default: Texture2D

func _ready():
	$canvas.load_data(leaf_texture_default)
	$ui/coloring.load_texture(leaf_texture_default)


func load_leaf(data):
	pass


func _on_canvas_ready():
	pass # Replace with function body.


func _on_ui_ready():
	$canvas.ui_control = $ui

