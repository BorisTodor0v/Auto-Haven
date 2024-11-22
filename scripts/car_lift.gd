extends PlaceableObject

var current_car : StaticBody3D
var is_started_by_player : bool
@onready var mesh: MeshInstance3D = self.get_child(0)
@onready var default_material : Material = mesh.get_active_material(0)
@onready var label : Label3D = $Label3D
@onready var timer : Timer = $Timer

func _process(_delta):
	if timer.is_stopped():
		label.hide()
	else:
		label.show()
		label.text = str("%.1f" % timer.time_left)

func can_take_car():
	return current_car == null

func has_car():
	return current_car != null

func disable_car_collision():
	current_car.disable_collision()
	current_car.disable_area_3d()

func enable_car_collision():
	current_car.enable_collision()
	current_car.disable_area_3d()

func start(car : StaticBody3D, _started_by_player : bool):
	is_started_by_player = _started_by_player
	current_car = car
	current_car.add_to_group("Repairing")
	timer.one_shot = true
	# Debug timer, one second to repair
	timer.start(1)
	# Normal timer, randomized time to repair
	#timer.start(randi_range(5, 20))

func end():
	if timer.is_stopped():
		current_car.queue_free()
		## Calculate rewards
		var cash_reward : int = randi_range(500,1000)
		var rep_reward : int = 100
		return [cash_reward, rep_reward]
	else:
		return -1

func get_is_started_by_player():
	return is_started_by_player

func _on_timer_timeout():
	current_car.finish_repair()
	if is_started_by_player == false:
		current_car.confirm_repair_completion()

func job_is_complete() -> bool:
	if timer.is_stopped():
		return true
	else:
		return false
