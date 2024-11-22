extends UI

signal open_menu(menu_name : String)
signal hire_mechanic
signal expand_garage
signal on_submenu_item_pressed(item_type : String, item)
signal submenu_closed
signal edit_mode_enabled(state : bool)

@onready var cash_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/CashLabel
@onready var rep_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/RepLabel
@onready var mechanics_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/MechanicsCountLabel
@onready var mechanic_cost_label : Label = $OptionsScreen/VBoxContainer/Menu/Control/ScrollContainer/HBoxContainer/HireMechanic/MarginContainer/Button/MarginContainer/VBoxContainer/Label2
@onready var garage_expansion_cost_label : Label = $OptionsScreen/VBoxContainer/Menu/Control/ScrollContainer/HBoxContainer/ExpandGarage/MarginContainer/Button/MarginContainer/VBoxContainer/Label2

@onready var message_label : Label = $OptionsScreen/VBoxContainer/Middle/MarginContainer/Control/MessageLabel
@onready var message_label_timer : Timer = $Timers/MessageLabelTimer

@onready var base_menu : Control = $OptionsScreen
# Submenus
@onready var car_storage_menu : Control = $SubMenu/CarStorageMenu

func _ready():
	message_label.hide()
	# Submenu signals
	car_storage_menu.connect("menu_closed", hide_submenu)
	car_storage_menu.connect("on_menu_item_pressed", on_submenu_item_pressed.emit)

func update_labels():
	cash_label.text = "Cash: $%d" % PlayerStats.get_cash()
	rep_label.text = "Rep: %d" % PlayerStats.get_rep()
	mechanics_label.text = "Mechanics: " + str(PlayerStats.get_available_mechanics()) + "/" + str(PlayerStats.get_total_mechanics())
	mechanic_cost_label.text = "$%d" % PlayerStats.get_mechanic_cost()
	garage_expansion_cost_label.text = "$%d" % PlayerStats.get_garage_expansion_cost()
	# Update submenu labels
	car_storage_menu.update_labels()

# Back button in base Garage Managament Menu, go back to base UI
func _leave_garage_managament_menu():
	open_menu.emit("base_ui")

func _on_hire_mechanic_button_pressed():
	hire_mechanic.emit()

func show_message(text : String, duration : float):
	message_label_timer.wait_time = duration
	message_label.show()
	message_label.text = text
	message_label_timer.start()
	car_storage_menu.show_message(text, duration)

func clear_message():
	message_label.text = ""
	message_label.hide()

func _on_expand_garage_button_pressed():
	expand_garage.emit()

func _on_car_storage_button_pressed():
	car_storage_menu.show()
	car_storage_menu.show_submenu("car")
	base_menu.hide()

func hide_submenu():
	car_storage_menu.hide()
	edit_mode_enabled.emit(false)
	base_menu.show()
	submenu_closed.emit()

func update_submenu_list():
	car_storage_menu.update_list()

func _on_redecorate_button_pressed():
	car_storage_menu.show()
	car_storage_menu.enable_edit_mode()
	edit_mode_enabled.emit(true)
	base_menu.hide()

func _on_buy_furniture_button_pressed():
	car_storage_menu.show()
	car_storage_menu.show_submenu("furniture")
	base_menu.hide()

func _on_edit_floor_tiles_button_pressed():
	car_storage_menu.show()
	car_storage_menu.show_submenu("floor_tiles")
	base_menu.hide()

func _on_buy_walls_button_pressed():
	car_storage_menu.show()
	car_storage_menu.show_submenu("walls")
	base_menu.hide()
