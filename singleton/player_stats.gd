extends Node

var cash : int = 100000
var rep : int = 0

var tiles_owned : int = 1
var tile_base_price : int = 5000

var total_mechanics : int = 0
var available_mechanics : int = 0
var mechanic_base_cost : int = 5000

# TODO: Combine these into a dictionary
var engine_parts : int = 1000
var weight_parts : int = 1000 # Carbon fibre parts to reduce weight
var transmission_parts : int = 1000
var nitrous_parts : int = 1000

var owned_cars : Dictionary = {}
var active_car : int = -1

func add_cash(_cash : int):
	cash += _cash

func remove_cash(_cash : int):
	cash -= _cash

func add_rep(_rep : int):
	rep += _rep

func get_cash():
	return cash

func get_rep():
	return rep

func hire_mechanic():
	total_mechanics += 1
	available_mechanics += 1

func get_total_mechanics() -> int:
	return total_mechanics

func get_available_mechanics() -> int:
	return available_mechanics

func assign_mechanic():
	if available_mechanics >= 1:
		available_mechanics -= 1

func free_mechanic():
	if available_mechanics < total_mechanics:
		available_mechanics += 1

func get_mechanic_cost() -> int:
	return mechanic_base_cost * (total_mechanics + 1)

func get_tiles_owned() -> int:
	return tiles_owned

func set_tiles_owned(new_value : int):
	tiles_owned = new_value

# Don't know if this should be here, in the player stats function, but leave as is for now
func get_garage_expansion_cost() -> int:
	return tile_base_price * tiles_owned

func add_car(new_car : Dictionary):
	print("Adding " + new_car["model"] + " to player's car collection")
	var id : int = owned_cars.size()+1
	owned_cars.get_or_add(id, new_car)
	print("Current collection:")
	print_debug(owned_cars)

## Returns all player owned cars
func get_owned_cars():
	return owned_cars

## Returns the car that corresponds with the id
func get_car(id : int):
	return owned_cars[id]

func get_active_car():
	return active_car

func set_active_car(id : int):
	active_car = id

func add_upgrade_parts(type : String, amount : int):
	match type:
		"engine":
			engine_parts += amount
		"weight":
			weight_parts += amount
		"nitrous":
			nitrous_parts += amount
		"transmission":
			transmission_parts += amount

func remove_upgrade_parts(type : String, amount : int):
	match type:
		"engine":
			engine_parts -= amount
		"weight":
			weight_parts -= amount
		"nitrous":
			nitrous_parts -= amount
		"transmission":
			transmission_parts -= amount

func get_upgrade_parts(type : String):
	match type:
		"engine":
			return engine_parts
		"weight":
			return weight_parts
		"nitrous":
			return nitrous_parts
		"transmission":
			return transmission_parts

func upgrade_car(car_id : int, upgrade_type : String):
	var current_car : Dictionary = get_car(car_id)
	if upgrade_type == "engine" || \
	upgrade_type == "weight" || \
	upgrade_type == "nitrous" || \
	upgrade_type == "transmission":
		if current_car["upgrades"][upgrade_type] < 10:
			var parts_needed : int = (current_car["upgrades"][upgrade_type]+1) * 10
			if get_upgrade_parts(upgrade_type) >= parts_needed:
				current_car["upgrades"][upgrade_type] += 1
				remove_upgrade_parts(upgrade_type, parts_needed)
				# TODO: Change performance values here
				if upgrade_type == "engine": # Top speed
					for i in current_car["performance_data"]["top_speed_for_gear"].size():
						current_car["performance_data"]["top_speed_for_gear"][i] += 2 # TODO: Test with different values
						# TODO: Change increase in performance, current value is for testing only 
					current_car["performance_data"]["top_speed_mps"] += 2
				elif upgrade_type == "transmission": # Acceleration
					for i in current_car["performance_data"]["acceleration_rate_for_gear"].size():
						current_car["performance_data"]["acceleration_rate_for_gear"][i] += 1 # TODO: Test with different values (0.2)
						# TODO: Change increase in performance, current value is for testing only 
				elif upgrade_type == "weight": # Top speed and acceleration
					# Top speed
					for i in current_car["performance_data"]["top_speed_for_gear"].size():
						current_car["performance_data"]["top_speed_for_gear"][i] += 1 # TODO: Test with different values
						# TODO: Change increase in performance, current value is for testing only 
					current_car["performance_data"]["top_speed_mps"] += 1
					# Acceleration
					for i in current_car["performance_data"]["acceleration_rate_for_gear"].size():
						current_car["performance_data"]["acceleration_rate_for_gear"][i] += .5 # TODO: Test with different values (0.2)
						# TODO: Change increase in performance, current value is for testing only
				elif upgrade_type == "nitrous":
					pass
					# TODO: Figure out how to handle nitrous upgrades:
					# IDEA
					# The number of the nitro upgrade divided by 2 represents how long does the nitrous last when activated
					# The number of the nitro upgrade divided by 10 represents how much bonus acceleration is added when activated
			else:
				print_debug("Not enough parts for this upgrade")
		else:
			print_debug("Car has reached maximum level for this upgrade")
	else:
		print_debug("Invalid upgrade type - " + upgrade_type)

#car = {
	#"model": car_key,
	#"color": car_color,
	#"wheels": car_data["default_wheels"],
	#"upgrades": {
		#"engine": 0,
		#"weight": 0,
		#"transmission": 0,
		#"nitrous": 0
	#},
	#"is_stored": true,
	#"performance_data": {
		#"top_speed_for_gear": car_data["top_speed_for_gear"],
		#"top_speed_mps": car_data["top_speed_mps"],
		#"acceleration_rate_for_gear": car_data["acceleration_rate_for_gear"],
		#"redline": car_data["redline"],
		#"max_rpm": car_data["max_rpm"],
		#"gears": car_data["gears"]
	#}
#}
