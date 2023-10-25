extends Node2D

@export var load_textures : bool = false
@export var texture_scene : PackedScene
@export var polygon_scene : PackedScene

var scenes : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	var load_target = polygon_scene
	if load_textures:
		load_target = texture_scene
	for x in range(1, 20):
		for y in range(1, 20):
			var pos = Vector2(
				lerp(0, get_window().size.x, float(x) / 20),
				lerp(0, get_window().size.y, float(y) / 20))
			var new_child = load_target.instantiate()
			new_child.position = pos
			add_child(new_child)
			scenes.append(new_child)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for s in scenes:
		s.rotate(randf_range(delta / 2, delta + delta))
