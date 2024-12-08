#main.gd
extends Node

@export var gem_scene: PackedScene
var player: Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE_NAME = "save.json"
const SECURITY_KEY = "jwyw9r2h"

var player_data = PlayerData.new()

var playerIt = null

var activePlayers = 0

var gem_array = []
var spawn_array = []

var isServer : bool = false
var won : bool = false

func _ready():
	verify_save_directory(SAVE_DIR)
	$UserInterface/PauseMenu.visible = false
	#gem_array.resize(5)
	spawn_array.resize(50)
	var count = 0
	#for child in get_node("Gems").get_children():
		#if child.is_in_group("Item"):
		#	child.id = count
		#	gem_array[count] = child
		#	count += 1
	#count = 0
	for child in get_node("SpawnPoints").get_children():
		spawn_array[count] = child
		count += 1


func verify_save_directory(path : String):
	DirAccess.make_dir_absolute(path)

func load_game(path : String):
	if FileAccess.file_exists(path):
		var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SECURITY_KEY)
		if file == null:
			print(FileAccess.get_open_error())
			return
			
		var content = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(content)
		if data == null:
			printerr("Cannot parse %s as a json_sting: (%s)" % [path, content])
			return
			
		player_data = PlayerData.new()
		player_data.global_position = Vector3(data.player_data.global_position.x, data.player_data.global_position.y, data.player_data.global_position.z)
		player_data.global_rotation = Vector3(data.player_data.global_rotation.x, data.player_data.global_rotation.y, data.player_data.global_rotation.z)
		player_data.gems = data.player_data.gems
		player.position = player_data.global_position
		player.rotation = player_data.global_rotation
		player_data.gem_array[0] = data.player_data.gem_array.a
		player_data.gem_array[1] = data.player_data.gem_array.b
		player_data.gem_array[2] = data.player_data.gem_array.c
		player_data.gem_array[3] = data.player_data.gem_array.d
		player_data.gem_array[4] = data.player_data.gem_array.e
		$UserInterface/ScoreLabel.gems = player_data.gems
		$UserInterface/ScoreLabel.update_score()
		
		var count = 0
		for id in player_data.gem_array:
			if id > 0:
				gem_array[count].visible = false
				gem_array[count].get_node("CollisionShape3D").call_deferred("set_disabled", true)
			else:
				gem_array[count].visible = true
				gem_array[count].get_node("CollisionShape3D").call_deferred("set_disabled", false)
			count += 1
		
	else:
		printerr("Cannot open non-existent file at %s!" % [path])


func save_game(path : String):
	player_data.global_position.x = player.position.x
	player_data.global_position.y = player.position.y
	player_data.global_position.z = player.position.z
	
	player_data.global_rotation.x = player.rotation.x
	player_data.global_rotation.y = player.rotation.y
	player_data.global_rotation.z = player.rotation.z
	
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, SECURITY_KEY)
	if file == null:
		print(FileAccess.get_open_error())
		return
		
	var data = {
		"player_data": {
			"global_position": {
				"x": player_data.global_position.x,
				"y": player_data.global_position.y,
				"z": player_data.global_position.z
			},
			"global_rotation": {
				"x": player_data.global_rotation.x,
				"y": player_data.global_rotation.y,
				"z": player_data.global_rotation.z
			},
			"gem_array": {
				"a": player_data.gem_array[0],
				"b": player_data.gem_array[1],
				"c": player_data.gem_array[2],
				"d": player_data.gem_array[3],
				"e": player_data.gem_array[4]
			},
			"gems": player_data.gems
		}
	}
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
func _unhandled_input(event):
	if event.is_action_pressed("pause") && player:
		$UserInterface/PauseMenu.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.mouseMotion = false;


func _on_gem_collected(id):
	gem_array[id].get_node("CollisionShape3D").call_deferred("set_disabled", true)
	gem_array[id].visible = false
	player_data.gem_array[id] = 1
	$UserInterface/ScoreLabel._on_collected()
	player_data.gems = $UserInterface/ScoreLabel.gems


func _on_resume_pressed():
	$UserInterface/PauseMenu.visible = false
	player.mouseMotion = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_save_pressed():
	save_game(SAVE_DIR + SAVE_FILE_NAME)


func _on_load_pressed():
	load_game(SAVE_DIR + SAVE_FILE_NAME)



func tagYoureIt(itPos : Vector3):
	var newIt: Node = player
	var minDist: float = 1000.0
	for child in $Players.get_children():
		if child.is_in_group("Player"):
			var othPos: Vector3 = child.global_transform.origin
			var dist = distToOthers(othPos, itPos)
			if dist < minDist:
				newIt = child
				minDist = dist
	newIt.youreIt(activePlayers)
	playerIt = newIt
	$CanvasLayer/Lobby.remoteYoureIt(newIt.id)

func distToOthers(it : Vector3, oth : Vector3):
	var xIt: float = it.x
	var yIt: float = it.y
	var zIt: float = it.z
	
	var xOth: float = oth.x
	var yOth: float = oth.y
	var zOth: float = oth.z
	
	var dist: float = sqrt((xIt - xOth) ** 2 + (yIt - yOth) ** 2 + (zIt - zOth) ** 2)
	return dist

func _on_tag_timer_timeout():
	if !won:
		if isServer:
			playerIt.explode()
			$CanvasLayer/Lobby.explodeClient(playerIt.id)
			activePlayers -= 1
			tagYoureIt(playerIt.global_transform.origin)

func _on_start_timer_timeout():
	if isServer:
		var playerCount = 0
		for child in $Players.get_children():
			playerCount += 1
		var randomInt = randi_range(0, playerCount - 1)	
		var it = $Players.get_child(randomInt)
		it.youreIt(activePlayers)
		playerIt = it

	$TagTimer.start()


func _on_lobby_add_player(play):
	$Players.add_child(play)


func _on_lobby_start_game():
	$StartTimer.start()
	player = $Players/Player
	print('Started Game!')
	var count = 0
	for user in $Players.get_children():
		user.position = spawn_array[count].position
		user.rotation = spawn_array[count].rotation
		count += 1
		user.connect("imIt", Callable(self, "remoteIt"))
		user.connect("win", Callable(self, "playerWin"))
	activePlayers = count
	player.mouseMotion = true
	print("Player Count: " + str(count))


func remoteIt(id):
	for child in $Players.get_children():
		if child.id == id:
			playerIt = child
	$CanvasLayer/Lobby.remoteYoureIt(id)

func _on_lobby_update_remote_data(id, pos, rot):
	if (id != player.id):
		for child in $Players.get_children():
			if child.id == id:
				child.position = pos
				child.rotation = rot

func _on_lobby_is_server():
	isServer = true

func _on_lobby_tag(id):
	for child in $Players.get_children():
		if child.id == id:
			child.youreIt(activePlayers)
		else:
			child.notIt()
			child.remove_from_group("It")
			child.add_to_group("Player")

func _on_lobby_explode(id):
	if !won:
		for child in $Players.get_children():
			if child.id == id:
				child.explode()
				activePlayers -= 1

func playerWin(id):
	won = true
	$TagTimer.stop()
	$CanvasLayer/Lobby.setWinner(id)
	if id != player.id:
		player.winScreen(id)

func _on_lobby_won(id):
	if id > -1:
		won = true
		$TagTimer.stop()
		if id != player.id:
			player.winScreen(id)
		


func _on_lobby_windmill(rot):
	if !isServer:
		$Windmill.rotation = Vector3(0, 0, rot)
	else:
		$CanvasLayer/Lobby.setWindmillRotation($Windmill.rotation.z)
