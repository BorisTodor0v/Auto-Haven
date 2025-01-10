extends UI

@export var options_grid : Control
@export var color_menu : Control

@onready var back_button : Button = $MarginContainer/Control/MarginContainer/VBoxContainer/Top/Buttons/BackButton

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

var preview_scene = preload("res://cars/car_preview_scene/car_preview.tscn")
@onready var sub_viewport : SubViewport = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CarPreview/SubViewport

# Wheels sub-menu
@export var wheels_menu : Control
@export var wheels_grid_container : GridContainer
var wheel_button = preload("res://scenes/ui/car_interaction_menu/wheel_button/wheel_button.tscn")

# Color sub-menu
var respray_cost : int = 1000
@onready var respray_cost_label : Label = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/ColorPicker/MarginContainer2/MarginContainer/VBoxContainer/ResprayCostLabel
@onready var color_picker : ColorPicker = $MarginContainer/Control/MarginContainer/VBoxContainer/Center/HBoxContainer/CustomizationPart/MarginContainer/VBoxContainer/VBoxContainer/ColorPicker/MarginContainer2/MarginContainer/VBoxContainer/ColorPick/CenterContainer/ColorPicker

var current_car_id : int
var general_car_data
var player_car_data
var acceleration : float = 0

signal open_menu(menu_name : String)
signal upgrade_car(car_id : int, upgrade_type : String)
signal store_car(car_id : int)
signal sell_car(car_id : int)

signal wheels_changed(wheel_name : String)
signal color_changed(color : Color)

# Called when the node enters the scene tree for the first time.
func _ready():
	engine_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("engine"))
	transmission_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("transmission"))
	weight_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("weight"))
	nitrous_upgrade_button.connect("pressed", _on_upgrade_button_pressed.bind("nitrous"))
	
	respray_cost_label.text = "Respray cost: $%d" % respray_cost
	
	fill_wheels_menu()

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
	# Nitrous duration and power label
	var nitrous_duration : float = float(player_car_data["upgrades"]["nitrous"]) / 2
	var nitrous_power : float = 1 + (float(player_car_data["upgrades"]["nitrous"]) / 13.3)
	nitrous_label.text = "Nitrous duration: %.2f sec. | Power: x%.2f" % [nitrous_duration, nitrous_power]
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
		transmission_parts_label.text = "Parts: " + str(PlayerStats.get_upgrade_parts("transmission")) + "/" + str((player_car_data["upgrades"]["transmission"]+1)*10)
	else:
		transmission_upgrade_button.disabled = true
		transmission_parts_label.text = "Maxed out"
	
	if (player_car_data["upgrades"]["weight"]) < 10:
		weight_upgrade_button.disabled = false
		weight_parts_label.text = "Parts: " + str(PlayerStats.get_upgrade_parts("weight")) + "/" + str((player_car_data["upgrades"]["weight"]+1)*10)
	else:
		weight_upgrade_button.disabled = true
		weight_parts_label.text = "Maxed out"
	
	if (player_car_data["upgrades"]["nitrous"]) < 10:
		nitrous_upgrade_button.disabled = false
		nitrous_parts_label.text = "Parts: " + str(PlayerStats.get_upgrade_parts("nitrous")) + "/" + str((player_car_data["upgrades"]["nitrous"]+1)*10)
	else:
		nitrous_upgrade_button.disabled = true
		nitrous_parts_label.text = "Maxed out"
	
	# Color sub-menu
	color_picker.color = player_car_data["color"]
	
	# Preview
	var preview_scene_instance = preview_scene.instantiate()
	preview_scene_instance.set_player_car(player_car_data)
	sub_viewport.remove_child(sub_viewport.get_child(0))
	sub_viewport.add_child(preview_scene_instance)

func close_menu():
	open_menu.emit("base_ui")
	show_submenu("options")
	sub_viewport.remove_child(sub_viewport.get_child(0))

func _on_close_button_pressed():
	close_menu()

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

# TODO: Change the below functions to show a confirmation dialog before actually selling/storing the car
##########################################
func _on_store_car_button_pressed():
	store_car.emit(current_car_id)
	close_menu()

func _on_sell_car_button_pressed():
	sell_car.emit(current_car_id)
	close_menu()
##########################################

func show_submenu(submenu_name : String):
	match submenu_name:
		"options":
			options_grid.show()
			back_button.hide()
			wheels_menu.hide()
			color_menu.hide()
		"wheels":
			options_grid.hide()
			back_button.show()
			wheels_menu.show()
			color_menu.hide()
		"color":
			options_grid.hide()
			back_button.show()
			wheels_menu.hide()
			color_menu.show()
		_:
			pass

func _on_back_button_pressed():
	show_submenu("options")
	assign_car(current_car_id)

func _on_wheels_customization_pressed():
	show_submenu("wheels")

func _on_color_customization_pressed():
	show_submenu("color")

func fill_wheels_menu():
	print_debug(CarsData.get_all_wheels())
	for wheel in CarsData.get_all_wheels():
		var button_instance = wheel_button.instantiate()
		var wheel_price : int = CarsData.wheels[wheel]["price"]
		button_instance.set_wheel(wheel, wheel_price)
		button_instance.connect("purchased_wheel", purchase_wheel)
		wheels_grid_container.add_child(button_instance)

func purchase_wheel(wheel_name : String, price : int):
	if PlayerStats.get_cash() >= price:
		if player_car_data["wheels"] == wheel_name:
			print_debug("Current car already has these wheels installed (%s)" % wheel_name)
		else:
			PlayerStats.change_player_car_property(current_car_id, "wheels", wheel_name)
			PlayerStats.remove_cash(price)
			assign_car(current_car_id)
			wheels_changed.emit(wheel_name)

func _on_confirm_respray_button_pressed():
	if PlayerStats.get_cash() >= respray_cost:
		PlayerStats.change_player_car_property(current_car_id, "color", color_picker.color)
		PlayerStats.remove_cash(respray_cost)
		assign_car(current_car_id)
		color_changed.emit(color_picker.color)
		show_submenu("options")

func _on_color_picker_color_changed(color):
	sub_viewport.get_child(0).change_car_color(color)
