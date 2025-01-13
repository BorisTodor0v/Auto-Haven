extends UI

@export var is_in_other_scene : bool = false

@onready var cash_label : Label = $MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/VBoxContainer2/Cash/Label
@onready var rep_label : Label = $MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/LevelGauge/Rep/Label
@onready var mechanics_label : Label = $MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/VBoxContainer2/Mechanics/Label
@export var fuel_label : Label
@export var fuel_progress_bar : ProgressBar
@export var refuel_progress_bar : ProgressBar
@export var refuel_time_label : Label

@export var buy_fuel_refill_button : Button

@onready var message = $MarginContainer/VBoxContainer/Bottom/VBoxContainer/MessageContainer/MessageBackground
@onready var message_timer : Timer = $Timers/MessageTimer
@onready var message_label : Label = $MarginContainer/VBoxContainer/Bottom/VBoxContainer/MessageContainer/MessageBackground/MessageLabel

signal open_menu(menu_name : String)
signal travel_button_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	fuel_progress_bar.max_value = PlayerStats.max_fuel
	fuel_progress_bar.value = PlayerStats.fuel
	
	refuel_progress_bar.max_value = PlayerStats.refill_one_fuel_unit_time
	refuel_progress_bar.value = 0
	
	if is_in_other_scene:
		$MarginContainer/VBoxContainer/Middle.hide()
		$MarginContainer/VBoxContainer/Bottom.hide()
		var margin : MarginContainer = $MarginContainer
		var margin_value : int = 0
		margin.add_theme_constant_override("margin_top", margin_value)
		margin.add_theme_constant_override("margin_left", margin_value)
		margin.add_theme_constant_override("margin_bottom", margin_value)
		margin.add_theme_constant_override("margin_right", margin_value)
		$MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer2/HBoxContainer/Control2/VBoxContainer/Control/Button.hide()
	message.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_labels()

func update_labels():
	cash_label.text = "Cash: $%3d" % PlayerStats.get_cash()
	rep_label.text = "Rep: %3d" % PlayerStats.get_rep()
	mechanics_label.text = "Mechanics: " + str(PlayerStats.get_available_mechanics()) + "/" + str(PlayerStats.get_total_mechanics())
	fuel_label.text = "Fuel: %d/%d" % [PlayerStats.fuel, PlayerStats.max_fuel]
	fuel_progress_bar.max_value = PlayerStats.max_fuel
	fuel_progress_bar.value = PlayerStats.fuel
	if PlayerStats.fuel < PlayerStats.max_fuel:
		refuel_time_label.text = "Refuel in: %.0f s" % (PlayerStats.refill_one_fuel_unit_time - PlayerStats.fuel_refill_time)
		refuel_progress_bar.value = PlayerStats.fuel_refill_time
		var remaining_fuel : int = PlayerStats.max_fuel - PlayerStats.fuel
		var refuel_cost : int = PlayerStats.buy_one_fuel_unit_cost * remaining_fuel
		buy_fuel_refill_button.text = "Refill fuel\n$%d" % refuel_cost
		if PlayerStats.get_cash() >= refuel_cost:
			buy_fuel_refill_button.disabled = false
		else:
			buy_fuel_refill_button.disabled = true
	else:
		refuel_progress_bar.value = PlayerStats.refill_one_fuel_unit_time
		refuel_time_label.text = "Fuel is topped out"
		buy_fuel_refill_button.text = "Fuel is\nat max"
		buy_fuel_refill_button.disabled = true

func _on_manage_garage_button_pressed():
	open_menu.emit("garage_managament_menu")

func show_message(text : String, duration : float):
	message_timer.wait_time = duration
	message.show()
	message_label.text = text
	message_timer.start()

func clear_message():
	message_label.text = ""
	message.hide()

func _on_travel_button_pressed():
	travel_button_pressed.emit()

func _on_buy_fuel_refill_button_pressed():
	var remaining_fuel : int = PlayerStats.max_fuel - PlayerStats.fuel
	var refuel_cost : int = PlayerStats.buy_one_fuel_unit_cost * remaining_fuel
	if PlayerStats.get_cash() >= refuel_cost:
		PlayerStats.remove_cash(refuel_cost)
		PlayerStats.fuel = PlayerStats.max_fuel	
