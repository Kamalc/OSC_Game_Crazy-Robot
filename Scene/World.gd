extends Spatial

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	var new_player = preload('res://player/player.tscn').instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	$Players.add_child(new_player)
	var info = Network.self_data
	new_player.init(info.name, info.position, false)
	print(IP.get_local_addresses())

func _on_player_disconnected(id):
	get_node('Players/'+str(id)).queue_free()

func _on_server_disconnected():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene('res://interface/Menu.tscn')