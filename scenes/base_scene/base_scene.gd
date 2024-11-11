extends Node

@onready var garage_scene : Node3D = $GarageScene
@onready var ui = $UI
@onready var job_car_spawner : Node = $JobCarSpawner

# Called when the node enters the scene tree for the first time.
func _ready():
	garage_scene.connect("repair_completed", complete_job)
	#garage_scene.connect("change_ui_message", ui.set_message_label_text)
	#garage_scene.connect("usable_car_clicked", show_car_interaction_menu)
	#garage_scene.connect("update_ui_labels", ui.update_labels)
	#garage_scene.connect("update_ui_list", ui.update_list)
	#ui.connect("debug_spawn_job_car", job_car_spawner.spawn_job)
	#ui.connect("floor_tile_selected", garage_scene.set_active_floor_tile)
	#ui.connect("is_expanding_garage", garage_scene.expand_garage)
	#ui.connect("debug_spawn_decor_car", garage_scene.debug_spawn_decor_car)
	#ui.connect("debug_spawn_furniture", garage_scene.debug_spawn_decor_furniture)
	#ui.connect("debug_move_objects", garage_scene.debug_move_placed_objects)
	#ui.connect("mechanic_hired", check_for_job_cars)
	#ui.connect("switch_location", switch_location) #(location_key : String)
	#ui.connect("travel_to_location_with", travel_to_location_with_car)
	ui.connect("hire_mechanic", hire_mechanic)
	job_car_spawner.connect("job_car_spawned", check_for_mechanics)
	job_car_spawner.set_car_spots(garage_scene.get_job_car_spots())
	ui.update_labels()
#
func complete_job(cash_reward : int, rep_reward : int):
	PlayerStats.add_cash(cash_reward)
	PlayerStats.add_rep(rep_reward)
	ui.update_labels()

### When a job car is spawned, check to see if there are available mechanics to take this job
func check_for_mechanics(pending_car : StaticBody3D):
	garage_scene.add_pending_car(pending_car)
	#print_debug(pending_car.name)
	#if PlayerStats.get_available_mechanics() > 0:
		#if garage_scene.start_car_repair(pending_car, false) == true:
			#PlayerStats.assign_mechanic()
	#else:
		#pass
	#ui.update_labels()

func hire_mechanic():
	PlayerStats.hire_mechanic()
	ui.update_labels()
	print_debug("Hire mechanic")
	
	pass

### When a mechanic completes a job, check to see if there are cars waiting for repairs
#func check_for_job_cars():
	#var pending_cars : Node3D = garage_scene.get_pending_cars()
	#for car in pending_cars.get_children():
		#if car.get_children().is_empty() == false:
			#check_for_mechanics(car.get_child(0))
			#ui.update_labels()
			#return true
	#return false
#
### When a mechanic finishesh a job, a cooldown timer is started before they can take another one
### This cooldown is necessary because without it a major bug that breaks the number of available
### mechanics and prevents a car from being repaired if all available mechanics are utilized
#func _on_mechanic_job_cooldown_timer_timeout():
	#check_for_job_cars()
#
#func show_car_interaction_menu(car : StaticBody3D):
	#if ui.has_method("show_car_interaction_menu"):
		#ui.show_car_interaction_menu(car)
#
#### Travel to a location that doesn't require the player to bring a car with them
#### For example if the player travels to the garage, or to a dealership (not implemented)
##func switch_location(location_key):
	##var location_data = LocationsData.get_locations()
	##var new_scene
	##if location_key != "garage":
		##garage_scene.hide()
		##ui.hide_garage_scene_buttons()
		##new_scene = load(location_data.get(location_key)["path"]).instantiate()
		##$Scene.add_child(new_scene)
		##new_scene.get_camera().current = true
	##else:
		### If trying to switch from the garage, to the garage
		##if $Scene.get_child_count() > 0:
			##$Scene.get_child(0).queue_free()
			##garage_scene.show()
			##ui.show_garage_scene_buttons()
			##garage_scene.get_camera().current = true
#func switch_location(location_key : String):
	#var location_data = LocationsData.get_locations()
	#var new_scene
	#if location_key != "garage":
		#garage_scene.hide()
		#ui.hide()
		#ui.show_all_buttons()
		#ui.hide_garage_scene_buttons()
		#ui.toggle_off_all_buttons()
		#ui.clear_ui_list()
		#new_scene = load(location_data.get(location_key)["path"]).instantiate()
		#$Scene.add_child(new_scene)
		#new_scene.connect("leave_location", return_to_garage)
		#ui.hide_car_interaction_menu()
		#ui = new_scene.get_ui()
		#ui.update_labels()
		#new_scene.get_camera().current = true
	#else:
		#if $Scene.get_child(0) != null:
			#$Scene.get_child(0).queue_free()
		#garage_scene.show()
		#ui = $UI
		#ui.show()
		#ui.update_labels()
		#ui.show_garage_scene_buttons()
		#garage_scene.get_camera().current = true
#
#### Travel to a location that requires the player to bring a car with them
#### For example, race meets (for now)
#func travel_to_location_with_car(location_key : String, car : Car):
	#var location_data = LocationsData.get_locations()
	#var new_scene
	#if location_key != "garage":
		#garage_scene.hide()
		#ui.hide()
		#ui.show_all_buttons()
		#ui.hide_garage_scene_buttons()
		#ui.toggle_off_all_buttons()
		#ui.clear_ui_list()
		#new_scene = load(location_data.get(location_key)["path"]).instantiate()
		#$Scene.add_child(new_scene)
		#var duplicate_car : Car = car.duplicate()
		#duplicate_car.set_internal_name(car.get_internal_name())
		#new_scene.set_player_car(car.duplicate())
		#new_scene.connect("leave_location", return_to_garage)
		#ui.hide_car_interaction_menu()
		#ui = new_scene.get_ui()
		#ui.update_labels()
		#new_scene.get_camera().current = true
	#else:
		#$Scene.get_child(0).queue_free()
		#garage_scene.show()
		#ui = $UI
		#ui.show()
		#ui.update_labels()
		#ui.show_garage_scene_buttons()
		#garage_scene.get_camera().current = true
#
#func return_to_garage():
	#travel_to_location_with_car("garage", null)
#
#func test_signals():
	#print_debug("Reached base scene")
