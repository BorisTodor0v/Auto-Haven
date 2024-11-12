extends Node

var cash : int = 10000
var rep : int = 0

var tiles_owned : int = 1

var total_mechanics : int = 0
var available_mechanics : int = 0
var mechanic_base_cost : int = 5000

var owned_cars : Dictionary = {}

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
func get_tile_cost() -> int:
	return 5000

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
