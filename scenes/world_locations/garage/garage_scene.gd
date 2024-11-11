extends Node3D

@onready var camera : Camera3D = $CameraPivot/Camera3D
@onready var car_lifts : Node3D = $CarLifts
@onready var job_car_spots : Node3D = $JobCarSpots
@onready var pending_cars : Array = []

signal repair_completed(cash_reward : int, rep_reward : int)

func _ready():
	on_ready_connect_car_lifts_signals()
	pass

#TODO: Call this function when adding a car bay, or a separate function that connects only the specific car bay
func on_ready_connect_car_lifts_signals():
	for car_lift in car_lifts.get_children():
		connect_car_lift_signals(car_lift)

func connect_car_lift_signals(car_lift : StaticBody3D):
	car_lift.connect("repair_complete", repair_completed_at_lift)

func repair_completed_at_lift(car_lift):
	# TODO: Change this to the following code:
	#func complete_job(car_bay : StaticBody3D):
		# If the car was repaired by a mechanic
		#if car_bay.get_is_started_by_player() == false:
			#PlayerStats.free_mechanic()
			#$Timers/MechanicJobCooldownTimer.start()
		#var cash_reward = car_bay.end()
		#var rep_reward = 100
		#PlayerStats.add_cash(cash_reward)
		#PlayerStats.add_rep(rep_reward)
		#ui.update_labels()
	repair_completed.emit(car_lift)

func get_job_car_spots() -> Node3D:
	return job_car_spots

func get_camera() -> Camera3D:
	return camera

func add_pending_car(pending_car : StaticBody3D):
	if pending_cars.size() < job_car_spots.get_child_count():
		pending_cars.append(pending_car)
		pending_car.connect("start_repair", start_car_repair)
		pending_car.connect("repair_completed", finish_car_repair)
		
		#print(pending_cars)
		#print_debug(str(pending_cars.size()) + "/" + str(job_car_spots.get_child_count()))
		#pending_cars.erase(pending_car)

func start_car_repair(car : StaticBody3D):
	# Find first available car lift
	for lift : Node3D in car_lifts.get_children():
		if lift.can_take_car():
			car.global_position = lift.global_position
			car.global_rotation = lift.global_rotation
			car.reparent(lift, true)
			lift.start(car, true)
			pending_cars.erase(car)
			break

func finish_car_repair(cash_reward : int, rep_reward : int):
	repair_completed.emit(cash_reward, rep_reward)

#@onready var car_bays : Node3D = $CarBays
#@onready var pending_cars : Node3D = $JobCarSpots
#
#signal repair_completed(car_bay)
#signal usable_car_clicked(car : StaticBody3D)
#signal change_ui_message(new_message : String, display_time : float)
#signal update_ui_labels
#signal update_ui_list
#
## Called when the node enters the scene tree for the first time.
#func _ready():
	#camera.connect("complete_repair_at_bay", repair_completed_at_bay)
	#camera.connect("change_ui_message", new_ui_message)
	#camera.connect("added_car_bay", connect_car_bay_signals)
	#camera.connect("usable_car_clicked", interact_with_car)
	#camera.connect("update_ui_labels", ui_update_labels)
	#camera.connect("update_ui_list", ui_update_list)
	#set_active_floor_tile(-1)
	#on_ready_connect_car_bays_signals()
#
#func connect_car_bay_signals(car_bay : StaticBody3D):
	#car_bay.connect("repair_complete", repair_completed_at_bay)
#
##TODO: Call this function when adding a car bay, or a separate function that connects only the specific car bay
#func on_ready_connect_car_bays_signals():
	#for car_bay in car_bays.get_children():
		#connect_car_bay_signals(car_bay)
#
#func repair_completed_at_bay(car_bay):
	#repair_completed.emit(car_bay)



#func debug_spawn_car_lift():
	#camera.add_car_lift()
#
#func set_active_floor_tile(tile_index : int):
	#camera.set_selected_tile(tile_index)
#
#func expand_garage(state : bool):
	#camera.expand_garage(state)
#
#func debug_spawn_decor_car(car : String, car_id : int):
	#camera.add_decor_car(car, car_id)
#
#func debug_spawn_decor_furniture(furniture_item : String):
	#camera.add_decor_furniture(furniture_item)
#
#func debug_move_placed_objects(is_enabled : bool):
	#camera.move_placed_objects(is_enabled)
#
#func new_ui_message(new_message : String, display_time : float):
	#change_ui_message.emit(new_message, display_time)
#
#func mechanic_repair_car(pending_car : StaticBody3D):
	#start_car_repair(pending_car, false)
#
#func start_car_repair(pending_car : StaticBody3D, is_started_by_player : bool):
	#if pending_car.is_in_group("Repair Car"):
		#for car_bay in car_bays.get_children():
			#if car_bay.is_in_group("Moving") == false:
				#if car_bay.can_take_car():
					#var available_bay = car_bay
					#pending_car.global_position = available_bay.global_position
					#pending_car.global_rotation = available_bay.global_rotation
					#pending_car.reparent(available_bay, true)
					#available_bay.start(pending_car, is_started_by_player)
					#return true
			#else:
				#continue
	#return false
#
#func get_pending_cars() -> Node3D:
	#return pending_cars
#
#func interact_with_car(car : StaticBody3D):
	#usable_car_clicked.emit(car)
#
#func ui_update_labels():
	#update_ui_labels.emit()
#
#func ui_update_list(identifier : String):
	#update_ui_list.emit(identifier)
