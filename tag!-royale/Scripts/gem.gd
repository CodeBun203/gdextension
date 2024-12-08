extends Area3D

signal collected(id)

var id = 0
func _on_body_entered(body):
	if body.is_in_group("Player") || body.is_in_group("It"):
		collected.emit(id)
		$AudioStreamPlayer2D.play()
