extends UI

@onready var car_name_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Top/ManufactureModelLabel
@onready var top_speed_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/MarginContainer2/Panel/MarginContainer/VBoxContainer/TopSpeedLabel
@onready var acceleration_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/MarginContainer2/Panel/MarginContainer/VBoxContainer/AccelerationLabel
@onready var nitrous_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/MarginContainer2/Panel/MarginContainer/VBoxContainer/NitrousLabel
@onready var win_rate_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/MarginContainer2/Panel/MarginContainer/VBoxContainer/WinRateLabel
@onready var set_active_car_button : Button = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CarPreview/VBoxContainer/SetActiveCarButton

# Upgrade buttons
@onready var engine_upgrade_button : Button = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton
@onready var transmission_upgrade_button : Button = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton2
@onready var weight_upgrade_button : Button = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton4
@onready var nitrous_upgrade_button : Button = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton5

# Labels to show parts required for an upgrade
@onready var engine_level_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton/VBoxContainer/OptionName
@onready var transmission_level_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton2/VBoxContainer/OptionName
@onready var weight_level_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton4/VBoxContainer/OptionName
@onready var nitrous_level_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton5/VBoxContainer/OptionName

@onready var engine_parts_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton/VBoxContainer/Label
@onready var transmission_parts_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton2/VBoxContainer/Label
@onready var weight_parts_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton4/VBoxContainer/Label
@onready var nitrous_parts_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/OptionsGrid/CustomizationOptionButton5/VBoxContainer/Label

var current_car_id : int
var general_car_data
var player_car_data
var acceleration : float = 0

signal open_menu(menu_name : String)
signal upgrade_car(car_id : int, upgrade_type : String)

# Called when the node enters the scene tree for the first time.
func _ready():
	engine_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("engine"))
	transmission_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("transmission"))
	weight_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("weight"))
	nitrous_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("nitrous"))
	
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
	top_speed_label.text = "Top speed: %d KM/H" % (player_car_data["performance_data"]["top_speed_mps"] * 3.6)
	# Acceleration label
	acceleration = 0
	for i in player_car_data["performance_data"]["acceleration_rate_for_gear"]:
		acceleration += i
	acceleration /= player_car_data["performance_data"]["acceleration_rate_for_gear"].size()
	acceleration_label.text = "Acceleration: %.2f" % acceleration
	# TODO: Nitrous duration and power label
	nitrous_label.text = "Nitrous duration: XX.XXX sec. | Power: xXX.XXX"
	# TODO: Race wins and losses label
	win_rate_label.text = "Race stats - Wins: " + str(player_car_data["wins"]) + " | Losses: " + str(player_car_data["losses"])
	# Set active car button
	set_active_car_button_state(car_id)
	# Upgrade levels
	engine_level_label.text = "ENGINE LVL. " + str(player_car_data["upgrades"]["engine"])
	transmission_level_label.text = "TRANSMISSION LVL. " + str(player_car_data["upgrades"]["transmission"])
	weight_level_label.text = "WEIGHT LVL. " + str(player_car_data["upgrades"]["weight"])
	nitrous_level_label.text = "NITROUS LVL. " + str(player_car_data["upgrades"]["nitrous"])
	# Upgrade buttons
	if (player_car_data["upgrades"]["engine"]) < 10:
		engine_upgrade_button.disabled = false
		engine_parts_label.text = "Parts: " + str(PlayerStats.get_upgrade_parts("engine")) + "/" + str((player_car_data["upgrades"]["engine"]+1)*10)
	else:
		engine_upgrade_button.disabled = true
		engine_parts_label.text = "Maxed out"
	
	if (player_car_data["upgrades"]["transmission"]) < 10:
		transmission_upgrade_button.disabled = false
		transmission_parts_label.text = "Parts: " + str(PlayerStats.get_upgrade_parts("engine")) + "/" + str((player_car_data["upgrades"]["transmission"]+1)*10)
	else:
		transmission_upgrade_button.disabled = true
		transmission_parts_label.text = "Maxed out"
	
	if (player_car_data["upgrades"]["weight"]) < 10:
		weight_upgrade_button.disabled = false
		weight_parts_label.text = "Parts: " + str(PlayerStats.get_upgrade_parts("engine")) + "/" + str((player_car_data["upgrades"]["weight"]+1)*10)
	else:
		weight_upgrade_button.disabled = true
		weight_parts_label.text = "Maxed out"
	
	if (player_car_data["upgrades"]["nitrous"]) < 10:
		nitrous_upgrade_button.disabled = false
		nitrous_parts_label.text = "Parts: " + str(PlayerStats.get_upgrade_parts("nitrous")) + "/" + str((player_car_data["upgrades"]["nitrous"]+1)*10)
	else:
		nitrous_upgrade_button.disabled = true
		nitrous_parts_label.text = "Maxed out"
	# Preview
	

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

func _on_upgrade_button_pressed(upgrade_type : String):
	upgrade_car.emit(current_car_id, upgrade_type)
	assign_car(current_car_id)
