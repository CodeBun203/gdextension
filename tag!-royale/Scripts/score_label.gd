extends Label

var gems = 0
	
func _on_collected():
	gems += 1
	text = "Gems: %s" % gems

func update_score():
	text = "Gems: %s" % gems
