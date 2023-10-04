extends Area2D

var occupants = []
var positions : PackedVector2Array = []


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
