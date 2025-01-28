extends Node

var cars = {}
var number_of_car_classes : int = 4
var wheels = {}

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
	
	if DirAccess.dir_exists_absolute("res://cars/wheels"):
		var wheel_directories = DirAccess.get_directories_at("res://cars/wheels")
		for wheel in wheel_directories:
			var price : int = 1000 # -- At the moment every set of wheels costs the same
			
			var wheel_data : Dictionary = {
				"price" : price
			}
			
			wheels.get_or_add(wheel, wheel_data)
	else:
		print_debug("Wheels directory in game directory /cars not found!")
		get_tree().quit()
		

func get_all_cars():
	return cars

func get_car(key : String):
	return cars[key]

func get_values_from_key(key : String):
	return cars.get(key)

func get_all_wheels():
	return wheels

func get_wheel(wheel_name : String):
	wheels[wheel_name]

# Car classes:
# 0 - Poor
# 1 - Mid
# 2 - High End
# 3 - Rich
# -- More might be added
func get_all_cars_by_class(class_value : int) -> Dictionary:
	if class_value > number_of_car_classes - 1 || class_value < 0:
		print_debug("Invalid car class value: %d | Must be above 0 and below %d" % [class_value, number_of_car_classes])
		return {}
	else:
		var result_cars : Dictionary = {}
		for car in cars:
			if cars[car]["class"] == class_value:
				result_cars.get_or_add(car, cars[car])
		return result_cars

func parse_color_from_string(color_string : String) -> Color:
	var error_color : Color = Color(1, 0.412, .716, 1)
	if !color_string.begins_with("(") and !color_string.ends_with(")"):
		print_debug("Color string does not start and end with brackets")
		return error_color
	var remove_brackets = color_string.erase(0, 1)
	remove_brackets = remove_brackets.erase(remove_brackets.length()-1, 1)
	var split_segments = color_string.split(',')
	if split_segments.size() != 4:
		print_debug("Invalid amount of segments after splitting (Expected 4, got %d)" % split_segments.size())
		return error_color
	var r : float = float(split_segments[0])
	var g : float = float(split_segments[1])
	var b : float = float(split_segments[2])
	var a : float = float(split_segments[3])
	
	var parsed_color : Color = Color(r, g, b, a)
	return parsed_color
