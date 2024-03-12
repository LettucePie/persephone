extends Node

## ONready UI Stuff
@onready var property_list_ui = $Control/ScrollContainer/VBoxContainer


var length_max : float = 1000
var trunk_start : Vector2
var branch_layers : Array = []
var branch_layer_settings : Array = []
var branch_setting_dict : Dictionary = {
	"population" = 0.0,
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
	length_max = screen_size.length() / 2
	create_default_layer()
	var starting_branch = create_branch(trunk_start, 0.2, 0.0)
	branch_layers[current_layer].append(starting_branch)
	$Node2D.add_child(starting_branch)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func create_branch(start_point : Vector2, length : float, angle : float):
	var new_branch = Line2D.new()
	new_branch.set_points(create_branch_points(start_point, length, angle))
	return new_branch


func edit_branch(
	branch : Line2D, 
	new_start : Vector2, 
	length : float, 
	angle : float):
	####
	print("Edit Branch : ", branch)
	var origin = branch.get_point_position(0)
	if new_start != Vector2.ZERO:
		origin = new_start
	branch.clear_points()
	branch.set_points(create_branch_points(origin, length, angle))


## Builds an array to be used in Create Branch or Edit Branch functions
func create_branch_points(start_point : Vector2, length : float, angle : float):
	var new_points = []
	new_points.append(start_point)
	var next_point = start_point
	var direction = Vector2.UP.rotated(angle)
	next_point += direction * (length * length_max)
	new_points.append(next_point)
	return new_points


func create_growth_points(branch : Line2D, growth : float, length : float):
	var line_points : PackedVector2Array = branch.get_points()
	
	## Segment is the line between two line points.
	## It refers to the current set of points by equaling the end point \
	## and being greater than the start point of each point pair. 
	## Example:
	## Segment 1 is points 0, and 1
	## Segment 5 is points 4, and 5
	## Segment index must be greater than 0.
	## We start with line_points.size() since we will be climbing from the end \
	## of the branch to the beginning.
	var segment_index = line_points.size()
	
	## We're going to try to determine how many growth points can be placed \
	## along a branch.
	## point_gap_distance is the distance between each growth point, along \
	## the whole branch from branch_point 0 to branch_point end.
	## point_quantity will be the number we iterate on to locate these points.
	var point_gap_distance = (length * length_max) * (1.01 - growth)
	var point_quantity = (length * length_max) / point_gap_distance
	
	## Establish the first point_position to be the end.
	## Then build the array, and add the end point.
	var point_position = line_points[segment_index]
	var growth_points : Array = []
	growth_points.append(point_position)
	## Iterate through the remaining point_quantity.
	for p in point_quantity - 1:
		## Start by setting up the distance along the line that remains for \
		## this point.
		var distance_remaining = point_gap_distance
		
		## Figure out the length of the current segment starting from the \
		## previously found point position.
		## At first this will always be the end of the line, over iterations \
		## it will change.
		var segment_length = point_position.distance_to(
			line_points[segment_index - 1])
		
		print("WARNING, STARTING WHILE_LOOP IN create_growth_points function.")
		var e_brake : int = 15
		
		## While Loop through until our distance_remaining is smaller than \
		## the amount of available space on a segment.
		while distance_remaining > segment_length:
			distance_remaining -= segment_length
			segment_index = clampi(segment_index - 1, 1, line_points.size())
			segment_length = line_points[segment_index].distance_to(
				line_points[segment_index - 1])
			## Emergency Brake
			e_brake -= 1
			if e_brake <= 0:
				print("WHILE LOOP E-BRAKE ACTIVATED")
				break
		
		print("Growth point num: ", p, " lies in Segment: ", segment_index)
		
		## Calculate the point position by getting the direction vector from \
		## the current segement end_point to the current segment beginning \
		## point. Then multiply it by the distance_remaining, creating a \
		## displacement vector which we add onto the endpoint of the current \
		## segment.
		point_position = line_points[segment_index] \
		+ (line_points[segment_index].direction_to(
			line_points[segment_index - 1]) * distance_remaining)
		
		growth_points.append(point_position)
	
	return growth_points


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
	$Control/layer/value.text = str(current_layer)
	property_list_ui.get_node("population/value").text = str(settings["population"])
	property_list_ui.get_node("population/population_slider").value = settings["population"]
	property_list_ui.get_node("length/value").text = str(settings["length"])
	property_list_ui.get_node("length/length_slider").value = settings["length"]
	property_list_ui.get_node("angle/value").text = str(settings["angle"])
	property_list_ui.get_node("angle/angle_slider").value = settings["angle"]
	property_list_ui.get_node("growth/value").text = str(settings["growth"])
	property_list_ui.get_node("growth/growth_slider").value = settings["growth"]


func update_setting(value : float, label : String):
	print("Update: ", label, " to ", value)
	branch_layer_settings[current_layer][label] = value
	update_settings_display()
	update_layer()


func update_layer():
	print("TODO")
	var editing_layer = current_layer
	var editing_branches = branch_layers[editing_layer]
	print("editing branches : ", editing_branches)
	for branch in editing_branches:
		edit_branch(
			branch, 
			Vector2.ZERO, 
			branch_layer_settings[current_layer]["length"],
			deg_to_rad(branch_layer_settings[current_layer]["angle"]))
	
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
