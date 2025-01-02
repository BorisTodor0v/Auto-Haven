extends Node3D

# Cameras
@export var race_camera : Camera3D
@export var camera_tracker : Node3D
@onready var camera_tracker_initial_position

@export var player_car_position : Node3D
var player_car : Car
var player_car_data
var player_general_car_data

@export var rival_car_position : Node3D
var rival_car : Car
var rival_car_data
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
@export var reaction_timer : Timer
@export var race_ui : Control

enum RaceStates {
	NONE,
	LAUNCH,
	RUN
}

var race_state : RaceStates = RaceStates.NONE
@export var race_countdown_timer : Timer

@export var wager : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	camera_tracker_initial_position = camera_tracker.global_position
	race_ui.connect("race_confirmed", confirm_race)
	race_ui.connect("launch", launch)
	race_ui.connect("shift_gear", shift_gear)
	race_ui.connect("run_finished", reset_cars)
	race_ui.update_labels()

	pass # Replace with function body.

func _process(delta):
	if race_state == RaceStates.LAUNCH:
		if race_countdown_timer.is_stopped():
			race_ui.set_countdown_label_text("GO")
			player_reaction_time += delta
		else:
			race_ui.set_countdown_label_text(str("%.3f" % race_countdown_timer.time_left))
	elif race_state == RaceStates.RUN:
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
		race_ui.set_race_labels(current_gear, current_velocity, race_time)

func set_player_car(player_car_id : int):
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
	
	## Add headlights to car
	for child in instance.get_children():
		if child is MeshInstance3D:
			var headlight : SpotLight3D = SpotLight3D.new()
			headlight.spot_range = 30
			headlight.spot_angle = 30
			headlight.light_energy = 2
			headlight.position = Vector3(0, 1, 2.2)
			headlight.rotate_x(deg_to_rad(-19.4))
			headlight.rotate_y(deg_to_rad(180))
			child.add_child(headlight)
			break

	if player_car_data["upgrades"]["nitrous"] == 0:
		race_ui.hide_nitrous_components()
	else:
		race_ui.show_nitrous_components()
	
	race_ui.set_redline(player_car_data["performance_data"]["redline"])

func set_rival_car(rival_data : Dictionary):
	if rival_car_position.get_child_count() > 0:
		rival_car_position.get_child(0).queue_free()
	rival_general_car_data = rival_data["car_data"]
	
	var scene = load(rival_general_car_data["scene_path"])
	var instance = scene.instantiate()
	rival_car = instance
	rival_car_position.add_child(rival_car)

	## Set car color
	var material : StandardMaterial3D = load("res://resources/shaders/car_base_color.tres").duplicate()
	var mesh : MeshInstance3D = null
	for child in instance.get_children():
		if child is MeshInstance3D:
			mesh = child
	if mesh != null && material != null:
		material.albedo_color = rival_data["color"]
		mesh.set_surface_override_material(0, material)

	## Add headlights to car
	for child in instance.get_children():
		if child is MeshInstance3D:
			var headlight : SpotLight3D = SpotLight3D.new()
			headlight.spot_range = 30
			headlight.spot_angle = 30
			headlight.light_energy = 2
			headlight.position = Vector3(0, 1, 2.2)
			headlight.rotate_x(deg_to_rad(-19.4))
			headlight.rotate_y(deg_to_rad(180))
			child.add_child(headlight)
			break

	## Add wheels to car model
	var wheel_model = load("res://cars/wheels/"+rival_general_car_data["default_wheels"]+"/"+rival_general_car_data["default_wheels"]+".glb").instantiate()
	for child in instance.get_children():
		if child.name == "WheelPositions":
			for wheel_position in child.get_children():
				wheel_position.add_child(wheel_model.duplicate())
			break

	rival_shift_point = randf_range(rival_general_car_data["peak_hp_rpm"], rival_general_car_data["max_rpm"]-100)
	rival_reaction_time = randf_range(0.25, 0.4) # Time that will pass before the rival will start moving
	reaction_timer.wait_time = rival_reaction_time

func confirm_race():
	start_race_countdown()

func start_race_countdown():
	race_countdown_timer.start()
	race_state = RaceStates.LAUNCH

func _on_race_start_countdown_timer_timeout():
	race_state = RaceStates.RUN
	reaction_timer.start()

func _on_rival_driver_reaction_time_timer_timeout():
	rival_crossed_line = false # Rival starts moving

func launch():
	if race_state == RaceStates.RUN:
		player_reaction_time = race_time
		player_crossed_line = false
		race_ui.show_upshift_button()
		race_ui.show_race_screen()
	else: # False start, stop the race
		show_post_race_screen("dsq")
		race_ui.rewards_label.text = "Don't jump the gun next time"
		reset_cars()
		PlayerStats.remove_cash(wager)

func accelerate_player_car(delta):
	if current_rpm < player_car_data["performance_data"]["max_rpm"] && current_velocity < player_car_data["performance_data"]["top_speed_mps"]:
		current_rpm = current_velocity / player_car_data["performance_data"]["top_speed_for_gear"][current_gear - 1] * player_car_data["performance_data"]["max_rpm"]
		current_velocity += player_car_data["performance_data"]["acceleration_rate_for_gear"][current_gear - 1] * delta
	race_ui.set_rpm(current_rpm)
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

func shift_gear():
	if current_gear < player_car_data["performance_data"]["gears"]:
			player_car.play_gearshift_animation()
			current_gear += 1
			if current_gear == player_car_data["performance_data"]["gears"]:
				race_ui.hide_upshift_button()
			
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
	if race_state == RaceStates.RUN:
		if player_crossed_line && rival_crossed_line == false:
			show_post_race_screen("win")
			# TODO: Increment win counter for the player car
			give_rewards()
		elif player_crossed_line && rival_crossed_line:
			if player_time < rival_time:
				show_post_race_screen("win")
				# TODO: Increment win counter for the player car
				#give_rewards()
			else:
				show_post_race_screen("loss")
				PlayerStats.remove_cash(wager)
				race_ui.rewards_label.text = "Better luck next time..."
				# TODO: Increment loss counter for the player car
		race_ui.update_labels()
	
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
	
	rival_reaction_time = 0
	rival_time = 0
	rival_rpm = 0
	rival_gear = 1
	rival_velocity = 0
	
	race_ui.show_upshift_button()

func show_post_race_screen(finish_type : String):
	var run_stats = {
		"reaction_time" : player_reaction_time,
		"player_run_time": player_time - player_reaction_time,
		"total_time": player_time,
		"rival_reaction_time": rival_reaction_time,
		"rival_run_time": rival_time - rival_reaction_time,
		"rival_total_time": rival_time
	}
	race_ui.show_post_race_screen(finish_type, run_stats)

func give_rewards():
	var rep_reward : int = 100
	PlayerStats.add_rep(rep_reward)
	PlayerStats.add_cash(wager)
	var rewards_string : String = "Rewards: $%d, %d Rep" % [wager, rep_reward]
	wager = 0 # Reset for next race
	var rng : float = randf_range(0, 1) # random_number_generator
	# 50% chance to get an upgrade part
	if rng >= 0.5:
		if rng >= 0.5 && rng < 0.7: # Parts from 1 category
			var parts_categories : Array[String] = ["engine", "weight", "nitrous", "transmission"]
			var parts_category_index : int = randi_range(0, 3)
			var parts_amount : int = randi_range(1, 20)
			rewards_string+= ", %d %s parts" % [parts_amount, parts_categories[parts_category_index]]
			PlayerStats.add_upgrade_parts(parts_categories[parts_category_index], parts_amount)
		elif rng >= 0.7 && rng < 0.85: # Parts from 2 categories
			for i in 2:
				var parts_categories : Array[String] = ["engine", "weight", "nitrous", "transmission"]
				var parts_category_index : int = randi_range(0, 3)
				var parts_amount : int = randi_range(1, 20)
				rewards_string+= ", %d %s parts" % [parts_amount, parts_categories[parts_category_index]]
				PlayerStats.add_upgrade_parts(parts_categories[parts_category_index], parts_amount)
		elif rng >= 0.85 && rng < 0.925: # Parts from 3 categories
			for i in 3:
				var parts_categories : Array[String] = ["engine", "weight", "nitrous", "transmission"]
				var parts_category_index : int = randi_range(0, 3)
				var parts_amount : int = randi_range(1, 20)
				rewards_string+= ", %d %s parts" % [parts_amount, parts_categories[parts_category_index]]
				PlayerStats.add_upgrade_parts(parts_categories[parts_category_index], parts_amount)
		else: # Parts from all 4 categories
			for i in 4:
				var parts_categories : Array[String] = ["engine", "weight", "nitrous", "transmission"]
				var parts_category_index : int = i
				var parts_amount : int = randi_range(1, 20)
				rewards_string+= ", %d %s parts" % [parts_amount, parts_categories[parts_category_index]]
				PlayerStats.add_upgrade_parts(parts_categories[parts_category_index], parts_amount)
	else: # 50% chance to NOT get an upgrade part, better luck next time
		pass
	race_ui.rewards_label.text = rewards_string
	race_ui.update_labels()
