extends PathFollow3D

@export var moveSpeed = 4

func _ready():
	self.progress_ratio = 0.0001

func _process(delta):
	self.progress += moveSpeed * delta
	if self.progress_ratio == 1 || self.progress_ratio == 0:
		moveSpeed = -moveSpeed
