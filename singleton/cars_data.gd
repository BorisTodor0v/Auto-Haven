extends Node

var cars = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the cars from cars_data.json
	if FileAccess.file_exists("res://data/cars_data.json"):
		var cars_file = FileAccess.open("res://data/cars_data.json", FileAccess.READ)
		var cars_json = JSON.parse_string(cars_file.get_as_text())
		cars_file.close()
		cars = cars_json
	else:
		# Make this a dialog window that pops up and then quits the game
		print_debug("File cars_data.json in game directory /data not found!")
		get_tree().quit()

func get_all_cars():
	return cars

func get_car(key : String):
	return cars[key]

func get_values_from_key(key : String):
	return cars.get(key)
