extends CharacterBody3D

@export var SPEED = 5.0
@export var GHOSTSPEED = 15.0
@export var JUMP_FORCE = 5.0
@export var GRAVITY = -9.8
@export var WALL_FORCE = 50.0
@export var DASH_FORCE = 2.0

const MAX_SPEED = 15

var double_jump = true
var dash = true
var wall_jump = true
var mouseMotion = true
var id = 0

@export var mouse_sense_horizontal = 0.5
@export var mouse_sense_vertical = 0.25
@onready var camera_mount = $camera_mount
@onready var visuals = $Pivot
@onready var animPlayer = $AnimationPlayer
@onready var tagLabel = $TagLabel
@onready var winLabel = $WinLabel
@onready var outLabel = $OutLabel
@onready var finalWinLabel = $FinalWinLabel
@onready var graceTimer = $GraceTimer
@onready var sound = $AudioStreamPlayer2D

signal imIt(id)
signal win(id)

var gameMode = 0
var activePlayers = 0

var tagMaterial = StandardMaterial3D.new()
var baseMaterial = StandardMaterial3D.new()

func _ready():
	tagMaterial.set("albedo_color", Color(1, 1, 0.2))
	baseMaterial = $Pivot/Character.get_surface_override_material(0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	tagLabel.visible = false
	winLabel.visible = false
	outLabel.visible = false
	finalWinLabel.visible = false

func _input(event):
	if event is InputEventMouseMotion and mouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sense_horizontal))
		visuals.rotate_y(deg_to_rad(event.relative.x * mouse_sense_horizontal))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * mouse_sense_vertical))

func _physics_process(delta):
		# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if gameMode == 0:	
		# Apply gravity.
		if !is_on_floor() and !is_on_wall_only():
			velocity.y += GRAVITY * delta
		elif is_on_wall_only():
			velocity.y += (GRAVITY / 2) * delta
		if is_on_floor():
			dash = true

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_FORCE
			double_jump = true
			wall_jump = true
		elif Input.is_action_just_pressed("jump") and !is_on_floor():
			if is_on_wall_only() and wall_jump:
				var wall_normal = get_wall_normal()
				velocity = Vector3(wall_normal.x * WALL_FORCE, JUMP_FORCE, wall_normal.z * WALL_FORCE)
				wall_jump = false
			elif double_jump:
				velocity.y = JUMP_FORCE
				double_jump = false
		
		else:
				
			if direction:
				velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, SPEED)
				velocity.z = move_toward(velocity.z, direction.z * MAX_SPEED, SPEED)
				visuals.look_at(position + direction)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
			if Input.is_action_just_pressed("dash") and dash:
					dash = false
					velocity -= visuals.global_transform.basis.z * DASH_FORCE
					sound.stream = preload("res://SFX/Woosh.wav")
					sound.play()

	else:
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, SPEED)
			velocity.z = move_toward(velocity.z, direction.z * MAX_SPEED, SPEED)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		if Input.is_action_pressed("jump"):
			position.y += GHOSTSPEED * delta
		if Input.is_action_pressed("dash"):
			position.y -= GHOSTSPEED * delta
			
	move_and_slide()
	
func explode():
	$Pivot/Character.get_surface_override_material(0).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outLabel.visible = true
	animPlayer.play("Out")
	self.visible = false
	self.get_node("CollisionShape3D").call_deferred("set_disabled", true)
	self.get_node("CPUParticles3D").emitting = true
	$Pivot/Character.visible = false
	GRAVITY = 0
	self.remove_from_group("It")
	self.add_to_group("Ghost")
	velocity = Vector3.ZERO
	gameMode = 1


func _on_area_3d_body_entered(body):
	if self.is_in_group("It") && body.is_in_group("Player"):
		$Pivot/Character.set_surface_override_material(0, baseMaterial)
		self.remove_from_group("It")
		self.add_to_group("Grace")
		body.youreIt(activePlayers)
		graceTimer.start()
		
func youreIt(playerCount):
	activePlayers = playerCount
	$Pivot/Character.set_surface_override_material(0, tagMaterial)
	if playerCount > 1:
		tagLabel.visible = true
		animPlayer.play("Tagged")
		self.remove_from_group("Player")
		self.add_to_group("It")
		imIt.emit(id)	
	else:
		winLabel.visible = true
		get_tree().current_scene.get_node("AudioStreamPlayer2D").stop()
		sound.stream = preload("res://SFX/Victory.mp3")
		sound.play()
		win.emit(id)

func _on_grace_timer_timeout():
	self.remove_from_group("Grace")
	self.add_to_group("Player")
	
func winScreen(othId):
	winLabel.visible = false
	tagLabel.visible = false
	outLabel.visible = false
	if othId == id:
		finalWinLabel.text = "You Won!"
	else:
		finalWinLabel.text = "Player " + str(othId) + " Won!"
	finalWinLabel.visible = true

func notIt():
	$Pivot/Character.set_surface_override_material(0, baseMaterial)
