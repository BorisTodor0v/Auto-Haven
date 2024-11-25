extends UI

@onready var car_name_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Top/ManufactureModelLabel
@onready var top_speed_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/MarginContainer2/Panel/MarginContainer/VBoxContainer/TopSpeedLabel
@onready var acceleration_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/MarginContainer2/Panel/MarginContainer/VBoxContainer/AccelerationLabel
@onready var set_active_car_button : Button = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CarPreview/VBoxContainer/SetActiveCarButton

var current_car_id : int
var general_car_data
var player_car_data
var acceleration : float = 0

signal open_menu(menu_name : String)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func assign_car(car_id : int):
	current_car_id = car_id
	player_car_data = PlayerStats.get_car(car_id)
	general_car_data = CarsData.get_car(player_car_data["model"])
	# Car name & manufacturer
	car_name_label.text = general_car_data["manufacturer"] + " " + general_car_data["name"]
	# Top Speed label
	top_speed_label.text = "Top speed: %d KM/H" % (general_car_data["top_speed_mps"] * 3.6)
	# Acceleration label
	acceleration = 0
	for i in general_car_data["acceleration_rate_for_gear"]:
		## TODO: Factor in installed upgrades to the acceleration value
		acceleration += i
	acceleration /= general_car_data["acceleration_rate_for_gear"].size()
	acceleration_label.text = "Acceleration: %.2f" % acceleration
	# Set active car button
	set_active_car_button_state(car_id)

func _on_close_button_pressed():
	open_menu.emit("base_ui")

func set_active_car_button_state(car_id : int):
	if car_id != PlayerStats.get_active_car(): # Current car is not selected as active
		set_active_car_button.text = "Set as active car"
		set_active_car_button.disabled = false
	else: # Current car is selected as active
		set_active_car_button.text = "Car is currently active"
		set_active_car_button.disabled = true

func _on_set_active_car_button_pressed():
	PlayerStats.set_active_car(current_car_id)
	set_active_car_button_state(current_car_id)
