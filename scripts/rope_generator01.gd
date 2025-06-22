@tool
extends MeshInstance3D

@export var tmp_player: Node3D
@export var tmp_hook: Node3D 
@export var isDrawing: bool = false:
	set(value):
		isDrawing = value
		if Engine.is_editor_hint():
			_update_mesh_in_editor()
@export var firstTime: bool = true
@export var dirty: bool = false
@export var iterations: int = 10
@export var point_count: int = 20
@export var gravity_default: float = 9.8
@export var point_spacing: float = 0.1
@export var rope_radius: float = 0.05  # Radius of the rope mesh
@export var circle_segments: int = 8    # Number of vertices in the cross-section circle

var rope_length: float
var points: Array[Vector3] = []
var points_old: Array[Vector3] = []
var tangent_array: Array[Vector3] = []
var normal_array: Array[Vector3] = []
var vertex_array: Array[Vector3] = []
var index_array: Array[int] = []
var uv_array: Array[Vector2] = []  # Added for UV mapping (optional)

var player_position: Vector3
var grapple_hook_position: Vector3

func _ready() -> void:
	mesh = ImmediateMesh.new()
	if Engine.is_editor_hint():
		print("Editor: _ready called")
		if not tmp_player:
			printerr("Editor: tmp_player is not assigned in _ready!")
		if not tmp_hook:
			printerr("Editor: tmp_hook is not assigned in _ready!")
		_update_mesh_in_editor()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_mesh_in_editor()
		return
	
	if not tmp_player or not tmp_hook:
		printerr("Runtime: tmp_player or tmp_hook is not assigned! tmp_player: ", tmp_player, ", tmp_hook: ", tmp_hook)
		return
	
	player_position = tmp_player.global_position
	grapple_hook_position = tmp_hook.global_position
	#print("Runtime: Player position: ", player_position, ", Hook position: ", grapple_hook_position)
	
	if isDrawing || dirty:
		if firstTime:
			print("Runtime: Initializing points...")
			PreparePoints()
			if points.is_empty():
				printerr("Runtime: Failed to initialize points! Points size: ", points.size())
			else:
				print("Runtime: Points initialized. Points size: ", points.size())
			firstTime = false
		if points.size() >= 2:
			print("Runtime: Updating points and generating mesh...")
			UpdatePoints(delta)
			GenerateMesh()
		else:
			printerr("Runtime: Not enough points to generate mesh! Points size: ", points.size())

func _update_mesh_in_editor() -> void:
	if not tmp_player or not tmp_hook:
		printerr("Editor: tmp_player or tmp_hook is not assigned! tmp_player: ", tmp_player, ", tmp_hook: ", tmp_hook)
		mesh.clear_surfaces()
		return
	
	player_position = tmp_player.global_position
	grapple_hook_position = tmp_hook.global_position
	#print("Editor: Player position: ", player_position, ", Hook position: ", grapple_hook_position)
	
	if isDrawing || dirty:
		if firstTime:
			print("Editor: Initializing points...")
			PreparePoints()
			if points.is_empty():
				printerr("Editor: Failed to initialize points! Points size: ", points.size())
			else:
				print("Editor: Points initialized. Points size: ", points.size())
			firstTime = false
		if points.size() >= 2:
			print("Editor: Generating mesh...")
			GenerateMesh()
		else:
			printerr("Editor: Not enough points to generate mesh! Points size: ", points.size())

func StartDrawing() -> void:
	isDrawing = true
	firstTime = true
	if Engine.is_editor_hint():
		_update_mesh_in_editor()

func StopDrawing() -> void:
	isDrawing = false
	mesh.clear_surfaces()
	if Engine.is_editor_hint():
		_update_mesh_in_editor()

func PreparePoints():
	points.clear()
	points_old.clear()
	
	for i in range(point_count):
		var t = i / (point_count - 1.0)
		points.append(lerp(player_position, grapple_hook_position, t))
		points_old.append(points[i])
	#_UpdatePointSpacing()
	print("PreparePoints:", points.size())
	
	pass

#func PreparePoints() -> void:
	#points.clear()
	#points_old.clear()
	#
	## Debug: Check inputs
	#print("PreparePoints: Player: ", player_position, ", Hook: ", grapple_hook_position)
	#print("PreparePoints: point_count: ", point_count)
	#
	## Check if positions are valid
	#var distance = player_position.distance_to(grapple_hook_position)
	#if distance < 0.01:
		#printerr("PreparePoints: Player and hook positions are too close! Distance: ", distance)
		#return
	#
	#rope_length = distance
	#if rope_length < 0.01:
		#printerr("PreparePoints: Rope length too small! Rope length: ", rope_length)
		#return
	#
	#if point_count < 2:
		#printerr("PreparePoints: point_count too low! point_count: ", point_count)
		#return
	#
	#point_spacing = rope_length / max(point_count - 1.0, 1.0)
	#print("PreparePoints: Rope length: ", rope_length, ", Point spacing: ", point_spacing)
	#
	#for i in range(point_count):
		#var t: float = i / (point_count - 1.0)
		#var point: Vector3 = lerp(player_position, grapple_hook_position, t)
		#points.append(point)
		#points_old.append(point)
		## Debug: Log each point
		#print("PreparePoints: Added point ", i, ": ", point)
	#
	## Debug: Confirm points were added
	#print("PreparePoints: Total points: ", points.size())

func UpdatePoints(delta: float) -> void:
	if points.size() < 2:
		printerr("UpdatePoints: Not enough points! Points size: ", points.size())
		return
	
	points[0] = player_position
	points[point_count - 1] = grapple_hook_position
	
	# Verlet integration
	for i in range(1, point_count - 1):
		var velocity: Vector3 = points[i] - points_old[i]
		points_old[i] = points[i]
		points[i] += velocity + Vector3.DOWN * gravity_default * delta * delta
	
	# Apply constraints
	for _i in range(iterations):
		ConstraintConnections()

func ConstraintConnections() -> void:
	if points.size() < 2:
		printerr("ConstraintConnections: Not enough points! Points size: ", points.size())
		return
	
	for i in range(point_count - 1):
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[i + 1]
		var offset: Vector3 = p2 - p1
		var length: float = offset.length()
		var dir: Vector3 = offset.normalized() if length > 0 else Vector3.ZERO
		var correction: float = (length - point_spacing) * 0.5
		
		if i != 0:
			points[i] += dir * correction
		if i + 1 != point_count - 1:
			points[i + 1] -= dir * correction

func CalculateNormals() -> void:
	normal_array.clear()
	tangent_array.clear()
	
	if points.size() < 2:
		printerr("CalculateNormals: Not enough points! Points size: ", points.size())
		return
	
	for i in range(point_count):
		var tangent: Vector3
		var normal: Vector3
		
		# Compute tangent
		if i == 0:
			tangent = (points[i + 1] - points[i]).normalized()
		elif i == point_count - 1:
			tangent = (points[i] - points[i - 1]).normalized()
		else:
			tangent = ((points[i + 1] - points[i]).normalized() + (points[i] - points[i - 1]).normalized()).normalized()
		
		# Compute normal using a reference vector
		var ref_vector: Vector3 = Vector3.UP if abs(tangent.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
		normal = tangent.cross(ref_vector).normalized()
		
		# Ensure continuity by aligning with previous normal
		if i > 0:
			var prev_normal: Vector3 = normal_array[i - 1]
			var bitangent: Vector3 = tangent.cross(normal)
			if bitangent.length() > 0:
				var rotation_axis: Vector3 = bitangent.normalized()
				var prev_tangent: Vector3 = tangent_array[i - 1]
				var angle: float = acos(prev_tangent.dot(tangent))
				var rotation: Basis = Basis(rotation_axis, angle)
				normal = (rotation * prev_normal).normalized()
		
		tangent_array.append(tangent)
		normal_array.append(normal)

func GenerateMesh() -> void:
	vertex_array.clear()
	index_array.clear()
	uv_array.clear()
	
	CalculateNormals()
	
	if tangent_array.size() != point_count:
		printerr("GenerateMesh: Tangent array size mismatch! Expected: ", point_count, ", Got: ", tangent_array.size())
		return
	
	# Generate vertices for a cylindrical mesh
	for i in range(point_count):
		var tangent: Vector3 = tangent_array[i]
		var normal: Vector3 = normal_array[i]
		var binormal: Vector3 = tangent.cross(normal).normalized()
		
		# Create a circle of vertices around the current point
		for j in range(circle_segments):
			var angle: float = (j / float(circle_segments)) * TAU
			var cos_a: float = cos(angle)
			var sin_a: float = sin(angle)
			var offset: Vector3 = (normal * cos_a + binormal * sin_a) * rope_radius
			vertex_array.append(points[i] + offset)
			uv_array.append(Vector2(j / float(circle_segments), i / float(point_count - 1)))
			# Debug: Log vertex
			if i == 0 and j == 0:
				print("GenerateMesh: Sample vertex: ", points[i] + offset)
	
	# Generate triangle indices
	for i in range(point_count - 1):
		for j in range(circle_segments):
			var j_next: int = (j + 1) % circle_segments
			var v0: int = i * circle_segments + j
			var v1: int = i * circle_segments + j_next
			var v2: int = (i + 1) * circle_segments + j
			var v3: int = (i + 1) * circle_segments + j_next
			
			# First triangle
			index_array.append(v0)
			index_array.append(v1)
			index_array.append(v2)
			# Second triangle
			index_array.append(v1)
			index_array.append(v3)
			index_array.append(v2)
	
	# Create the mesh
	mesh.clear_surfaces()
	if vertex_array.size() == 0 or index_array.size() == 0:
		printerr("GenerateMesh: Vertex or index array is empty! Vertices: ", vertex_array.size(), ", Indices: ", index_array.size())
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(index_array.size() / 3):
		var idx0: int = index_array[i * 3]
		var idx1: int = index_array[i * 3 + 1]
		var idx2: int = index_array[i * 3 + 2]
		
		var p0: Vector3 = vertex_array[idx0]
		var p1: Vector3 = vertex_array[idx1]
		var p2: Vector3 = vertex_array[idx2]
		
		# Compute face normal
		var edge1: Vector3 = p1 - p0
		var edge2: Vector3 = p2 - p0
		var normal: Vector3 = edge1.cross(edge2).normalized()
		
		# Add vertices with normals and UVs
		mesh.surface_set_normal(normal)
		mesh.surface_set_uv(uv_array[idx0])
		mesh.surface_add_vertex(p0)
		
		mesh.surface_set_normal(normal)
		mesh.surface_set_uv(uv_array[idx1])
		mesh.surface_add_vertex(p1)
		
		mesh.surface_set_normal(normal)
		mesh.surface_set_uv(uv_array[idx2])
		mesh.surface_add_vertex(p2)
	
	mesh.surface_end()
	# Debug: Confirm mesh generation
	print("GenerateMesh: Mesh generated. Vertices: ", vertex_array.size(), ", Triangles: ", index_array.size() / 3)
