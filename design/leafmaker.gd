extends Node2D

export(Texture) var square_node_tex
export(Texture) var circle_node_tex
export(Vector2) var node_scale = Vector2(0.1, 0.1)


var nodes = []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			print(event.position)
			print(event.button_index)
			if event.button_index == 1:
				print("Left Click")
				var new_node = Sprite.new()
				new_node.texture = square_node_tex
				new_node.position = event.position
				new_node.scale = node_scale
				nodes.append(new_node)
				self.add_child(new_node)
			if event.button_index == 2:
				print("Right Click")
			if event.button_index == 3:
				print("Middle Click")
