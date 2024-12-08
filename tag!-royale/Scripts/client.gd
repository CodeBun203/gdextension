extends Node

var udp_socket = PacketPeerUDP.new()
var server_address = "127.0.0.1"
var server_port = 12345
var client_count_label = null

# Called when the node is added to the scene
func _ready():
	udp_socket.connect_to_host(server_address, server_port)
	set_process(true)
	client_count_label = $ClientsWaitingLabel
	send_join_message()

# Send a join message to the server
func send_join_message():
	var player_id = "player" + str(randi() % 1000)  # Example player ID
	var message = "join," + player_id + ",0,0"
	var packet = message.to_utf8_buffer()
	udp_socket.put_packet(packet)

# Called every frame
func _process(delta):
	while udp_socket.get_available_packet_count() > 0:
		var packet = udp_socket.get_packet()
		handle_packet(packet)

# Handle incoming packets
func handle_packet(packet):
	var data = packet.get_string_from_utf8()
	print("Received packet: ", data)  # Debugging
	var parts = data.split(",")
	if parts[0] == "client_count":
		update_client_count(parts[1].to_int())
	else:
		var message_instance = Message.new()
		var message = message_instance.parse_message(packet)
		if message.type == "state":
			update_game_state(message)

# Update the client count label
func update_client_count(count):
	print("Updating client count to: ", count)  # Debugging
	client_count_label.text = "Clients in Lobby: " + str(count)

# Send an action message to the server
func send_action(action):
	var message_instance = Message.new()
	var message = message_instance.create_action_message(action)
	var packet = action_to_packet(message)
	udp_socket.put_packet(packet)

# Update the game state based on the message
func update_game_state(message):
	# Update the game state based on the message
	pass

# Convert an action message to a packet
func action_to_packet(action):
	var data = action.type + "," + action.player_id + "," + str(action.position.x) + "," + str(action.position.y)
	return data.to_utf8_buffer()
