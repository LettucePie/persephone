extends Area2D

var occupants = []
var positions : PackedVector2Array = []
var central_points : Array = []
var neighbor_displacements : PackedVector2Array = []


func setup_grid_params(dp_vec : Vector2):
	neighbor_displacements.clear()
	neighbor_displacements.append(dp_vec)
	neighbor_displacements.append(Vector2(dp_vec.x, 0.0))
	neighbor_displacements.append(Vector2(dp_vec.x, dp_vec.y * -1.0))
	neighbor_displacements.append(Vector2(0.0, dp_vec.y * -1.0))
	neighbor_displacements.append(dp_vec * -1.0)
	neighbor_displacements.append(Vector2(dp_vec.x * -1.0, 0.0))
	neighbor_displacements.append(Vector2(dp_vec.x * -1.0, dp_vec.y))
	neighbor_displacements.append(Vector2(0.0, dp_vec.y))


func _on_body_entered(body):
	if !occupants.has(body):
		occupants.append(body)
		gather_point_positions()


func _on_body_exited(body):
	if occupants.has(body):
		occupants.erase(body)
		gather_point_positions()


func gather_point_positions():
	positions.clear()
	for o in occupants:
		positions.append(o.position)
	positions.sort()
	detect_central_points()


func bundle_relevant_points(min, max):
	var bundle : PackedVector2Array = []
	for p in positions:
		if p > min and p < max:
			bundle.append(p)
	return bundle


func detect_central_points():
	central_points.clear()
	for pos in positions:
		var analyzing : bool = true
		var score = 0
		var rank = 0
		var multiplier = 1.0
		while analyzing:
			for dp_vec in neighbor_displacements:
				if positions.has(pos + (dp_vec * multiplier)):
					score += 1
			if score >= 8:
				rank += 1
				score = 0
				multiplier += 1.0
			else:
				analyzing = false
		if rank > 0:
			central_points.append({"point" = pos, "rank" = rank})


func get_best_central_points():
	if central_points.size() > 0:
		print("Sort_custom")
	else:
		return PackedVector2Array()


func get_rank_at_point(point : Vector2):
	if central_points.size() > 0:
		for cen_point in central_points:
			if point == cen_point["point"]:
				return cen_point["rank"]
	else:
		return null


func get_closest_central_point(pos : Vector2):
#	print("Searching for closest Central Point to pos: ", pos)
	if central_points.size() > 0:
		var closest_point : Vector2 = central_points[0]["point"]
		var compare_distance = get_window().get_size().length() * 2.0
		for cen_point in central_points:
			var dist = cen_point["point"].distance_to(pos)
			if dist < compare_distance:
				compare_distance = dist
				closest_point = cen_point["point"]
#		print("Returning Central Point: ", closest_point)
		return closest_point


func get_closest_grid_point(pos : Vector2, min_frame : Vector2, max_frame : Vector2):
	var compare_distance = get_window().get_size().length() * 2.0
	var closest_grid_point = null
	for grid_pos in positions:
		if grid_pos > min_frame and grid_pos < max_frame:
			var dist = pos.distance_to(grid_pos)
			if dist < compare_distance:
				compare_distance = dist
				closest_grid_point = grid_pos
	print("Returning Closest grid point: ", closest_grid_point, " with distance of: ", compare_distance)
	return closest_grid_point
