extends Node

var server = null
var client = null

# Called when the node is added to the scene
func _ready():
	if is_server():
		server = load("res://Scripts/server.gd").new()
		add_child(server)
		server.start()
	else:
		client = load("res://Scripts/client.gd").new()
		add_child(client)
		client.connect_to_server("127.0.0.1", 12345)

# Check if the current instance is the server
func is_server():
	return OS.get_cmdline_args().has("--server")
