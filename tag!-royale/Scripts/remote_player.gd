extends StaticBody3D


var id = 0
var deathTimer = null
var activePlayers = 0
var tagMaterial = StandardMaterial3D.new()
var baseMaterial = StandardMaterial3D.new()

signal imIt(id)
signal win(id)

func _ready():
	tagMaterial.set("albedo_color", Color(1, 1, 0.2))
	baseMaterial = $MeshInstance3D.get_surface_override_material(0)
	deathTimer = $DeathTimer

func youreIt(playerCount):
	$MeshInstance3D.set_surface_override_material(0, tagMaterial)
	if playerCount > 1:
		self.remove_from_group("Player")
		self.add_to_group("It")
		imIt.emit(id)
	else:
		win.emit(id)
	activePlayers = playerCount
	
	
func explode():
	$MeshInstance3D.visible = false
	self.get_node("CollisionShape3D").call_deferred("set_disabled", true)
	$AudioStreamPlayer3D.play()
	deathTimer.start()
	self.remove_from_group("It")
	self.add_to_group("Ghost")

func _on_area_3d_body_entered(body):
	if self.is_in_group("It") && body.is_in_group("Player"):
		$MeshInstance3D.set_surface_override_material(0, baseMaterial)
		self.remove_from_group("It")
		self.add_to_group("Player")
		body.youreIt(activePlayers)


func _on_death_timer_timeout():
	queue_free()
	
func notIt():
	$MeshInstance3D.set_surface_override_material(0, baseMaterial)
