extends Node

const IP_ADDRESS := "127.0.0.1"
const PORT := 7777
const MAX_CLIENTS := 8

func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args():
		create_server()
	else:
		create_client()

func create_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer

func create_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func go_offline():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
