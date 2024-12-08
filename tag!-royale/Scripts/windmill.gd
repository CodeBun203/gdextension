extends StaticBody3D

@export var rot_speed = 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_z(rot_speed * delta)
