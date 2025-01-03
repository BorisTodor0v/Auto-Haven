extends Interactable

var is_repair_started : bool = false
var is_repair_finished : bool = false
var is_repaired_by_player : bool = false

signal start_repair(job_car : StaticBody3D, is_started_by_player : bool)
signal repair_completed(cash_reward : int, rep_reward : int)

func interact():
	if is_repair_started == false:
		is_repaired_by_player = true
		begin_repair()
	elif is_repair_started == true && is_repair_finished == true:
		confirm_repair_completion()

func begin_repair():
	is_repair_started = true
	start_repair.emit(self, is_repaired_by_player)

func finish_repair():
	if is_repair_started == true:
		is_repair_finished = true

func confirm_repair_completion():
	if is_repair_started == true && is_repair_finished == true:
		var rewards = get_parent().end()
		# TODO: Fix problem - Somehow gave -1 for rewards when repair is considered finished, but timer wasn't considered stopped
		# Probably a frame difference between the timer stopping and the repair job being considered finished
		# Another problem is when hiring a bunch of mechanics at once, if a car is available to repair and is ACTIVELY BEING REPAIRED
		# they will take that car from another mechanic and start working on it, which does not run the logic for freeing the by the other
		# mechanic, which causes him to be lost permanently.
		# Possibly the initial problem described above is caused by the second problem.
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
