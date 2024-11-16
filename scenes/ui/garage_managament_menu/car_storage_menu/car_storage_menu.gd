extends UI

@onready var menu_list : HBoxContainer = $OptionsScreen/VBoxContainer/Menu/Control/ScrollContainer/MarginContainer/HBoxContainer

@onready var cash_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/CashLabel
@onready var rep_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/RepLabel
@onready var mechanics_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/MechanicsCountLabel

@onready var car_button = preload("res://scenes/ui/model_preview_button/model_preview_button.tscn")

@onready var message_label : Label = $OptionsScreen/VBoxContainer/Middle/MarginContainer/Control/MessageLabel
@onready var message_label_timer : Timer = $Timers/MessageLabelTimer

signal menu_closed
signal on_menu_item_pressed(item_type : String, item)

# Called when the node enters the scene tree for the first time.
func _ready():
	fill_list()

func _on_back_button_pressed():
	menu_closed.emit()
	empty_list()

func update_list():
	empty_list()
	fill_list()

func empty_list():
	for child in menu_list.get_children():
		child.queue_free()

func fill_list():
	for car in PlayerStats.get_owned_cars():
		if PlayerStats.get_car(car)["is_stored"] == true:
			var button_instance = car_button.instantiate()
			button_instance.connect("ready", button_instance.assign_car.bind(car))
			button_instance.connect("pressed", _button_pressed.bind(car))
			menu_list.add_child(button_instance)

func assign_car_to_button(button, car_id : int):
	button.assign_car(car_id)

func _button_pressed(car_id : int):
	on_menu_item_pressed.emit("car", car_id)

func update_labels():
	cash_label.text = "Cash: $%d" % PlayerStats.get_cash()
	rep_label.text = "Rep: %d" % PlayerStats.get_rep()
	mechanics_label.text = "Mechanics: " + str(PlayerStats.get_available_mechanics()) + "/" + str(PlayerStats.get_total_mechanics())

func show_message(text : String, duration : float):
	message_label_timer.wait_time = duration
	message_label.show()
	message_label.text = text
	message_label_timer.start()
