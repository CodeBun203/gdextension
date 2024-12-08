extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var summator = Summator.new()
	summator.add(3)
	summator.add(4)
	print(summator.get_total())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
