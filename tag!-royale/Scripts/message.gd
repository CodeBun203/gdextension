extends RefCounted
class_name Message

var type = ""
var player_id = ""
var position = Vector2()
var address = ""
var port = 0

# Parse a message from a packet
func parse_message(packet):
	var message = Message.new()
	var data = packet.get_string_from_utf8()
	var parts = data.split(",")
	message.type = parts[0]
	message.player_id = parts[1]
	message.position = Vector2(parts[2].to_float(), parts[3].to_float())
	return message

# Create a state message
func create_state_message(player_id, position):
	var message = Message.new()
	message.type = "state"
	message.player_id = player_id
	message.position = position
	return message

# Create an action message
func create_action_message(action):
	var message = Message.new()
	message.type = "action"
	message.player_id = action["player_id"]
	message.position = action["position"]
	return message
