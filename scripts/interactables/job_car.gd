extends Interactable

var is_repair_started : bool = false
var is_repair_finished : bool = false

signal start_repair(job_car)
signal repair_completed(cash_reward, rep_reward)

func interact():
	if is_repair_started == false:
		begin_repair()
	elif is_repair_started == true && is_repair_finished == true:
		confirm_repair_completion()

func begin_repair():
	is_repair_started = true
	start_repair.emit(self)

func finish_repair():
	if is_repair_started == true:
		is_repair_finished = true

func confirm_repair_completion():
	if is_repair_started == true && is_repair_finished == true:
		var rewards = get_parent().end()
		repair_completed.emit(rewards[0], rewards[1])
