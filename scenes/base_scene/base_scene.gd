extends Node

@onready var garage_scene : Node3D = $GarageScene
@onready var ui = $UI
@onready var job_car_spawner : Node = $JobCarSpawner
@onready var scene_holder : Node = $Scene
@onready var car_interaction_menu : Node = $UI/CarInteractionMenu
var car_interaction_menu_active_car_node : Car

@export var world_environment : WorldEnvironment
@export var environment_light : DirectionalLight3D

var is_expanding_garage : bool = false
var is_redecorating : bool = false

var daytime_light_energy : float = 1.0
var daytime_light_orientation : Vector3 = Vector3(deg_to_rad(-60), deg_to_rad(-150), deg_to_rad(0))
var daytime_world_environment_energy_multiplier : float = 1
var nighttime_light_energy : float = 0.075
var nighttime_light_orientation : Vector3 = Vector3(deg_to_rad(-42.3), deg_to_rad(-171.3), deg_to_rad(174.1))
var nighttime_world_environment_energy_multiplier : float = 0.01

# Saving and loading variables
var save_data_path : String = "user://save_data/"
var save_file_name : String = "save_data.json"

# Called when the node enters the scene tree for the first time.
func _ready():
	load_game()
	garage_scene.connect("repair_completed", complete_job)
	garage_scene.connect("pressed_on_tile", pressed_on_tile)
	garage_scene.connect("end_placing_item", end_placing_item)
	garage_scene.connect("pressed_on_object", handle_object_clicked)
	garage_scene.connect("update_labels", ui.update_labels)
	ui.connect("hire_mechanic", hire_mechanic)
	ui.connect("expand_garage", toggle_garage_expansion)
	ui.connect("open_menu", open_menu)
	ui.connect("travel_to_location", travel_to_location)
	ui.connect("on_garage_submenu_item_pressed", begin_placing_item)
	ui.connect("garage_submenu_closed", cancel_placing_item)
	ui.connect("edit_mode_enabled", set_edit_mode)
	ui.connect("save_game", save_game)
	job_car_spawner.connect("job_car_spawned", check_for_mechanics)
	job_car_spawner.set_car_spots(garage_scene.get_job_car_spots())
	car_interaction_menu.connect("upgrade_car", upgrade_car)
	car_interaction_menu.connect("store_car", store_car)
	car_interaction_menu.connect("sell_car", sell_car)
	car_interaction_menu.connect("wheels_changed", update_car_wheels)
	car_interaction_menu.connect("color_changed", update_car_color)
	ui.update_labels()

func complete_job(cash_reward : int, rep_reward : int, is_repaired_by_player : bool):
	if is_repaired_by_player == false:
		PlayerStats.free_mechanic()
		$Timers/MechanicJobCooldownTimer.start()
	PlayerStats.add_cash(cash_reward)
	PlayerStats.add_rep(rep_reward)
	ui.update_labels()

## When a job car is spawned, check to see if there are available mechanics to take this job
## Additionally, check if there are any car lifts available to take the car for repair
func check_for_mechanics(pending_car : JobCar):
	garage_scene.add_pending_car(pending_car)
	# Check if there is atleast one available mechanic to take this car
	if PlayerStats.get_available_mechanics() > 0:
		# Find if there are any available car lifts to take the car
		var car_lift : CarLift = garage_scene.find_available_car_lift()
		if car_lift != null:
			pending_car.begin_repair()
			pending_car.car_lift = car_lift
			PlayerStats.assign_mechanic()
	else:
		print_debug("No mechanic able to take this car | " + pending_car.name)
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

func travel_to_location(location_name : String):
	var location = LocationsData.get_location(location_name)
	if location_name != "garage":
		if location["requires_car"] == true && int(PlayerStats.get_active_car()) == -1:
			ui.show_message("Select a car from your garage to travel to this location with", 3)
		else:
			garage_scene.hide()
			var new_scene = load(location["path"]).instantiate()
			scene_holder.add_child(new_scene)
			if new_scene is WorldLocation:
				new_scene.get_camera().current = true
				## Connect specific signals from specific scenes
				match location_name:
					"car_dealership":
						new_scene.connect("player_bought_car", buy_car)
						switch_time_of_day_to("day")
					"drag_strip":
						new_scene.set_player_car(PlayerStats.get_active_car())
						switch_time_of_day_to("day")
					"underground_race_meet":
						switch_time_of_day_to("night")
						new_scene.connect("remove_player_car", remove_player_car_from_garage)
					_:
						pass
			ui.hide()
			ui = new_scene.get_ui()
			new_scene.connect("leave_location", travel_to_location.bind("garage"))
	else:
		if scene_holder.get_child_count() > 0:
			scene_holder.get_child(0).queue_free()
		garage_scene.show()
		switch_time_of_day_to("day")
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
			"is_stored": true,
			"performance_data": {
				"top_speed_for_gear": car_data["top_speed_for_gear"].duplicate(),
				"top_speed_mps": car_data["top_speed_mps"],
				"acceleration_rate_for_gear": car_data["acceleration_rate_for_gear"].duplicate(),
				"redline": car_data["redline"],
				"max_rpm": car_data["max_rpm"],
				"gears": car_data["gears"]
			},
			"wins": 0,
			"losses": 0
		}
		PlayerStats.add_car(new_car)
		ui.show_message("Congratulations on your new car. Go to your garage to place it and show it off.", 5)
	else:
		ui.show_message("Not enough money to buy this car", 5)
	ui.update_labels()

func begin_placing_item(item_type : String, item):
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
		"walls":
			var wall_data = FurnitureData.walls[item]
			if PlayerStats.get_cash() >= wall_data["price"]:
				ui.show_message("Left Mouse Button to place anywhere. R to rotate.\nRight Mouse Button to cancel.", 9999)
				garage_scene.begin_placing_item(item_type, item)
			else:
				ui.show_message("Not enough money to buy this furniture item", 5)
		"floor_tiles":
			ui.show_message("Select a tile color and press anywhere on the garage to apply it.", 9999)
			garage_scene.begin_floor_tile_edit(item)
			print_debug("Place floor tiles")
		_:
			print_debug("Placing something else")

func end_placing_item(placed_item_type : String, placed_item_id):
	if placed_item_type != "" && placed_item_id != null:
		print_debug("Update submenu list")
		## Specific procedures for placing specific types of items
		match placed_item_type:
			"car":
				PlayerStats.get_car(str(placed_item_id))["is_stored"] = false
				ui.update_submenu_list()
			"furniture":
				var furniture_item_data = FurnitureData.get_values_from_key(placed_item_id)
				if is_redecorating == false:
					PlayerStats.remove_cash(furniture_item_data["price"])
			"walls":
				if is_redecorating == false:
					PlayerStats.remove_cash(FurnitureData.walls.get(placed_item_id)["price"])
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

# Removed static type of object_node (Node3D) to fix error:
# Invalid call. Nonexistent function car_interaction_menu_assign_car in base Control
# When switching from garage scene after using car interaction menu
# To drag race when selecting a run type (Versus run)
# In it's place, added a check to see if the object is a Car, and if so to then call the function
# Will probably need to check the UI instead of the car, as the problem is thrown there
func handle_object_clicked(object_node, object_name : String, car_id : String):
	if is_redecorating:
		print_debug("Editing: " + str(object_node) + " | " + object_name + " | " + str(car_id))
		garage_scene.begin_edit_item(object_node, object_name, car_id)
		ui.show_message("Left Mouse Button to place anywhere. R to rotate.\nRight Mouse Button to cancel. X to delete, or if it's a car to send back to storage.", 9999)
	else:
		if object_node is Car:
			if int(car_id) >= 0:
				if ui.has_method("car_interaction_menu_assign_car"):
					ui.car_interaction_menu_assign_car(car_id)
					car_interaction_menu_active_car_node = object_node
					open_menu("car_interaction_menu")

func upgrade_car(car_id : String, upgrade_type : String):
	PlayerStats.upgrade_car(car_id, upgrade_type)

func store_car(car_id : String):
	PlayerStats.get_car(car_id)["is_stored"] = true
	car_interaction_menu_active_car_node.queue_free()

func sell_car(car_id : String):
	if PlayerStats.get_active_car() == car_id:
		PlayerStats.set_active_car("-1")
	var player_car_data : Dictionary = PlayerStats.get_car(car_id)
	var car_name : String = player_car_data["model"]
	var general_car_data : Dictionary = CarsData.get_car(car_name)
	
	var sale_price : int = general_car_data["price"] / 2
	
	# For every upgraded part, multiply the level by 5% of the base price of the car and add it to the sale price
	for upgrade in player_car_data["upgrades"]:
		sale_price += player_car_data["upgrades"][upgrade] * (general_car_data["price"] * 0.05)
	
	car_interaction_menu_active_car_node.queue_free()
	PlayerStats.add_cash(sale_price)
	PlayerStats.remove_car(car_id)
	ui.update_labels()

func remove_player_car_from_garage(car_id : String):
	garage_scene.remove_car(car_id)

func switch_time_of_day_to(target_time : String):
	match target_time:
		"day":
			world_environment.environment.background_energy_multiplier = daytime_world_environment_energy_multiplier
			environment_light.light_energy = daytime_light_energy
			environment_light.rotation = daytime_light_orientation
		"night":
			world_environment.environment.background_energy_multiplier = nighttime_world_environment_energy_multiplier
			environment_light.light_energy = nighttime_light_energy
			environment_light.rotation = nighttime_light_orientation
		_:
			pass

func update_car_wheels(wheel_name : String):
	car_interaction_menu_active_car_node.set_wheels(wheel_name)
	ui.update_labels()

func update_car_color(color : Color):
	car_interaction_menu_active_car_node.set_color(color)
	ui.update_labels()

func save_game():
	ui.show_message("Saving game...", 9999)
	var serialized_data : Dictionary = {}
	var player_cars_placed_in_garage : Dictionary = {}
	var decor_items_in_garage : Dictionary = {}
	var car_lifts_in_garage : Dictionary = {}
	var walls : Dictionary = {}
	var tiles : Dictionary = {}
	
	# Serialize player data
	# Does not contain WHICH tiles the player owns, only the number.
	# Those will need to be serialized separately
	var player_data : Dictionary = {
		"cash": PlayerStats.get_cash(),
		"rep": PlayerStats.get_rep(),
		"max_fuel": PlayerStats.max_fuel,
		"fuel": PlayerStats.fuel,
		"tiles_owned": PlayerStats.get_tiles_owned(),
		"total_mechanics": PlayerStats.get_total_mechanics(),
		"upgrade_parts": {
			"engine": PlayerStats.engine_parts,
			"weight": PlayerStats.weight_parts,
			"transmission": PlayerStats.transmission_parts,
			"nitrous": PlayerStats.nitrous_parts
		},
		"owned_cars": PlayerStats.get_owned_cars(),
		"active_car": PlayerStats.get_active_car()
	}
	serialized_data.get_or_add("player_data", player_data)
	
	# Get all nodes with the "Persist" group
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	
	# Serialize node data
	for node in save_nodes:
		# Logic to serialize player owned cars placed in the garage
		if node.get_groups().has("Player Car Container"):
			for car : Node3D in node.get_children():
				var player_car_entry : Dictionary = {
					"internal_name": car.get_internal_name(),
					"internal_id": car.get_internal_id(),
					"position_x": car.position.x,
					"position_y": car.position.y,
					"position_z": car.position.z,
					"rotation_x": car.rotation.x,
					"rotation_y": car.rotation.y,
					"rotation_z": car.rotation.z,
				}
				player_cars_placed_in_garage.get_or_add(car, player_car_entry)
			# Add the serialized car data to the "serialized_data" dictionary
			serialized_data.get_or_add("player_cars_placed_in_garage", player_cars_placed_in_garage)
		elif node.get_groups().has("Garage Decorations Container"):
			for decor_item in node.get_children():
				var decor_item_entry : Dictionary = {
					"internal_name": decor_item.get_internal_name(),
					"position_x": decor_item.position.x,
					"position_y": decor_item.position.y,
					"position_z": decor_item.position.z,
					"rotation_x": decor_item.rotation.x,
					"rotation_y": decor_item.rotation.y,
					"rotation_z": decor_item.rotation.z,
				}
				decor_items_in_garage.get_or_add(decor_item, decor_item_entry)
			# Add the serialized decorations data to the "serialized_data" dictionary
			serialized_data.get_or_add("decor_items_in_garage", decor_items_in_garage)
		elif node.get_groups().has("Car Lifts Container"):
			for car_lift in node.get_children():
				var car_lift_entry : Dictionary = {
					"internal_name": car_lift.get_internal_name(),
					"position_x": car_lift.position.x,
					"position_y": car_lift.position.y,
					"position_z": car_lift.position.z,
					"rotation_x": car_lift.rotation.x,
					"rotation_y": car_lift.rotation.y,
					"rotation_z": car_lift.rotation.z,
				}
				car_lifts_in_garage.get_or_add(car_lift, car_lift_entry)
			# Add the serialized car lifts data to the "serialized_data" dictionary
			serialized_data.get_or_add("car_lifts_in_garage", car_lifts_in_garage)
		elif node.get_groups().has("Walls Container"):
			for wall in node.get_children():
				var wall_entry : Dictionary = {
					"internal_name": wall.get_internal_name(),
					"position_x": wall.position.x,
					"position_y": wall.position.y,
					"position_z": wall.position.z,
					"rotation_x": wall.rotation.x,
					"rotation_y": wall.rotation.y,
					"rotation_z": wall.rotation.z,
				}
				walls.get_or_add(wall, wall_entry)
			# Add the serialized walls data to the "serialized_data" dictionary
			serialized_data.get_or_add("walls", walls)
		elif node.get_groups().has("Tile"):
			# Store only the unlocked tiles
			for tile : Tile in node.get_children():
				if tile.is_unlocked:
					var grid_map : GridMap = tile.get_grid_map()
					var mesh_library_item_list = grid_map.mesh_library.get_item_list()
					# Takes an item from the mesh library as a key
					# Stores an array of Vector3's that represent cells in the tile in which that
					# item is placed in
					var mesh_library_items : Dictionary = {}
					
					for item in mesh_library_item_list:
						var cells_by_item = grid_map.get_used_cells_by_item(item)
						mesh_library_items.get_or_add(item, cells_by_item)
				
					var tile_entry : Dictionary = {
						"mesh_library_items": mesh_library_items,
						"position_x": tile.position.x,
						"position_y": tile.position.y,
						"position_z": tile.position.z,
					}
					tiles.get_or_add(tile, tile_entry)
			# Add the serialized tiles data to the "serialized_data" dictionary
			serialized_data.get_or_add("tiles", tiles)
	
	# Create save data folder in user directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists(save_data_path):
		dir.make_dir_recursive(save_data_path)
	
	# Write serialized data to file - JSON FORMAT
	var save_file = FileAccess.open(save_data_path+"/"+save_file_name, FileAccess.WRITE)
	var json_string = JSON.stringify(serialized_data, "\t",false)
	save_file.store_string(json_string)
	save_file.close()
	ui.show_message("Save completed", 3)

func load_game():
	if FileAccess.file_exists(save_data_path+"/"+save_file_name):
		ui.show_message("Existing save file found, loading...", 9999)
		# Read data from file
		var save_file = FileAccess.open(save_data_path+"/"+save_file_name, FileAccess.READ)
		var save_data : Dictionary = JSON.parse_string(save_file.get_as_text())
		save_file.close()
		
		# Load player data:
		PlayerStats.cash = save_data["player_data"]["cash"]
		PlayerStats.rep = save_data["player_data"]["rep"]
		PlayerStats.max_fuel = save_data["player_data"]["max_fuel"]
		PlayerStats.fuel = save_data["player_data"]["fuel"]
		PlayerStats.tiles_owned = save_data["player_data"]["tiles_owned"]
		PlayerStats.total_mechanics = save_data["player_data"]["total_mechanics"]
		PlayerStats.available_mechanics = PlayerStats.total_mechanics
		PlayerStats.engine_parts = save_data["player_data"]["upgrade_parts"]["engine"]
		PlayerStats.weight_parts = save_data["player_data"]["upgrade_parts"]["weight"]
		PlayerStats.transmission_parts = save_data["player_data"]["upgrade_parts"]["transmission"]
		PlayerStats.nitrous_parts = save_data["player_data"]["upgrade_parts"]["nitrous"]
		PlayerStats.owned_cars = save_data["player_data"]["owned_cars"]
		PlayerStats.active_car = save_data["player_data"]["active_car"]
		
		# Place player owned cars in the garage
		garage_scene.place_player_owned_cars(save_data["player_cars_placed_in_garage"])
		# Place decor items in the garage
		garage_scene.place_garage_decor(save_data["decor_items_in_garage"])
		# Place car lifts in the garage
		garage_scene.place_car_lifts(save_data["car_lifts_in_garage"])
		# Place walls in the garage
		garage_scene.place_walls(save_data["walls"])
		# Tiles
		garage_scene.load_tiles(save_data["tiles"])
		ui.show_message("Loaded save data", 3)
