extends Control

var _player_name = ""

func _ready():
	$VBoxContainer/selfIPHBContainer/TextField.text = IP.get_local_addresses()[1]

func _on_Name_TextField_text_changed(new_text):
	_player_name = new_text

func _on_CreateButton_pressed():
	if _player_name == "":
		return
	Network.create_server(_player_name)
	_load_game()

func _on_JoinButton_pressed():
	var server_ip = $VBoxContainer/ServerHBoxContainer/TextField.text
	if _player_name == "" or server_ip == "" or not server_ip.is_valid_ip_address():
		return
	Network.connect_to_server(_player_name,server_ip)
	_load_game()

func _load_game():
	get_tree().change_scene('res://Scene/World.tscn')

