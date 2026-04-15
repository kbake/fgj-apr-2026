extends Node2D

# has whatever a player needs to keep track of
@export var Player_Health : int = 100
@export var Player_Speed : int = 50
@export var is_Blocking : bool = false
@export var is_Shoving : bool = false
@export var is_Grabbing : bool = false

func _get_local_input() -> Dictionary:
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	
	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = input_vector
	
	return input

func _network_process(input: Dictionary) -> void:
	position += input.get("input_vector", Vector2.ZERO) * 8

func _save_state() -> Dictionary:
	return {
		position = position,
	}

func _load_state(state: Dictionary) -> void:
	position = state["position"]
