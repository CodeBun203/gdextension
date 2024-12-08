extends RigidBody3D

@onready var deathTimer = $DeathTimer

func _process(delta):
	angular_velocity.x = 0
	angular_velocity.z = 0

func explode():
	$MeshInstance3D.visible = false
	self.get_node("CollisionShape3D").call_deferred("set_disabled", true)
	$AudioStreamPlayer3D.play()
	deathTimer.start()
	
	
func youreIt():
	self.remove_from_group("Player")
	self.add_to_group("It")
	
func _on_area_3d_body_entered(body):
	if self.is_in_group("It") && body.is_in_group("Player"):
		self.remove_from_group("It")
		self.add_to_group("Player")
		body.youreIt()


func _on_death_timer_timeout():
	queue_free()
