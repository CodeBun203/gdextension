extends Node

var players = {}
var udp_socket = PacketPeerUDP.new()

# Start the server
func start():
	udp_socket.listen(12345)
	set_process(true)

# Called every frame
func _process(delta):
	while udp_socket.get_available_packet_count() > 0:
		var packet = udp_socket.get_packet()
		handle_packet(packet)

# Handle incoming packets
func handle_packet(packet):
	var message_instance = Message.new()
	var message = message_instance.parse_message(packet)
	if message.type == "join":
		players[message.player_id] = message.position
		broadcast_client_count()
	elif message.type == "update":
		players[message.player_id] = message.position
	broadcast_state()

# Broadcast the client count to all clients
func broadcast_client_count():
	var client_count = str(players.size())
	var message = "client_count," + client_count
	var packet = message.to_utf8_buffer()
	for player_id in players.keys():
		udp_socket.put_packet(packet)

# Broadcast the game state to all clients
func broadcast_state():
	for player_id in players.keys():
		var message_instance = Message.new()
		var state = message_instance.create_state_message(player_id, players[player_id])
		var packet = state_to_packet(state)
		udp_socket.put_packet(packet)

# Convert a state message to a packet
func state_to_packet(state):
	var data = state.type + "," + state.player_id + "," + str(state.position.x) + "," + str(state.position.y)
	return data.to_utf8_buffer()
