extends Node

@onready var player:CharacterBody3D = get_parent()

@export var ray:RayCast3D
@export var rope_generator:Node3D
@export var rest_length = 2.0
@export var stiffness = 10.0
@export var damping = 1.0

var target:Vector3
var launched = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		lanuch()
		rope_generator.visible = true
		rope_generator.StartDrawing()
	if Input.is_action_just_released("shoot"):
		retract()
		rope_generator.StopDrawing()
		
	if launched:
		handle_grapple(delta)
		
	update_rope()
		
func lanuch():
	if ray.is_colliding():
		target = ray.get_collision_point()
		#print("hit...")
		launched = true
		#rope_generator.visible = true
		#rope_generator.SetPlayerPosition(player.global_position)
		print("target: ",target)
		print("rope_generator:", rope_generator)
		#rope_generator.SetGrappleHookPosition(target)
		rope_generator.grapple_hook_position = target
	#pass

func retract():
	launched = false
	#pass
	
func handle_grapple(delta: float):
	
	var target_dir = player.global_position.direction_to(target)
	var target_dist = player.global_position.distance_to(target)
	
	var displacement = target_dist - rest_length
	
	var force = Vector3.ZERO
	
	if displacement > 0:
		var spring_force_magnitude = stiffness * displacement
		var spring_force = target_dir * spring_force_magnitude
	
		var vel_dot = player.velocity.dot(target_dir)
		var damping = -damping * vel_dot * target_dir
	
		force = spring_force + damping
		
	player.velocity += force * delta
	#pass

func update_rope():
	if !launched:
		rope_generator.visible = false
		return
	rope_generator.SetPlayerPosition(player.global_position)
	#pass
