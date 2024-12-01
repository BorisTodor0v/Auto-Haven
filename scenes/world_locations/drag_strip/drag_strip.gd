extends WorldLocation

# Cameras
@onready var menu_camera : Camera3D = $CameraHolder/CarShowcaseCamera
@onready var race_camera : Camera3D = $CameraHolder/RaceCamera

@onready var player_car_positon : Node3D = $"Grid Positions/Slot1"
var player_car : Car
var player_car_data 
var general_car_data

# Called when the node enters the scene tree for the first time.
func _ready():
	set_camera($CameraHolder/CarShowcaseCamera)
	set_ui($UI)
	ui.connect("leave_location", leave_location.emit)
	ui.connect("race_confirmed", set_active_camera.bind(1))
	ui.connect("run_finished", set_active_camera.bind(0))
	ui.update_labels()

func set_player_car(player_car_id : int):
	print_debug(PlayerStats.get_car(player_car_id)["model"])
	player_car_data = PlayerStats.get_car(player_car_id)
	general_car_data = CarsData.get_car(player_car_data["model"])
	
	var scene = load(general_car_data["scene_path"])
	var instance = scene.instantiate()
	player_car = instance
	player_car_positon.add_child(player_car)

func set_active_camera(camera_type : int):
	match camera_type:
		0: # Menu Camera
			menu_camera.current = true
		1: # Race Camera
			race_camera.current = true
		_: # Other
			pass

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
	#"is_stored": true
#}

#"chal":{
	#"name": "Phoenix",
	#"manufacturer": "Liberty Motors",
	#"price": 20000,
	#"gears": 6,
	#"top_speed_for_gear": [24.5435, 34.43281, 44.3889, 54.7222, 64.5913, 68.4444],
	#"acceleration_rate_for_gear": [6, 6, 5, 5, 4, 3],
	#"top_speed_mps": 68.4444,
	#"redline": 7500,
	#"max_rpm": 7700,
	#"peak_hp_rpm": 7100,
	#"scene_path": "res://cars/models/chal/chal.tscn",
	#"model_path": "res://cars/models/chal/chal.glb",
	#"default_wheels": "wheel_001"
#}
