extends Node3D

@onready var car_holder : Node3D = $CarHolder
@onready var car : Car = $CarHolder.get_child(0)
#@onready var rpm_gauge : Control = $UI/HBoxContainer/RpmGauge

# Car details labels
@onready var name_and_manufacturer_label : Label = $UI/HBoxContainer/CarDetails/VBoxContainer/NameAndManufacturerLabel
@onready var top_speed_ms_label : Label = $UI/HBoxContainer/CarDetails/VBoxContainer/TopSpeedMSLabel
@onready var top_speed_kph_label : Label = $UI/HBoxContainer/CarDetails/VBoxContainer/TopSpeedKPHLabel
@onready var zero_to_100_time_label : Label = $"UI/HBoxContainer/CarDetails/VBoxContainer/0-100TimeLabel"
@onready var gears_label : Label = $UI/HBoxContainer/CarDetails/VBoxContainer/GearsLabel
@onready var redline_label : Label = $UI/HBoxContainer/CarDetails/VBoxContainer/RedlineLabel

var current_rpm : float = 0
var current_velocity : float = 0
var current_gear : int = 1

var is_run_started : bool = false
var run_time_elapsed : float = 0

# Run data segment components
@onready var start_run_button : Button = $UI/HBoxContainer/TestDragRun/VBoxContainer/StartRunButton
@onready var end_run_button : Button = $UI/HBoxContainer/TestDragRun/VBoxContainer/EndRunButton
@onready var up_shift_button : Button = $UI/HBoxContainer/TestDragRun/VBoxContainer/UpShiftButton
@onready var current_rpm_label : Label = $UI/HBoxContainer/TestDragRun/VBoxContainer/CurrentRPMLabel
@onready var current_velocity_mps_label : Label = $UI/HBoxContainer/TestDragRun/VBoxContainer/CurrentSpeedMSLabel
@onready var current_velocity_kmh_label : Label = $UI/HBoxContainer/TestDragRun/VBoxContainer/CurrentSpeedKMHLabel
@onready var current_gear_label : Label = $UI/HBoxContainer/TestDragRun/VBoxContainer/CurrentGearLabel
@onready var run_zero_to_100_time_label : Label = $UI/HBoxContainer/TestDragRun/VBoxContainer/TestZeroTo100TimeLabel

## TODO: Get this data from a car handling singleton
var car_data = {
		"name": "Phoenix",
		"manufacturer": "Liberty Motors",
		"price": 20000,
		"gears": 6,
		"top_speed_for_gear": [24.5435, 34.43281, 44.3889, 54.7222, 64.5913, 68.4444],
		"acceleration_rate_for_gear": [6, 6, 5, 5, 4, 3],
		"top_speed_mps": 68.4444,
		"redline": 7500,
		"max_rpm": 7700,
		"peak_hp_rpm": 7100,
		"scene_path": "res://models/cars/chal/chal.tscn",
	}
var player_car_wheels : Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	## Get the redline from the car
	#rpm_gauge.set_redline(car_data["redline"])
	## TODO: Figure out how to set these values for different cars
	#rpm_gauge.set_good_shift_range(car_data["peak_hp_rpm"]-1000, car_data["peak_hp_rpm"])
	#rpm_gauge.set_perfect_shift_range(car_data["peak_hp_rpm"], car_data["redline"])
	set_car_details(car_data)
	player_car_wheels = car_holder.get_child(0).get_wheels()

func set_car_details(car_data : Dictionary):
	name_and_manufacturer_label.text = car_data["manufacturer"] + " " + car_data["name"]
	top_speed_ms_label.text = "Top speed (m/s): %f" % car_data["top_speed_mps"]
	top_speed_kph_label.text = "Top speed (km/h): %d" % (car_data["top_speed_mps"] * 3.6)
	#zero_to_100_time_label.text = "0-100 kp/h: %d s" % car_data["0-100_seconds"]
	gears_label.text = "Gears: %d" % car_data["gears"]
	redline_label.text = "Redline: %d RPM" % car_data["redline"]
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_run_started:
		accelerate(delta)


func _on_start_run_button_pressed():
	is_run_started = true
	start_run_button.hide()
	end_run_button.show()
	up_shift_button.show()

func _on_end_run_button_pressed():
	is_run_started = false
	start_run_button.show()
	end_run_button.hide()
	up_shift_button.hide()
	
	run_time_elapsed = 0
	
	current_rpm = 0
	current_velocity = 0
	current_gear = 1
	current_gear_label.text = "Current gear: N"

func accelerate(delta):
	run_time_elapsed += delta
	
	if current_rpm < car_data["max_rpm"] && current_velocity < car_data["top_speed_mps"]:
		current_rpm = current_velocity / car_data["top_speed_for_gear"][current_gear - 1] * car_data["max_rpm"]
		current_velocity += car_data["acceleration_rate_for_gear"][current_gear - 1] * delta
		
		var wheel_rotation_angle = current_velocity * delta / (2 * PI * 0.29) * 2 * PI
		if player_car_wheels != null:
			player_car_wheels.get_child(0).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
			player_car_wheels.get_child(1).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
			player_car_wheels.get_child(2).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
			player_car_wheels.get_child(3).rotate_object_local(Vector3(1, 0, 0), wheel_rotation_angle)
		
	
	if current_velocity < 27.7778:
		run_zero_to_100_time_label.text = "0-100 km/h: %.4f" % run_time_elapsed
	
	current_rpm_label.text = "Current RPM: %d" % current_rpm
	#rpm_gauge.set_current_rpm(current_rpm)
	current_velocity_mps_label.text = "Current speed (m/s): %f" % current_velocity
	current_velocity_kmh_label.text = "Current speed (km/h): %d" % (current_velocity * 3.6)
	current_gear_label.text = "Current gear: %d" % current_gear

func _on_up_shift_button_pressed():
	if is_run_started:
		if current_gear < car_data["gears"]:
			car.play_gearshift_animation()
			current_gear += 1
			
			if current_gear == car_data["gears"]:
				up_shift_button.hide()
			
			var previous_gear_top_speed = car_data["top_speed_for_gear"][current_gear - 2]
			var new_gear_top_speed = car_data["top_speed_for_gear"][current_gear - 1]
			current_rpm *= previous_gear_top_speed / new_gear_top_speed
			
