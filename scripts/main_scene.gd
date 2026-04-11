extends Node2D

var stage_instance : Node2D

func _on_button_pressed():
	load_stage("stage_trad2d")

func unload_stage():
	if (is_instance_valid(stage_instance)):
		stage_instance.queue_free()
	stage_instance = null

func load_stage(stage_name : String):
	unload_stage()
	var stage_path := "res://scenes/%s.tscn" % stage_name
	var stage_resource := load(stage_path)
	if( stage_resource ):
		stage_instance = stage_resource.instantiate()
		self.add_child((stage_instance))


func _on_button_2_pressed():
	load_stage("stage_topdown")
