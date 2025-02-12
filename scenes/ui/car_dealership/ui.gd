extends UI

@onready var cash_label : Label = $MarginContainer/VBoxContainer/Top/PlayerCashLabel
@onready var dealership_cars_container : HBoxContainer = $MarginContainer/VBoxContainer/DealershipCars/ScrollContainer/Panel/MarginContainer/CarsContainer
@onready var message : Label = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Center/MessageLabel
@onready var message_timer : Timer = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Center/MessageLabel/Timer

@onready var manufacturer_label : Label = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Left/MarginContainer/VBoxContainer/ManufacturerLabel
@onready var car_name_label : Label = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Left/MarginContainer/VBoxContainer/NameLabel
@onready var top_speed_label : Label = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Left/MarginContainer/VBoxContainer/TopSpeedLabel
@onready var acceleration_label : Label = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Left/MarginContainer/VBoxContainer/AccelerationLabel
@onready var price_label : Label = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Left/MarginContainer/VBoxContainer/PriceLabel
@onready var color_picker : ColorPickerButton = $MarginContainer/VBoxContainer/CarStats/HBoxContainer/Left/MarginContainer/VBoxContainer/CarColor/CarColorPickerButton

var car_button = preload("res://scenes/ui/car_dealership/dealership_car_button/dealership_car_button.tscn")
var current_car_key : String

signal selected_car(car_key : String)
signal leave_location
signal player_bought_car(car_key : String)
signal color_changed(color : Color)

# Called when the node enters the scene tree for the first time.
func _ready():
	update_labels()
	list_cars()

func _on_leave_location_button_pressed():
	leave_location.emit()

func update_labels():
	cash_label.text = "Cash: $%d" % PlayerStats.get_cash()

func show_message(text : String, duration : float):
	message_timer.wait_time = duration
	message.show()
	message.text = text
	message_timer.start()

func clear_message():
	message.text = ""
	message.hide()

func list_cars():
	for car in CarsData.get_all_cars():
		if CarsData.get_car(car)["can_buy_in_dealership"] == true:
			var button_instance = car_button.instantiate()
			button_instance.connect("ready", assign_car_to_button.bind(button_instance, car))
			button_instance.connect("pressed", _on_car_list_item_pressed.bind(car))
			dealership_cars_container.add_child(button_instance)

func assign_car_to_button(button, car : String):
	button.assign_car(car)

func _on_car_list_item_pressed(car_key : String):
	selected_car.emit(car_key)

func display_car_stats(car_key : String):
	current_car_key = car_key
	var car_data : Dictionary = CarsData.get_car(car_key)
	
	var acceleration : float = 0
	
	for i in car_data["acceleration_rate_for_gear"]:
		acceleration += i
	
	acceleration /= car_data["acceleration_rate_for_gear"].size()
	
	manufacturer_label.text = car_data["manufacturer"]
	car_name_label.text = car_data["name"]
	top_speed_label.text = "Top speed: %d KM/H" % (car_data["top_speed_mps"] * 3.6)
	acceleration_label.text = "Acceleration: %.2f" % acceleration
	price_label.text = "Price: $%d" % car_data["price"]

func _on_purchase_car_button_pressed():
	player_bought_car.emit(current_car_key)

func _on_car_color_picker_button_color_changed(color):
	color_changed.emit(color)

func set_car_color_picker_button_color(color : Color):
	color_picker.color = color
