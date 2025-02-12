class_name JobCar
extends Interactable

var is_repair_started : bool = false
var is_repair_finished : bool = false
var is_repaired_by_player : bool = false

@export var car_lift : CarLift

signal start_repair(job_car : JobCar, is_started_by_player : bool)
signal repair_completed(cash_reward : int, rep_reward : int)
signal ask_for_repair(job_car : JobCar)

func interact():
	# If the car is waiting for a repair, check when clicking on it if there are any available
	# car lifts to take the car.
	if is_repair_started == false:
		ask_for_repair.emit(self)
	# If the car is being repaired, check before repair is completed before confirming repair
	else:
		if is_repair_finished == true:
			confirm_repair_completion()

func process_repair_response(response : bool):
	# If there is an available car lift to take the car, start the repair
	if response == true:
		if is_repair_started == false:
			is_repaired_by_player = true
			begin_repair()
	# Otherwise, do nothing.

func begin_repair():
	is_repair_started = true
	start_repair.emit(self, is_repaired_by_player)

func finish_repair():
	if is_repair_started == true:
		is_repair_finished = true

func confirm_repair_completion():
	if is_repair_started == true && is_repair_finished == true:
		var rewards = car_lift.end()
		if rewards is Array:
			repair_completed.emit(rewards[0], rewards[1], is_repaired_by_player)

func disable_collision():
	$CollisionShape3D.disabled = true

func enable_collision():
	$CollisionShape3D.disabled = false

func disable_area_3d():
	$Area3D/CollisionShape3D.disabled = true

func enable_area_3d():
	$Area3D/CollisionShape3D.disabled = false
