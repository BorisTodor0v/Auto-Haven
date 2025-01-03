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
			var size = CarsData.get_all_cars().size()
			var random_car_key = CarsData.get_all_cars().keys()[randi() % size]
			var random_car = CarsData.get_car(random_car_key)
			var instance = load(random_car["scene_path"]).instantiate()
			var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
			var mesh : MeshInstance3D = null
			for child in instance.get_children():
				if child is MeshInstance3D:
					mesh = child
			if mesh != null && material != null:
				material.albedo_color = Color(randf(), randf(), randf(), 1)
				mesh.set_surface_override_material(0, material)
			var wheel_model = load("res://cars/wheels/"+random_car["default_wheels"]+"/"+random_car["default_wheels"]+".glb").instantiate()
			for child in instance.get_children():
				if child.name == "WheelPositions":
					for wheel_position in child.get_children():
						wheel_position.add_child(wheel_model.duplicate())
					break
			instance.add_to_group("Repair Car")
			instance.set_script(load("res://scripts/interactables/job_car.gd"))
			# Disables collision area around car to allow moving car lift while car is placed on it
			instance.disable_area_3d()
			spot.add_child(instance)
			job_car_spawned.emit(instance)
			break
