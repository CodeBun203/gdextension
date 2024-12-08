extends CharacterBody3D


const SPEED = 15.0
const JUMP_VELOCITY = 5

var double_jump = true
var wall_jump = true

@export var mouse_sense_horizontal = 0.5
@export var mouse_sense_vertical = 0.25
@onready var camera_mount = $camera_mount
@onready var visuals = $Pivot

var mouseMotion = true

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion and mouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sense_horizontal))
		visuals.rotate_y(deg_to_rad(event.relative.x * mouse_sense_horizontal))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * mouse_sense_vertical))

func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Add the gravity.
	if !is_on_floor() and !is_on_wall_only():
		velocity += get_gravity() * delta
	elif is_on_wall_only():
		velocity += (get_gravity() / 2) * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		double_jump = true
		wall_jump = true


	elif Input.is_action_just_pressed("jump") and !is_on_floor():
		if is_on_wall_only() and wall_jump:
			velocity.x += get_last_slide_collision().get_normal().x * SPEED * JUMP_VELOCITY
			velocity.z += get_last_slide_collision().get_normal().z * SPEED * JUMP_VELOCITY
			velocity.y = JUMP_VELOCITY
			wall_jump = false
		elif double_jump: 
			velocity.y = JUMP_VELOCITY
			double_jump = false
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		visuals.look_at(position + direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
