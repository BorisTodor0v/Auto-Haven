extends Node

@onready var garage_scene : Node3D = $GarageScene
@onready var ui = $UI
@onready var job_car_spawner : Node = $JobCarSpawner
@onready var scene_holder : Node = $Scene

var is_expanding_garage : bool = false
var is_redecorating : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	garage_scene.connect("repair_completed", complete_job)
	garage_scene.connect("pressed_on_tile", pressed_on_tile)
	garage_scene.connect("end_placing_item", end_placing_item)
	garage_scene.connect("pressed_on_object", handle_object_clicked)
	ui.connect("hire_mechanic", hire_mechanic)
	ui.connect("expand_garage", toggle_garage_expansion)
	ui.connect("open_menu", open_menu)
	ui.connect("travel_to_location", travel_to_location_no_car)
	ui.connect("on_garage_submenu_item_pressed", begin_placing_item)
	ui.connect("garage_submenu_closed", cancel_placing_item)
	ui.connect("edit_mode_enabled", set_edit_mode)
	job_car_spawner.connect("job_car_spawned", check_for_mechanics)
	job_car_spawner.set_car_spots(garage_scene.get_job_car_spots())
	ui.update_labels()
#
func complete_job(cash_reward : int, rep_reward : int, is_repaired_by_player : bool):
	if is_repaired_by_player == false:
		PlayerStats.free_mechanic()
		$Timers/MechanicJobCooldownTimer.start()
	PlayerStats.add_cash(cash_reward)
	PlayerStats.add_rep(rep_reward)
	ui.update_labels()

### When a job car is spawned, check to see if there are available mechanics to take this job
func check_for_mechanics(pending_car : StaticBody3D):
	garage_scene.add_pending_car(pending_car)
	if PlayerStats.get_available_mechanics() > 0:
		pending_car.begin_repair()
		PlayerStats.assign_mechanic()
	ui.update_labels()

func hire_mechanic():
	if PlayerStats.get_cash() >= PlayerStats.get_mechanic_cost():
		PlayerStats.remove_cash(PlayerStats.get_mechanic_cost())
		PlayerStats.hire_mechanic()
		check_for_job_cars()
		ui.update_labels()
	else:
		ui.show_message("Not enough money to hire a mechanic", 5.0)

## When a mechanic finishes a job, a cooldown timer is started before they can take another one
## This cooldown is necessary because without it a major bug that breaks the number of available
## mechanics and prevents a car from being repaired if all available mechanics are utilized
func _on_mechanic_job_cooldown_timer_timeout():
	check_for_job_cars()

## When a mechanic completes a job, and when hiring one, 
## check to see if there are cars waiting for repairs
func check_for_job_cars():
	var pending_cars : Array = garage_scene.get_pending_cars()
	for car in pending_cars:
		if car == null:
			return false
		check_for_mechanics(car)
		ui.update_labels()
		return true
	return false

func toggle_garage_expansion():
	is_expanding_garage = !is_expanding_garage
	if is_expanding_garage == true:
		garage_scene.show_unlockable_tiles()
	else:
		garage_scene.hide_unlockable_tiles()

func pressed_on_tile(tile : Tile):
	if is_expanding_garage == true && tile.get_can_unlock() == true:
		if PlayerStats.get_cash() >= PlayerStats.get_garage_expansion_cost():
			PlayerStats.remove_cash(PlayerStats.get_garage_expansion_cost())
			tile.unlock_tile()
			ui.update_labels()
		else:
			ui.show_message("Not enough money to expand garage", 5.0)

func open_menu(menu_name : String):
	# Checks if any garage managament options are enabled before switching menu
	if is_expanding_garage == true:
		toggle_garage_expansion()
	ui.change_active_menu(menu_name)

func travel_to_location_no_car(location_name : String):
	var location = LocationsData.get_location(location_name)
	if location_name != "garage":
		garage_scene.hide()
		var new_scene = load(location["path"]).instantiate()
		scene_holder.add_child(new_scene)
		if new_scene is WorldLocation:
			new_scene.get_camera().current = true
			## Connect specific signals from specific scenes
			match location_name:
				"car_dealership":
					new_scene.connect("player_bought_car", buy_car)
				_:
					pass
		ui.hide()
		ui = new_scene.get_ui()
		new_scene.connect("leave_location", travel_to_location_no_car.bind("garage"))
	else:
		if scene_holder.get_child_count() > 0:
			scene_holder.get_child(0).queue_free()
		garage_scene.show()
		ui = $UI
		ui.show()
		ui.update_labels()
		garage_scene.get_camera().current = true

func buy_car(car_key : String, car_color : Color):
	var car_data : Dictionary = CarsData.get_car(car_key)
	if PlayerStats.get_cash() >= car_data["price"]:
		PlayerStats.remove_cash(CarsData.get_car(car_key)["price"])
		var new_car = {
			"model": car_key,
			"color": car_color,
			"wheels": car_data["default_wheels"],
			"upgrades": {
				"engine": 0,
				"weight": 0,
				"transmission": 0,
				"nitrous": 0
			},
			"is_stored": true
		}
		PlayerStats.add_car(new_car)
		ui.show_message("Congratulations on your new car. Go to your garage to place it and show it off.", 5)
	else:
		ui.show_message("Not enough money to buy this car", 5)
	ui.update_labels()

func begin_placing_item(item_type : String, item):
	print_debug(item)
	match item_type:
		"car": # Car price is not important as player already owns car / is in storage, begin placing
			ui.show_message("Left Mouse Button to place anywhere. R to rotate.\nRight Mouse Button to cancel.", 9999)
			garage_scene.begin_placing_item(item_type, item)
		"furniture":
			var furniture_item_data = FurnitureData.get_values_from_key(item)
			if PlayerStats.get_cash() >= furniture_item_data["price"]:
				ui.show_message("Left Mouse Button to place anywhere. R to rotate.\nRight Mouse Button to cancel.", 9999)
				garage_scene.begin_placing_item(item_type, item)
			else:
				ui.show_message("Not enough money to buy this furniture item", 5)
		_:
			print_debug("Placing something else")

func end_placing_item(placed_item_type : String, placed_item_id):
	if placed_item_type != "" && placed_item_id != null:
		print_debug("Update submenu list")
		
		## Specific procedures for placing specific types of items
		match placed_item_type:
			"car":
				PlayerStats.get_car(placed_item_id)["is_stored"] = false
				ui.update_submenu_list()
			"furniture":
				var furniture_item_data = FurnitureData.get_values_from_key(placed_item_id)
				if is_redecorating == false:
					PlayerStats.remove_cash(furniture_item_data["price"])
			_:
				pass
	ui.update_labels()
	ui.show_message("", 1)
	if is_redecorating:
		ui.show_message("Click over an object to change its position", 9999)

func cancel_placing_item():
	garage_scene.finish_placing_item(false, "", null, null)
	if is_redecorating:
		ui.show_message("Click over an object to change its position", 9999)

func set_edit_mode(state : bool):
	is_redecorating = state
	if is_redecorating:
		ui.show_message("Click over an object to change its position", 9999)
	else:
		ui.show_message("", 1)

func handle_object_clicked(object_node : Node3D, object_name : String, car_id : int):
	if is_redecorating:
		print_debug("Editing: " + str(object_node) + " | " + object_name + " | " + str(car_id))
		garage_scene.begin_edit_item(object_node, object_name, car_id)
		ui.show_message("Left Mouse Button to place anywhere. R to rotate.\nRight Mouse Button to cancel.", 9999)
	else:
		if car_id >= 0:
			ui.car_interaction_menu_assign_car(car_id)
			open_menu("car_interaction_menu")
			

func test_signal(a : String):
	print_debug("Signal reached base scene " + a)
