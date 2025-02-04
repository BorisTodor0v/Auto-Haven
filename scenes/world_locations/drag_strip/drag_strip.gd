extends WorldLocation

# Cameras
@onready var menu_camera : Camera3D = $CameraHolder/CarShowcaseCamera
@onready var race_camera : Camera3D = $CameraHolder/RaceCamera
@onready var camera_tracker : Node3D = $CameraTracker
@onready var camera_tracker_initial_position

var number_of_cars : int

@export var player_car_position : Node3D
var player_car : Car
var player_car_data 
var player_car_wheels : Node3D
var player_general_car_data
var player_nitrous_power : float
var player_nitrous_duration : float
var player_nitrous_duration_remaining : float
var is_nitrous_active : bool = false

@export var rival_car_position : Node3D
var rival_car : Car
var rival_car_data
var rival_car_wheels : Node3D
var rival_general_car_data

var race_time : float = 0

var current_rpm : float = 0
var current_velocity : float = 0
var current_gear : int = 1
var player_crossed_line : bool = true
var player_time : float = 0
var player_reaction_time : float = 0

var rival_rpm : float = 0
var rival_velocity : float = 0
var rival_gear : int = 1
var rival_shift_point : float = 0
var rival_crossed_line : bool = true
var rival_time : float = 0
var rival_reaction_time : float = 0
#@onready var reaction_timer : Timer = $Node/RivalDriverReactionTimeTimer
@export var reaction_timer : Timer

enum RaceStates {
	NONE,
	LAUNCH,
	TEST_RUN, # Accelerate only the player car
	VERSUS_RUN, # Accelerate player and rival car
}
var race_state : RaceStates = RaceStates.NONE
@onready var race_countdown_timer : Timer = $Node/RaceStartCountdownTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	number_of_cars = CarsData.get_all_cars().size()
	camera_tracker_initial_position = camera_tracker.global_position
	set_camera($CameraHolder/CarShowcaseCamera)
	set_ui($UI)
	ui.connect("leave_location", leave_location.emit)
	ui.connect("race_confirmed", confirm_race)
	ui.connect("launch", launch)
	ui.connect("shift_gear", shift_gear)
	ui.connect("fire_nitrous", fire_nitrous_player)
	ui.connect("run_finished", reset_cars)
	ui.update_labels()
	generate_rival()
	

func _process(delta):
	if race_state == RaceStates.LAUNCH:
		if race_countdown_timer.is_stopped():
			ui.set_countdown_label_text("GO")
			player_reaction_time += delta
		else:
			ui.set_countdown_label_text(str("%.3f" % race_countdown_timer.time_left))
	elif race_state == RaceStates.TEST_RUN:
		if player_crossed_line == false:
			accelerate_player_car(delta)
		else:
			decelerate_player_car(delta)
		race_time += delta
		ui.set_race_labels(current_gear, current_velocity, race_time)
	elif race_state == RaceStates.VERSUS_RUN:
		race_time += delta
		if player_crossed_line == false:
			accelerate_player_car(delta)
		else:
			decelerate_player_car(delta)
			
		if rival_crossed_line == false:
			accelerate_rival_car(delta)
			rival_time = race_time
		else:
			decelerate_rival_car(delta)
		ui.set_race_labels(current_gear, current_velocity, race_time)
	# When state is none, player is in the race select menu
	
	if is_nitrous_active:
		player_nitrous_duration_remaining -= delta
		ui.set_nitrous_bar_value(player_nitrous_duration_remaining)
		if player_nitrous_duration_remaining <= 0:
			is_nitrous_active = false

func set_player_car(player_car_id : String):
	player_car_data = PlayerStats.get_car(player_car_id)
	player_general_car_data = CarsData.get_car(player_car_data["model"])
	
	var scene = load(player_general_car_data["scene_path"])
	var instance = scene.instantiate()
	player_car = instance
	player_car_position.add_child(player_car)
	
	## Add wheels to the car model
	var wheel_model = load("res://cars/wheels/"+player_car_data["wheels"]+"/"+player_car_data["wheels"]+".glb").instantiate()
	for child in instance.get_children():
		if child.name == "WheelPositions":
			for wheel_position in child.get_children():
				wheel_position.add_child(wheel_model.duplicate())
			break
	
	## Change color
	var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
	var mesh : MeshInstance3D = null
	for child in instance.get_children():
		if child is MeshInstance3D:
			mesh = child
	if mesh != null && material != null:
		if player_car_data["color"] is Color:
			material.albedo_color = player_car_data["color"]
		else:
			material.albedo_color = CarsData.parse_color_from_string(player_car_data["color"])
		mesh.set_surface_override_material(0, material)
	
	player_car_wheels = player_car.get_wheels()
	
	if player_car_data["upgrades"]["nitrous"] == 0:
		ui.hide_nitrous_components()
	else:
		ui.show_nitrous_components()
		player_nitrous_duration = float(player_car_data["upgrades"]["nitrous"]) / 2
		ui.set_nitrous_bar_max_value(player_nitrous_duration)
		ui.set_nitrous_bar_value(player_nitrous_duration)
		player_nitrous_duration_remaining = player_nitrous_duration
		player_nitrous_power = 1 + (float(player_car_data["upgrades"]["nitrous"]) / 13.3)
	
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

func confirm_race(race_type : String):
	if race_type == "test_run":
		rival_car_position.hide()
	elif race_type == "versus_run":
		rival_car_position.show()
	start_race_countdown()

func start_race_countdown():
	set_active_camera(1)
	race_countdown_timer.start()
	race_state = RaceStates.LAUNCH

func _on_race_start_countdown_timer_timeout():
	if rival_car_position.visible == true:
		race_state = RaceStates.VERSUS_RUN
		reaction_timer.start()
	else:
		race_state = RaceStates.TEST_RUN

func _on_rival_driver_reaction_time_timer_timeout():
	rival_crossed_line = false # Rival starts moving

func launch():
	if race_state == RaceStates.VERSUS_RUN || race_state == RaceStates.TEST_RUN:
		player_reaction_time = race_time
		player_crossed_line = false
		ui.show_upshift_button()
		ui.show_race_screen()
	else: # False start, stop the race
		show_post_race_screen("dsq")
		PlayerStats.get_car(PlayerStats.get_active_car())["losses"] += 1
		var rewards_string : String = "Wait for the timer to reach 0 before starting"
		ui.rewards_label.text = rewards_string
		reset_cars()

func accelerate_player_car(delta):
	if current_rpm < player_car_data["performance_data"]["max_rpm"] && current_velocity < player_car_data["performance_data"]["top_speed_mps"]:
		current_rpm = current_velocity / player_car_data["performance_data"]["top_speed_for_gear"][current_gear - 1] * player_car_data["performance_data"]["max_rpm"]
		if is_nitrous_active:
			current_velocity += (player_car_data["performance_data"]["acceleration_rate_for_gear"][current_gear - 1] * player_nitrous_power)* delta
		else:
			current_velocity += player_car_data["performance_data"]["acceleration_rate_for_gear"][current_gear - 1] * delta
	ui.set_rpm(current_rpm)
	move_player_car(delta)

func decelerate_player_car(delta):
	if current_velocity > 2:
		current_velocity -= 30 * delta
	else:
		current_velocity = 0
	move_player_car(delta)

func move_player_car(delta):
	player_car.translate(Vector3(0,0,1)*current_velocity*delta)
	camera_tracker.translate(Vector3(0,0,1)*current_velocity*delta)
	race_camera.global_position = lerp(race_camera.global_position, camera_tracker.global_position, randf_range(0.17, 0.2))
	
	var wheel_rotation_angle = current_velocity * delta / (2 * PI * 0.29) * 2 * PI
	if player_car_wheels != null:
		player_car_wheels.get_child(0).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
		player_car_wheels.get_child(1).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
		player_car_wheels.get_child(2).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
		player_car_wheels.get_child(3).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)

func shift_gear():
	if current_gear < player_car_data["performance_data"]["gears"]:
			player_car.play_gearshift_animation()
			current_gear += 1
			if current_gear == player_car_data["performance_data"]["gears"]:
				ui.hide_upshift_button()
			
			var previous_gear_top_speed = player_car_data["performance_data"]["top_speed_for_gear"][current_gear - 2]
			var new_gear_top_speed = player_car_data["performance_data"]["top_speed_for_gear"][current_gear - 1]
			current_rpm *= previous_gear_top_speed / new_gear_top_speed

func accelerate_rival_car(delta):
	if rival_rpm < rival_general_car_data["max_rpm"] && rival_general_car_data["top_speed_mps"]:
		rival_rpm = rival_velocity / rival_general_car_data["top_speed_for_gear"][rival_gear - 1] * rival_general_car_data["max_rpm"]
		rival_velocity += rival_general_car_data["acceleration_rate_for_gear"][rival_gear - 1] * delta
	move_rival_car(delta)
	
	# Gear shifting logic
	if rival_rpm >= rival_shift_point && rival_gear < rival_general_car_data["gears"]:
		rival_car.play_gearshift_animation()
		rival_gear += 1
		var previous_gear_top_speed = rival_general_car_data["top_speed_for_gear"][rival_gear - 2]
		var new_gear_top_speed = rival_general_car_data["top_speed_for_gear"][rival_gear - 1]
		rival_rpm *= previous_gear_top_speed / new_gear_top_speed

func decelerate_rival_car(delta):
	if rival_velocity > 2:
		rival_velocity -= 30 * delta
	else:
		rival_velocity = 0
	move_rival_car(delta)

func move_rival_car(delta):
	rival_car.translate(Vector3(0,0,1)*rival_velocity*delta)
	var wheel_rotation_angle = current_velocity * delta / (2 * PI * 0.29) * 2 * PI
	if rival_car_wheels != null:
		rival_car_wheels.get_child(0).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
		rival_car_wheels.get_child(1).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
		rival_car_wheels.get_child(2).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
		rival_car_wheels.get_child(3).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)

func _on_finish_line_area_3d_area_entered(area):
	if area.get_parent() == player_car:
		player_time = race_time
		player_crossed_line = true
		end_race()
	elif area.get_parent() == rival_car:
		rival_time = race_time
		rival_crossed_line = true
		end_race()

func end_race():
	if race_state == RaceStates.TEST_RUN:
		show_post_race_screen("win")
	elif race_state == RaceStates.VERSUS_RUN:
		if player_crossed_line && rival_crossed_line == false:
			show_post_race_screen("win")
			give_rewards()
		elif player_crossed_line && rival_crossed_line:
			if player_time < rival_time:
				show_post_race_screen("win")
				#give_rewards()
			else:
				show_post_race_screen("loss")
				var rewards_string : String = "Better luck next time."
				ui.rewards_label.text = rewards_string
				PlayerStats.get_car(PlayerStats.get_active_car())["losses"] += 1

func reset_cars():
	race_state = RaceStates.NONE
	camera_tracker.global_position = camera_tracker_initial_position
	race_camera.global_position = camera_tracker.global_position
	player_car.global_transform.origin = player_car_position.global_transform.origin
	rival_car.global_transform.origin = rival_car_position.global_transform.origin
	
	race_time = 0
	
	player_reaction_time = 0
	player_time = 0
	current_rpm = 0
	current_gear = 1
	current_velocity = 0
	player_nitrous_duration_remaining = player_nitrous_duration
	if player_car_data["upgrades"]["nitrous"] > 0:
		ui.show_nitrous_button()
		ui.set_nitrous_bar_value(player_nitrous_duration)
	is_nitrous_active = false
	
	rival_reaction_time = 0
	rival_time = 0
	rival_rpm = 0
	rival_gear = 1
	rival_velocity = 0
	
	set_active_camera(0)
	ui.show_upshift_button()
	
	generate_rival()

func show_post_race_screen(finish_type : String):
	var run_stats = {
		"reaction_time" : player_reaction_time,
		"player_run_time": player_time - player_reaction_time,
		"total_time": player_time,
		"rival_reaction_time": rival_reaction_time,
		"rival_run_time": rival_time - rival_reaction_time,
		"rival_total_time": rival_time
	}
	ui.show_post_race_screen(finish_type, run_stats)

func generate_rival():
	if rival_car_position.get_child_count() > 0:
		rival_car_position.remove_child(rival_car_position.get_child(0))
	
	if rival_car_position.get_child_count() == 0:
		rival_car_data = [] # Car data is supposed to contain data such as performance and visual upgrades
							# At the moment, there is no way to track this data for cars other than player owned cars
							# Revisit later
		var random_car_key = CarsData.get_all_cars().keys()[randi() % number_of_cars]
		rival_general_car_data = CarsData.get_car(random_car_key)
	
		var scene = load(rival_general_car_data["scene_path"])
		var instance = scene.instantiate()
	
		# Randomize car color
		var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
		var mesh : MeshInstance3D = null
		for child in instance.get_children():
			if child is MeshInstance3D:
				mesh = child
		if mesh != null && material != null:
			material.albedo_color = Color(randf(), randf(), randf(), 1)
			mesh.set_surface_override_material(0, material)
		
		rival_car = instance
		rival_car_position.add_child(rival_car)
	
		## Add wheels to the car model
		var wheel_model = load("res://cars/wheels/"+rival_general_car_data["default_wheels"]+"/"+rival_general_car_data["default_wheels"]+".glb").instantiate()
		for child in instance.get_children():
			if child.name == "WheelPositions":
				for wheel_position in child.get_children():
					wheel_position.add_child(wheel_model.duplicate())
				break
		
		rival_car_wheels = rival_car.get_wheels()
		
		rival_shift_point = randf_range(rival_general_car_data["peak_hp_rpm"], rival_general_car_data["max_rpm"]-100)
		rival_reaction_time = randf_range(0.3, 0.6) # Time that will pass before the rival will start moving
		reaction_timer.wait_time = rival_reaction_time

func give_rewards():
	PlayerStats.get_car(PlayerStats.get_active_car())["wins"] += 1
	var rep_reward : int = 250
	PlayerStats.add_rep(rep_reward)
	var rewards_string : String = "Rewards: %d Rep" % [rep_reward]
	ui.update_labels()
	ui.rewards_label.text = rewards_string

func fire_nitrous_player():
	ui.hide_nitrous_button()
	is_nitrous_active = true
	print_debug("Nitro duration: " + str(player_nitrous_duration) + " - Power" + str(player_nitrous_power) )

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
