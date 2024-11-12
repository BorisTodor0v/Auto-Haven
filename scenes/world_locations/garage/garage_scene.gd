extends Node3D

@onready var camera : Camera3D = $CameraPivot/Camera3D
@onready var car_lifts : Node3D = $CarLifts
@onready var job_car_spots : Node3D = $JobCarSpots
@onready var pending_cars : Array = []

signal repair_completed(cash_reward : int, rep_reward : int)

func _ready():
	pass

func get_job_car_spots() -> Node3D:
	return job_car_spots

func get_camera() -> Camera3D:
	return camera

func add_pending_car(pending_car : StaticBody3D):
	if pending_cars.size() < job_car_spots.get_child_count():
		pending_cars.append(pending_car)
		pending_car.connect("start_repair", start_car_repair)
		pending_car.connect("repair_completed", finish_car_repair)

func start_car_repair(car : StaticBody3D, is_started_by_player : bool):
	# Find first available car lift
	for lift : Node3D in car_lifts.get_children():
		if lift.can_take_car():
			car.global_position = lift.global_position
			car.global_rotation = lift.global_rotation
			car.reparent(lift, true)
			lift.start(car, is_started_by_player)
			pending_cars.erase(car)
			break

func finish_car_repair(cash_reward : int, rep_reward : int, is_repaired_by_player : bool):
	repair_completed.emit(cash_reward, rep_reward, is_repaired_by_player)

func get_pending_cars() -> Array:
	return pending_cars
