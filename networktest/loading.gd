extends Control

@onready var client_waiting_label = $ClientWaitingLabel

var server = null
var client = null
var summator = null

func _ready():
	var args = OS.get_cmdline_args()
	if "server" in args:
		start_server()
	elif "client" in args:
		start_client()
	summator = Summator.new()
	summator.add(3)
	summator.add(4)
	print(summator.get_total())

func start_server():
	server = Server.new()
	server.start(12345)
	add_child(server)
	set_process(true)

func start_client():
	client = Client.new()
	client.connect_to_server("127.0.0.1", 12345)
	add_child(client)
	set_process(true)
	client.setLabel(client_waiting_label)

func _process(delta):
	if server:
		client_waiting_label.text = "Clients connected: %d" % server.get_client_count()
