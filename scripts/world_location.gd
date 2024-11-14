class_name WorldLocation
extends Node3D

@onready var ui : Control
@onready var camera : Camera3D

signal leave_location

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_camera(_camera : Camera3D):
	camera = _camera

func get_camera():
	return camera

func return_to_garage():
	leave_location.emit()

func get_ui():
	return ui

func set_ui(_ui : UI):
	ui = _ui

func get_player_car():
	pass
