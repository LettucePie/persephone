extends Area2D

var occupants = []
var positions : PackedVector2Array = []


func _on_body_entered(body):
	if !occupants.has(body):
		occupants.append(body)


func _on_body_exited(body):
	if occupants.has(body):
		occupants.erase(body)
