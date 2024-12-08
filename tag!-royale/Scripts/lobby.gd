extends Control

@onready var client_waiting_label = $ColorRect/ClientsWaitingLabel

var server = null
var client = null
var port = 2395

signal addPlayer(player)
signal startGame
signal updateRemoteData(id, pos, rot)
signal tag(id)
signal isServer()
signal explode(id)
signal won(id)
signal windmill(rot)

var playerScene = null
var remotePlayerScene = null

var player = null
var remotePlayer = null

var gameStart : bool = false

var tempPos = Vector3.ZERO
var tempRot = Vector3.ZERO

var timer = 0
var clientCount = 0

var it
var exploded
var winner

var ip


func _ready():
	playerScene = load("res://Scenes/player.tscn")
	remotePlayerScene = load("res://Scenes/remote_player.tscn")
	var args = OS.get_cmdline_args()
	get_tree().root.get_window().connect("close_requested", Callable(self, "_on_close_requested"))
	it = -1
	exploded = -1
	winner = -1
	$ColorRect/ClientsWaitingLabel.visible = false
	$ColorRect/Back.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func start_server():
	isServer.emit()
	server = Server.new()
	server.start(port)
	#add_child(server)
	set_process(true)

func start_client():
	client = Client.new()
	client.connect_to_server(ip, port)
	#add_child(client)
	set_process(true)
	client.setLabel(client_waiting_label)

func _input(event):
	if event.is_action_pressed("ui_accept") && !gameStart && server:
		server.setStart(1)
		gameStart = true
		startTheGame()

func startTheGame():
	var count = 0
	if client:
		client.send_message("GET ClientCount")
		clientCount = client.getClientCount()
		for user in range(clientCount):
			if count == client.getClientId():
				print("Creating Player")
				player = playerScene.instantiate()
				player.id = count
				addPlayer.emit(player)
			else:
				remotePlayer = remotePlayerScene.instantiate()
				remotePlayer.name = "RemotePlayer" + str(count)
				remotePlayer.id = count
				addPlayer.emit(remotePlayer)
			count += 1

	if server:
		clientCount = server.getClientCount()
		for user in range(clientCount):
			if count == 0:
				print("Creating Player")
				player = playerScene.instantiate()
				player.id = 0
				addPlayer.emit(player)
			else:
				remotePlayer = remotePlayerScene.instantiate()
				remotePlayer.name = "RemotePlayer" + str(count)
				remotePlayer.id = count
				addPlayer.emit(remotePlayer)
			count += 1

	print("Player id: " + str(player.id))
	startGame.emit()
	get_child(0).visible = false

func _process(delta):
	timer += 1
	var temp = 0
	
	if server && !gameStart:
		client_waiting_label.text = "Lobby: %d" % server.getClientCount()
		windmill.emit(0)

	if client && !gameStart:
		client.send_message("GET Windmill")
		windmill.emit(client.getWindmillRotation())
		client.send_message("GET Start")
		gameStart = client.getStartGame()
		if gameStart:
			startTheGame()
		client.send_message("GET ClientCount")

	if client && gameStart && timer >= 2:
		if timer >= 2:
			client.send_message("POST Position " + str(player.id) + " " + str(player.position.x) + " " + str(player.position.y) + " " + str(player.position.z))
			client.send_message("POST Rotation " + str(player.id) + " " + str(player.rotation.x) + " " + str(player.rotation.y) + " " + str(player.rotation.z))
			
			for data in range(clientCount):
				if data != player.id:
					client.send_message("GET Position " + str(data))
					client.send_message("GET Rotation " + str(data))
					updateRemoteData.emit(data, client.getClientPosition(data), client.getClientRotation(data))
			
			client.send_message("GET Exploded")
			if exploded != client.getExploded():
				exploded = client.getExploded()
				explode.emit(exploded)
				
			client.send_message("GET It")
			if it != client.getIt():
				it = client.getIt()
				tag.emit(it)
				
			client.send_message("GET Winner")
			if winner != client.getWinner():
				winner = client.getWinner()
				won.emit(winner)

	if server && gameStart && timer >= 2:
		if timer >= 2:
			server.setClientPosition(0, player.position.x, player.position.y, player.position.z)
			server.setClientRotation(0, player.rotation.x, player.rotation.y, player.rotation.z)
			for data in range(clientCount):
				if data != player.id:
					updateRemoteData.emit(data, server.getClientPosition(data), server.getClientRotation(data))

func explodeClient(cliId):
	exploded = cliId
	if server:
		server.setExploded(cliId)

func remoteYoureIt(cliId):
	it = cliId
	if server:
		server.setIt(cliId)

func setWinner(cliId):
	winner = cliId
	if server:
		server.setWinner(cliId)
		
func setWindmillRotation(rot):
	if server:
		server.setWindmillRotation(rot)

func _on_quit_pressed():
	if client:
		client.disconnect()
	get_tree().quit()
	
func _on_close_requested():
	if client:
		client.disconnect()


func _on_start_pressed():
	$ColorRect/Join.visible = false
	$ColorRect/Start.visible = false
	$ColorRect/ClientsWaitingLabel.visible = true
	$ColorRect/Back.visible = true
	$ColorRect/StartLabel.visible = true
	start_server()

func _on_back_pressed():
	$ColorRect/ClientsWaitingLabel.visible = false
	$ColorRect/Back.visible = false
	$ColorRect/FailedLabel.visible = false
	$ColorRect/LineEdit.visible = false
	$ColorRect/JoinLabel.visible = false
	$ColorRect/Join.visible = true
	$ColorRect/Start.visible = true
	$ColorRect/StartLabel.visible = false
	if client:
		client.disconnect()


func _on_join_pressed():
	$ColorRect/JoinLabel.visible = true
	$ColorRect/LineEdit.visible = true
	$ColorRect/Back.visible = true
	$ColorRect/Start.visible = false
	$ColorRect/Join.visible = false


func _on_line_edit_text_submitted(new_text):
	var count = 0
	ip = new_text
	start_client()
	while count < 100000:
		count += 1
	print(str(client.getClientId()))
	if client.getClientId() != -1:
		$ColorRect/LineEdit.visible = false
		$ColorRect/JoinLabel.visible = false
		$ColorRect/FailedLabel.visible = false
		$ColorRect/ClientsWaitingLabel.visible = true
	else:
		$ColorRect/FailedLabel.text = "Could Not Connect To IP:\n" + new_text
		$ColorRect/FailedLabel.visible = true
	
