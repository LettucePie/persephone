extends Node

var length_max : float = 1000
var trunk_start : Vector2
var branch_layers : Array = []
var branch_layer_settings : Array = []
var branch_setting_dict : Dictionary = {
	"population" = 0,
	"length" = 0.0,
	"angle" = 0.0,
	"growth" = 0.0
}
var current_layer : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	var screen_size = Vector2(get_window().get_size())
	trunk_start = screen_size
	trunk_start.x *= 0.5
	trunk_start.y *= 0.7
	length_max = screen_size.length()
	create_default_layer()
	create_branch(trunk_start, 0.2, 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func create_branch(start_point : Vector2, length : float, angle : float):
	var new_branch = Line2D.new()
	new_branch.add_point(start_point)
	var next_point = start_point
	var direction = Vector2.UP.rotated(angle)
	next_point += direction * (length * length_max)
	new_branch.add_point(next_point)
	$Node2D.add_child(new_branch)


func _on_layer_switch_pressed(next : bool):
	print("Advance to NEXT layer? : ", next)
	if next:
		current_layer += 1
	else:
		current_layer -= 1
	if current_layer < 0:
		current_layer = 0
	var last_index = branch_layer_settings.size() - 1
	if current_layer > last_index:
		create_default_layer()
	print("update settings display")
	update_settings_display()


func create_default_layer():
	print("Create default layer")
	print(current_layer)
	var settings : Dictionary = branch_setting_dict.duplicate(true)
	branch_layer_settings.insert(current_layer, settings)
	branch_layers.insert(current_layer, [])


func update_settings_display():
	print("branch_layer_settings.size(): ", branch_layer_settings.size())
	var settings : Dictionary = branch_layer_settings[current_layer]
	$Control/VBoxContainer/layer/value.text = str(current_layer)
	$Control/VBoxContainer/population/value.text = str(settings["population"])
	$Control/VBoxContainer/population/population_slider.value = settings["population"]
	$Control/VBoxContainer/length/value.text = str(settings["length"])
	$Control/VBoxContainer/length/length_slider.value = settings["length"]
	$Control/VBoxContainer/angle/value.text = str(settings["angle"])
	$Control/VBoxContainer/angle/angle_slider.value = settings["angle"]
	$Control/VBoxContainer/growth/value.text = str(settings["growth"])
	$Control/VBoxContainer/growth/growth_slider.value = settings["growth"]


func update_setting(value : float, label : String):
	print("Update: ", label, " to ", value)
	branch_layer_settings[current_layer][label] = value
	update_settings_display()
	update_layer()


func update_layer():
	print("TODO")
	## TODO
	## Okay so, i need to get the growth points from the previous layer.
	## I also need to work off of those by current_layer[population] percent.
	
	## however i need to make sure layer 0 just uses the start point, ignoring
	## the previous nonexistant layers growth points.
	
	## after all that, simply iterate through all the population.percent of 
	## growth points. creating a branch with the other applied settings for each.
	
	## Make it recursive?
	## so if more layers are available ahead of current, I'll need to update
	## those too.


func _on_delete_layer_pressed():
	pass # Replace with function body.
