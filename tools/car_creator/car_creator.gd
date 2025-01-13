## Tool to input car data without having to write JSON manually.
## First make a folder with the name of the car.
## Insert the model in that folder and create a scene for the car.
## The folder, the model and the scene all must have the same name.
## Afterwards, open this tool and input the data for the car in the editor.
## Then run the scene of this tool (F6 in editor).
## If all the data is valid, the data will successfully be saved and the car will appear in game.
## Otherwise, a message will be displayed in the editor to display everything wrong with the data.
extends Node3D

@export var car_name : String
@export var manufacturer : String
@export var price : int
@export var gears : int
@export var top_speed_for_gear : Array[float]
@export var acceleration_rate_for_gear : Array[float]
#@export var top_speed_meters_per_second : float
@export var redline : int
@export var max_rpm : int
@export var peak_hp_rpm : int
## Name of the folder, model and scene of the car. 
@export var internal_name : String
@export var default_wheels : String
@export var can_buy_in_dealership : bool
## Minimum value is 0, cannot be negative.
## Higher number means higher value car, which means can only be owned by richer racers
@export var car_class : int

# Separate file used for testing
#var cars_data_file_path : String = "res://data/cars_data_TEST.json"
var cars_data_file_path : String = "res://data/cars_data.json"

var can_write : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	var cars_file = FileAccess.open(cars_data_file_path, FileAccess.READ)
	var existing_data : Dictionary = JSON.parse_string(cars_file.get_as_text())
	cars_file.close()
	
	if existing_data.has(internal_name):
		print("Car with name %s already exists" % internal_name)
		can_write = false
	if car_name == "" || car_name == null:
		print("Car name cannot be empty or null")
		can_write = false
	if manufacturer == "" || manufacturer == null:
		print("Manufacturer name cannot be empty or null")
		can_write = false
	if price <= 0:
		print("Price must be above 0")
		can_write = false
	if gears < 1:
		print("Car must have atleast 1 gear")
		can_write = false
	if top_speed_for_gear.size() != gears:
		print("The number of speeds does not match the number of gears")
		can_write = false
	for speed in top_speed_for_gear:
		if speed <= 0:
			print("Speed %d must be above 0" % speed)
			can_write = false
	if max_rpm <= 0:
		print("Max RPM must be above 0")
		can_write = false
	if redline <= 0:
		print("Redline RPM must be above 0")
		can_write = false
	else:
		if redline > max_rpm:
			print("Redline RPM cannot be above Max RPM")
			can_write = false
	# Unsure if this parameter will ever be used
	if peak_hp_rpm <= 0:
		print("Peak HP RPM must be above 0")
		can_write = false
	else:
		if peak_hp_rpm > max_rpm:
			print("Peak HP RPM cannot be above Max RPM")
			can_write = false
	if internal_name == "" || internal_name == null:
		print("Manufacturer name cannot be empty or null")
		can_write = false
	else:
		# Check if folder containing model and scene exists
		if DirAccess.dir_exists_absolute("res://cars/models/%s/" % internal_name) == false:
			print("Folder does not exist")
			can_write = false
		else:
			if FileAccess.file_exists("res://cars/models/%s/%s.tscn" % [internal_name, internal_name]) == false:
				print("Scene file for %s does not exist" % internal_name)
				can_write = false
			if FileAccess.file_exists("res://cars/models/%s/%s.glb" % [internal_name, internal_name]) == false:
				print("Model file for %s does not exist" % internal_name)
				can_write = false
	if default_wheels == "" || default_wheels == null:
		print("Name of default wheels cannot be empty or null")
		can_write = false
	else:
		if FileAccess.file_exists("res://cars/wheels/"+default_wheels+"/"+default_wheels+".glb"):
			print("Invalid name of default wheels")
			can_write = false
	if car_class < 0:
		print("Car class must be a non-negative integer")
		can_write = false
	
	if can_write:
		# Made it past verification, now write to JSON
		var data : Dictionary = {
			"name": car_name,
			"manufacturer": manufacturer,
			"price": price,
			"gears": gears,
			"top_speed_for_gear": top_speed_for_gear,
			"acceleration_rate_for_gear": acceleration_rate_for_gear,
			"top_speed_mps": top_speed_for_gear[top_speed_for_gear.size()-1],
			"redline": redline,
			"max_rpm": max_rpm,
			"peak_hp_rpm": peak_hp_rpm,
			"scene_path": "res://cars/models/"+internal_name+"/"+internal_name+".tscn",
			"model_path": "res://cars/models/"+internal_name+"/"+internal_name+".glb",
			"default_wheels": default_wheels,
			"can_buy_in_dealership": can_buy_in_dealership,
			"class": car_class
		}
		
		existing_data.get_or_add(internal_name, data)
		var data_to_json = JSON.stringify(existing_data, "\t",false)
		
		cars_file = FileAccess.open(cars_data_file_path, FileAccess.WRITE)
		cars_file.store_string(data_to_json)
		cars_file.close()
