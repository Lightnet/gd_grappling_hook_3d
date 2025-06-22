@tool
extends MeshInstance3D

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	rotation_degrees.y += 1
	pass
