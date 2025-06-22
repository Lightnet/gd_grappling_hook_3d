@tool
extends MeshInstance3D
# https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/immediatemesh.html

@export var pos:Vector3

@export var p1:float = 0

func _ready():
	# Begin draw.
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Prepare attributes for add_vertex.
	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 0))
	# Call last for each vertex, adds the above attributes.
	mesh.surface_add_vertex(Vector3(-1, -1, 0))

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 1))
	mesh.surface_add_vertex(Vector3(-1, 1, 0))

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(1, 1))
	mesh.surface_add_vertex(Vector3(1, 1, 0))

	# End drawing.
	mesh.surface_end()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# Clean up before drawing.
	mesh.clear_surfaces()
	
	# Begin draw.
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Prepare attributes for add_vertex.
	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 0))
	# Call last for each vertex, adds the above attributes.
	mesh.surface_add_vertex(Vector3(-1, -1, 0))

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 1))
	mesh.surface_add_vertex(Vector3(-1, 1, 0))

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(1, 1))
	mesh.surface_add_vertex(Vector3(1, p1, 0))
	if p1 > 2:
		p1 = 0
	p1 += 1 * delta

	# End drawing.
	mesh.surface_end()
	pass
