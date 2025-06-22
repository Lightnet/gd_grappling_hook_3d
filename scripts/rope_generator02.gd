@tool #real time update for editor
extends MeshInstance3D
# https://www.youtube.com/watch?v=yuU6DO9-enM 2.46

"""
#...
	if Input.is_action_just_pressed("shoot"):
		lanuch()
		rope_generator.visible = true
		rope_generator.StartDrawing()
	if Input.is_action_just_released("shoot"):
		retract()
		rope_generator.visible = false
		rope_generator.StopDrawing()
#...
func lanuch():
	if ray.is_colliding():
		target = ray.get_collision_point()
		launched = true
		rope_generator.grapple_hook_position = target
#...
	if !launched:
		rope_generator.visible = false
		return
	rope_generator.SetPlayerPosition(player.global_position)
"""

@onready var tmp_player: Node3D = $tmpPlayer
@onready var tmp_hook: Node3D = $tmpHook
## first time to create points rope
@export var firstTime:bool = true
## create points and rebuild mesh
@export var isDrawing:bool = false:
	set(value):
		isDrawing = value
		firstTime = value
## update points again...
@export var dirty:bool = false
## springs for rope if disable it will fall stretch. It how much will it move.
@export var iterations: int  = 10
## many points for rope to draw line mesh
@export var point_count: int  = 20 
## this handle rope drop which required iterations to stop infi fall. 0 to stop drop.
@export var gravity_default: float = 9.8
## debug position from player and image position target hook
@export var is_editor:bool = false
## number segements for rings 2 min to draw rope. 1 no rope. 0 below error.
@export var resoulution:int = 4
var point_spacing: float = 0.1
var rope_length: float
## rope radius
@export var rope_width: float = 0.1

@export var texture_height_to_width:float = 0.5 # 2048x1024 > Width is 2x more than height
@export var uv_scale:float = 0.5
# mesh generate
var points: Array[Vector3] = []
var points_old: Array[Vector3] = []
var tangent_array: Array[Vector3] = []
var normal_array: Array[Vector3] = []
var vertex_array: Array[Vector3] = []
var index_array: Array[int] = []
#var uv_array: Array[Vector2] = []  # For UV mapping
var uv1_array: Array[Vector2] = []  # For UV mapping
# placeholder node3d position
@export var player_position:Vector3 = Vector3.ZERO
@export var grapple_hook_position:Vector3 = Vector3.ZERO

#func _ready() -> void:
	#pass 
	
# called every frame 'delta' is the elapsed time since the previus frame
func _process(delta: float) -> void:
	
	#if not tmp_player or not tmp_hook:
		#printerr("Runtime: tmp_player or tmp_hook is not assigned! tmp_player: ", tmp_player, ", tmp_hook: ", tmp_hook)
		#return
	if is_editor:
		##print("update?")
		SetPlayerPosition(tmp_player.position)
		SetGrappleHookPosition(tmp_hook.position)
	if grapple_hook_position.length() == 0:
		return
		
	if isDrawing || dirty:
		if firstTime:
			#print("first time")
			PreparePoints()
			#print("PreparePoints")
			firstTime = false
		UpdatePoints(delta)
		#print("UpdatePoints")
		GenerateMesh()
		#print("GenerateMesh")
		dirty = false
	#pass

func SetPlayerPosition(pos):
	player_position = pos

func SetGrappleHookPosition(pos):
	grapple_hook_position = pos

func StartDrawing():
	isDrawing = true
	#visible = true
	
func StopDrawing():
	isDrawing = false
	#visible = false
	
func PreparePoints():
	points.clear()
	points_old.clear()
	
	for i in range(point_count):
		var t = i / (point_count - 1.0)
		points.append(lerp(player_position, grapple_hook_position, t))
		points_old.append(points[i])
	_UpdatePointSpacing()
	print("points:", points.size())
	#pass
	
func _UpdatePointSpacing():
	rope_length = (grapple_hook_position - player_position).length()
	point_spacing = rope_length / (point_count - 1.0)
	#pass

func UpdatePoints(delta):
	#print("grapple_hook_position?", grapple_hook_position)
	points[0] = player_position
	points[point_count-1] = grapple_hook_position
	
	_UpdatePointSpacing()
	
	for i in range(1, point_count - 1):
		var curr:Vector3 = points[i]
		points[i] =  points[i] + (points[i] - points_old[i]) + (
			Vector3.DOWN * gravity_default * delta * delta)
		points_old[i] = curr
	
	# animation spring
	for i in range(iterations):
		ConstraintConnections()
		pass

func ConstraintConnections():
	#print("ConstraintConnections")
	for i in range(point_count - 1):
		var center:Vector3 = (points[i+1] + points[i]) / 2.0
		var offset:Vector3 = (points[i+1] - points[i])
		var length:float = offset.length()
		var dir :Vector3 = offset.normalized()
		
		var d = length - point_spacing
		
		if i != 0:
			points[i] += dir * d * 0.5
			
		if i + 1 != point_count - 1:
			points[i+1] -= dir * d * 0.5
		
	#pass

func GenerateMesh():
	# Safeguard against invalid setup
	if points.is_empty() or point_count < 2 or resoulution < 3:
		print("GenerateMesh: Invalid setup (empty points, point_count < 2, or resoulution < 3)")
		mesh = null
		return
	
	vertex_array.clear()
	uv1_array.clear()
	index_array.clear()
	
	# Calculate normals and tangents
	CalcuateNormals()  # Fixed typo: was CalcuateNormals
	
	# Create ImmediateMesh
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Total rope length for UV scaling
	var total_rope_length = (grapple_hook_position - player_position).length()
	if total_rope_length == 0:
		total_rope_length = 0.001  # Prevent division by zero
	
	# Circumference for UV aspect ratio
	var circumference = 2.0 * PI * rope_width
	var uv_segment_length = circumference * texture_height_to_width
	
	# Generate vertices, UVs, and indices
	for p in range(point_count):
		var center: Vector3 = points[p]
		var forward = tangent_array[p]
		var norm = normal_array[p]
		var bitangent = norm.cross(forward).normalized()
		
		# UV V-coordinate: normalized distance along rope
		var distance_from_start = (center - player_position).length()
		var uv1_v = distance_from_start / total_rope_length
		
		# Generate vertices for the segment
		for c in range(resoulution):
			var angle = (float(c) / resoulution) * 2.0 * PI
			var xVal = sin(angle) * rope_width
			var yVal = cos(angle) * rope_width
			
			var point = (norm * xVal) + (bitangent * yVal) + center
			vertex_array.append(point)
			
			# UV U-coordinate: angle around the rope
			var uv1_u = float(c) / resoulution
			uv1_array.append(Vector2(uv1_u, uv1_v) * uv_scale)
			
			# Generate triangle indices
			if p < point_count - 1:
				var start_index = resoulution * p
				# First triangle
				index_array.append(start_index + c)
				index_array.append(start_index + c + resoulution)
				index_array.append(start_index + (c + 1) % resoulution)
				# Second triangle
				index_array.append(start_index + (c + 1) % resoulution)
				index_array.append(start_index + c + resoulution)
				index_array.append(start_index + (c + 1) % resoulution + resoulution)
	
	# Add triangles to ImmediateMesh
	for i in range(index_array.size() / 3):
		var p1 = vertex_array[index_array[3 * i]]
		var p2 = vertex_array[index_array[3 * i + 1]]
		var p3 = vertex_array[index_array[3 * i + 2]]
		
		var uv1 = uv1_array[index_array[3 * i]]
		var uv2 = uv1_array[index_array[3 * i + 1]]
		var uv3 = uv1_array[index_array[3 * i + 2]]
		
		# Calculate triangle normal
		var edge1 = p2 - p1
		var edge2 = p3 - p1
		var normal = edge1.cross(edge2).normalized()
		
		# Add vertices with normals and UVs
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_set_uv(uv1)
		immediate_mesh.surface_add_vertex(p1)
		
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_set_uv(uv2)
		immediate_mesh.surface_add_vertex(p2)
		
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_set_uv(uv3)
		immediate_mesh.surface_add_vertex(p3)
	
	# End mesh
	immediate_mesh.surface_end()
	mesh = immediate_mesh

func CalcuateNormals():
	normal_array.clear()
	tangent_array.clear()
	
	for i in range(point_count):
		var tangent := Vector3(0,0,0)
		var normal := Vector3(0,0,0)
		
		var temp_helper_vector := Vector3(0,0,0)
		
		#first point
		if i == 0:
			tangent = (points[i + 1] - points[i]).normalized()
		#last point
		elif i == point_count - 1:
			tangent = (points[i] - points[i-1]).normalized()
		#between point
		else:
			tangent = (points[i+1] - points[i]).normalized() + (
				points[i] - points[i - 1]).normalized()
		
		if i == 0:
			temp_helper_vector = -Vector3.FORWARD if (
				tangent.dot(Vector3.UP) > 0.5) else Vector3.UP
			
			normal = temp_helper_vector.cross(tangent).normalized()
			
		else:
			var tangent_prev = tangent_array[i-1]
			var normal_prev = normal_array[i-1]
			var bitangent = tangent_prev.cross(tangent)
			
			if bitangent.length() == 0:
				normal = normal_prev
			else:
				var bitangent_dir =bitangent.normalized()
				var theta = acos(tangent_prev.dot(tangent))
			
				var rotate_matrix = Basis(bitangent_dir, theta)
				normal = (rotate_matrix * normal_prev).normalized()
		tangent_array.append(tangent)
		normal_array.append(normal)
	#pass
#
