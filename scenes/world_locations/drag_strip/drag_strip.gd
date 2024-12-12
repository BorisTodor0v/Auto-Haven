extends WorldLocation

# Cameras
@onready var menu_camera : Camera3D = $CameraHolder/CarShowcaseCamera
@onready var race_camera : Camera3D = $CameraHolder/RaceCamera
@onready var camera_tracker : Node3D = $CameraTracker
@onready var camera_tracker_initial_position

@onready var player_car_position : Node3D = $"Grid Positions/Slot1"
var player_car : Car
var player_car_data 
var general_car_data

var current_rpm : float = 0
var current_velocity : float = 0
var current_gear : int = 1
var race_time : float = 0
var reaction_time : float = 0

enum RaceStates {
	NONE,
	LAUNCH,
	RUN,
	FINISHED
}
var race_state : RaceStates = RaceStates.NONE
@onready var race_countdown_timer : Timer = $Node/RaceStartCountdownTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	camera_tracker_initial_position = camera_tracker.global_position
	set_camera($CameraHolder/CarShowcaseCamera)
	set_ui($UI)
	ui.connect("leave_location", leave_location.emit)
	ui.connect("race_confirmed", start_race_countdown)
	ui.connect("launch", launch)
	ui.connect("shift_gear", shift_gear)
	ui.connect("run_finished", reset_cars)
	ui.update_labels()

func _process(delta):
	if race_state == RaceStates.LAUNCH:
		if race_countdown_timer.is_stopped():
			ui.set_countdown_label_text("GO")
			reaction_time += delta
		else:
			ui.set_countdown_label_text(str("%.3f" % race_countdown_timer.time_left))
	elif race_state == RaceStates.RUN:
		accelerate_player_car(delta)
		race_time += delta
		ui.set_race_labels(current_gear, current_velocity, race_time)
	elif race_state == RaceStates.FINISHED:
		decelerate_player_car(delta)
	# When state is none, player is in the race select menu

func set_player_car(player_car_id : int):
	print_debug(PlayerStats.get_car(player_car_id)["model"])
	player_car_data = PlayerStats.get_car(player_car_id)
	general_car_data = CarsData.get_car(player_car_data["model"])
	
	var scene = load(general_car_data["scene_path"])
	var instance = scene.instantiate()
	player_car = instance
	player_car_position.add_child(player_car)
	
	if player_car_data["upgrades"]["nitrous"] == 0:
		ui.hide_nitrous_components()
	else:
		ui.show_nitrous_components()
	
	ui.set_redline(player_car_data["performance_data"]["redline"])

func set_active_camera(camera_type : int):
	match camera_type:
		0: # Menu Camera
			menu_camera.current = true
		1: # Race Camera
			race_camera.current = true
		_: # Other
			print_debug("Invalid camera - " + str(camera_type))
			pass

func start_race_countdown():
	set_active_camera(1)
	race_countdown_timer.start()
	race_state = RaceStates.LAUNCH

func launch():
	if race_countdown_timer.is_stopped(): # Proper launch, start driving
		race_state = RaceStates.RUN
		ui.show_upshift_button()
		ui.show_race_screen()
	else: # False start, stop the race
		race_state = RaceStates.NONE
		show_post_race_screen("dsq")

func accelerate_player_car(delta):
	if current_rpm < player_car_data["performance_data"]["max_rpm"] && current_velocity < player_car_data["performance_data"]["top_speed_mps"]:
		current_rpm = current_velocity / player_car_data["performance_data"]["top_speed_for_gear"][current_gear - 1] * player_car_data["performance_data"]["max_rpm"]
		current_velocity += player_car_data["performance_data"]["acceleration_rate_for_gear"][current_gear - 1] * delta
	ui.set_rpm(current_rpm)
	move_player_car(delta)

func decelerate_player_car(delta):
	if current_velocity > 2:
		current_velocity -= 20 * delta
	else:
		current_velocity = 0
	move_player_car(delta)

func move_player_car(delta):
	player_car.translate(Vector3(0,0,1)*current_velocity*delta)
	camera_tracker.translate(Vector3(0,0,1)*current_velocity*delta)
	race_camera.global_position = lerp(race_camera.global_position, camera_tracker.global_position, randf_range(0.17, 0.2))

func shift_gear():
	if current_gear < player_car_data["performance_data"]["gears"]:
			player_car.play_gearshift_animation()
			current_gear += 1
			if current_gear == player_car_data["performance_data"]["gears"]:
				ui.hide_upshift_button()
			
			var previous_gear_top_speed = player_car_data["performance_data"]["top_speed_for_gear"][current_gear - 2]
			var new_gear_top_speed = player_car_data["performance_data"]["top_speed_for_gear"][current_gear - 1]
			current_rpm *= previous_gear_top_speed / new_gear_top_speed

func _on_finish_line_area_3d_area_entered(area):
	if area.get_parent() == player_car:
		print_debug("Player crossed the line first")
	else:
		print_debug("Rival car crossed the line first")
	end_race()

func end_race():
	race_state = RaceStates.FINISHED
	show_post_race_screen("win")
	# TODO: Handle losing the race
	#show_post_race_screen("loss")

func reset_cars():
	race_state = RaceStates.NONE
	camera_tracker.global_position = camera_tracker_initial_position
	race_camera.global_position = camera_tracker.global_position
	player_car.global_transform.origin = player_car_position.global_transform.origin
	
	race_time = 0
	reaction_time = 0
	current_rpm = 0
	current_gear = 1
	current_velocity = 0
	
	set_active_camera(0)
	ui.show_upshift_button()

func show_post_race_screen(finish_type : String):
	var run_stats = {
		"reaction_time" : reaction_time,
		"race_time": race_time,
		"total_time": race_time + reaction_time
		## TODO: Add opponent data
	}
	ui.show_post_race_screen(finish_type, run_stats)

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
