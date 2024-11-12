extends Node

var car_path : String = "res://cars/models"
var directory : PackedStringArray = DirAccess.get_directories_at(car_path)

@onready var car_spots : Node3D

@onready var timer : Timer = $Timer

signal job_car_spawned(car : StaticBody3D)

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = randi_range(2, 10)
	timer.timeout.connect(_on_timer_timeout)

func set_car_spots(_car_spots : Node3D):
	car_spots = _car_spots

func _on_timer_timeout():
	spawn_job()

func spawn_job():
	timer.wait_time = randi_range(2, 8)
	for spot : Node3D in car_spots.get_children():
		if spot.get_child_count() == 0:
			var car : String = directory[randi_range(0, directory.size()-1)]
			var scene = load(car_path+"/"+car+"/"+car+".tscn")
			var instance = scene.instantiate()
			var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
			var mesh : MeshInstance3D = null
			for child in instance.get_children():
				if child is MeshInstance3D:
					mesh = child
			if mesh != null && material != null:
				material.albedo_color = Color(randf(), randf(), randf(), 1)
				mesh.set_surface_override_material(0, material)
			instance.add_to_group("Repair Car")
			instance.set_script(load("res://scripts/interactables/job_car.gd"))
			spot.add_child(instance)
			job_car_spawned.emit(instance)
			break
