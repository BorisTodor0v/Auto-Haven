extends UI

@onready var edit_mode_blank_control : Control = $OptionsScreen/VBoxContainer/EditModeBlank
@onready var menu_list_control : Control = $OptionsScreen/VBoxContainer/Menu
@onready var menu_list : HBoxContainer = $OptionsScreen/VBoxContainer/Menu/Control/ScrollContainer/MarginContainer/HBoxContainer

@onready var cash_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/CashLabel
@onready var rep_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/RepLabel
@onready var mechanics_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/MechanicsCountLabel

@onready var preview_button = preload("res://scenes/ui/model_preview_button/model_preview_button.tscn")

@onready var message_label : Label = $OptionsScreen/VBoxContainer/Middle/MarginContainer/Control/MessageLabel
@onready var message_label_timer : Timer = $Timers/MessageLabelTimer

@onready var submenu_label : Label = $OptionsScreen/VBoxContainer/Middle/MarginContainer/Control/Panel/Label

var floor_tiles_mesh_library : MeshLibrary = load("res://scenes/world_locations/garage/garage_tile/floor_tiles_mesh_library.tres")

signal menu_closed
signal on_menu_item_pressed(item_type : String, item)

var edit_mode_enabled : bool = false
## Fill the list in the sub menu with the items from the specific type (cars, furniture etc.)
var current_submenu_items_type : String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	fill_list()

func _on_back_button_pressed():
	if edit_mode_enabled:
		disable_edit_mode()
	menu_closed.emit()
	empty_list()

func update_list():
	empty_list()
	fill_list()

func empty_list():
	for child in menu_list.get_children():
		child.queue_free()

func show_submenu(list_items_type : String):
	current_submenu_items_type = list_items_type
	fill_list()

func fill_list():
	match current_submenu_items_type:
		"car":
			submenu_label.text = "Car Storage"
			for car in PlayerStats.get_owned_cars():
				if PlayerStats.get_car(car)["is_stored"] == true:
					var button_instance = preview_button.instantiate()
					button_instance.connect("ready", button_instance.assign_player_car.bind(car))
					button_instance.connect("pressed", _button_pressed.bind(car))
					menu_list.add_child(button_instance)
		"furniture":
			submenu_label.text = "Buy furniture"
			for furniture_item in FurnitureData.get_furniture_items():
				var furniture_item_data = FurnitureData.get_values_from_key(furniture_item)
				if furniture_item_data["model_path"] != "" and furniture_item_data["scene_path"] != "":
					var button_instance = preview_button.instantiate()
					if furniture_item_data["model_path"] != "":
						button_instance.connect("ready", button_instance.assign_furniture.bind(furniture_item))
					button_instance.connect("pressed", _button_pressed.bind(furniture_item))
					menu_list.add_child(button_instance)
		"floor_tiles":
			submenu_label.text = "Edit floor tiles"
			for floor_tile in floor_tiles_mesh_library.get_item_list():
				var button_instance = preview_button.instantiate()
				button_instance.connect("ready", button_instance.assign_floor_tile.bind(floor_tile))
				button_instance.connect("pressed", _button_pressed.bind(floor_tile))
				menu_list.add_child(button_instance)
		"walls":
			submenu_label.text = "Buy walls"
			for wall in FurnitureData.get_walls():
				var wall_item_data = FurnitureData.walls[wall]
				if wall_item_data["model_path"] != "":
					var button_instance = preview_button.instantiate()
					button_instance.connect("ready", button_instance.assign_wall.bind(wall))
					button_instance.connect("pressed", _button_pressed.bind(wall))
					menu_list.add_child(button_instance)
		_:
			submenu_label.text = "Sub Menu"

func assign_car_to_button(button, car_id : int):
	button.assign_car(car_id)

func _button_pressed(item_id):
	on_menu_item_pressed.emit(current_submenu_items_type, item_id)
	match current_submenu_items_type:
		"car":
			print_debug("Pressed on car: " + str(item_id))
		"furniture":
			print_debug("Pressed on furniture item: " + str(item_id))
		"floor_tiles":
			print_debug("Pressed on floor tile: " + str(item_id))
		"walls":
			print_debug("Pressed on wall")
		_:
			print_debug("Don't know what was pressed..")
	

func update_labels():
	cash_label.text = "Cash: $%d" % PlayerStats.get_cash()
	rep_label.text = "Rep: %d" % PlayerStats.get_rep()
	mechanics_label.text = "Mechanics: " + str(PlayerStats.get_available_mechanics()) + "/" + str(PlayerStats.get_total_mechanics())

func show_message(text : String, duration : float):
	message_label_timer.wait_time = duration
	message_label.show()
	message_label.text = text
	message_label_timer.start()

func enable_edit_mode():
	submenu_label.text = "Redecorating"
	edit_mode_enabled = true
	edit_mode_blank_control.show()
	menu_list_control.hide()
	menu_list.hide()

func disable_edit_mode():
	edit_mode_enabled = false
	edit_mode_blank_control.hide()
	menu_list_control.show()
	menu_list.show()
