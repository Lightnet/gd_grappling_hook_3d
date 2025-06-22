extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D
@onready var gc = $GrappleController

@export var speed = 15.0
@export var jump_force = 10.0
@export var gravity := 0.5

@export var accelertion := 10.0
@export var deceleration := 8.0

@export var sensitivity := 0.01

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var input_dir = Input.get_vector("left","right","forward","backward")
	var move_vec = (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
	
	if input_dir.length() != 0:
		velocity.x = lerpf(velocity.x, move_vec.x * speed, accelertion * delta)
		velocity.z = lerpf(velocity.z, move_vec.z * speed, accelertion * delta)
	else:
		velocity.x = lerpf(velocity.x, 0, deceleration * delta)
		velocity.z = lerpf(velocity.z, 0, deceleration * delta)
	
	if !is_on_floor():
		velocity.y -= gravity
		
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() || gc.launched:
			velocity.y += jump_force
			gc.retract()
	move_and_slide()
	#pass
