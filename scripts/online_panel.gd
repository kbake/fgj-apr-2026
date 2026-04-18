extends Node2D

@onready var connection_panel = $CanvasLayer/ConnectionPanel
@onready var host_field = $CanvasLayer/ConnectionPanel/GridContainer/HostField
@onready var port_field = $CanvasLayer/ConnectionPanel/GridContainer/PortField
@onready var message_label = $CanvasLayer/MessageLabel
@onready var sync_lost_label = $CanvasLayer/SyncLostLabel

const LOG_FILE_DIRECTORY = 'user://detailed_logs'

var logging_enabled := true

func _ready() -> void:
	multiplayer.connect("peer_connected", _on_peer_connected)
	multiplayer.connect("peer_disconnected", _on_peer_disconnected)
	multiplayer.connect("server_disconnected", _on_server_disconnected)
	SyncManager.connect("sync_started", _on_SyncManager_sync_started)
	SyncManager.connect("sync_stopped", _on_SyncManager_sync_stopped)
	SyncManager.connect("sync_lost", _on_SyncManager_sync_lost)
	SyncManager.connect("sync_regained", _on_SyncManager_sync_regained)
	SyncManager.connect("sync_error", _on_SyncManager_sync_error)

func _on_server_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_field.text), 1)
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Listening..."

func _on_client_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Connecting..."

func _on_peer_connected(peer_id: int):
	message_label.text = "Connected!"
	SyncManager.add_peer(peer_id)
	
	var is_server = multiplayer.is_server()
		
	var players = get_tree().get_nodes_in_group("network_sync")
	for p in players:
		if p.name == 'ServerPlayer':
			p.set_multiplayer_authority(1)
		elif is_server:
			p.set_multiplayer_authority(peer_id)
		else:
			p.set_multiplayer_authority(p.multiplayer.get_unique_id())

	if is_server:
		message_label.text = "Starting..."
		# Give some time for SyncManager to ping
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()

func _on_peer_disconnected(peer_id: int):
	message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)

func _on_server_disconnected() -> void:
	_on_peer_disconnected(1)


func _on_reset_button_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()

func _on_SyncManager_sync_started() -> void:
	message_label.text = "Started!"

	if logging_enabled:
		var _dir = DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)

		var log_file_name = "%s-peer-%d.log" % [
			Time.get_datetime_string_from_system(true),
			get_tree().get_multiplayer().get_unique_id()
		]
		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name)

func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false
	
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()
