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
		repair_completed.emit(rewards[0], rewards[1], is_repaired_by_player)

func disable_collision():
	$CollisionShape3D.disabled = true

func enable_collision():
	$CollisionShape3D.disabled = false

func disable_area_3d():
	$Area3D/CollisionShape3D.disabled = true

func enable_area_3d():
	$Area3D/CollisionShape3D.disabled = false
