extends UI

@onready var base_ui : UI = $BaseUI
@onready var garage_managament_menu : UI = $GarageManagamentMenu
@onready var travel_locations_menu : Control = $TravelLocationsList
var active_menu = "base_ui"

signal hire_mechanic
signal expand_garage
signal open_menu(menu_name : String)
signal travel_to_location(location_name : String)
signal on_garage_submenu_item_pressed(item_type : String, item)
signal garage_submenu_closed
signal edit_mode_enabled(state : bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	## Instead of changing the menu from the "change_active_menu" function in this script, a signal is
	## passed to the base scene to run a check if the game is ready to change the menu. For example:
	## If the player leaves the garage managament menu while expanding the garage, the tiles that can 
	## be unlocked will always be displayed, which should not happen outside of the managament menu.
	base_ui.connect("open_menu", open_menu.emit)
	base_ui.connect("travel_button_pressed", show_travel_locations)
	## Same comment as above (line 16)
	garage_managament_menu.connect("open_menu", open_menu.emit)
	garage_managament_menu.connect("hire_mechanic", hire_mechanic.emit)
	garage_managament_menu.connect("expand_garage", expand_garage.emit)
	garage_managament_menu.connect("on_submenu_item_pressed", on_garage_submenu_item_pressed.emit)
	garage_managament_menu.connect("submenu_closed", garage_submenu_closed.emit)
	## TODO: If no additional checks are needed for the signal, pass it directly in the connect function
	garage_managament_menu.connect("edit_mode_enabled", set_edit_mode)
	travel_locations_menu.connect("travel_to_location", travel_to_location.emit)

func change_active_menu(menu_name : String):
	match menu_name:
		"garage_managament_menu":
			base_ui.hide()
			garage_managament_menu.show()
			active_menu = "garage_managament_menu"
		"base_ui":
			base_ui.show()
			garage_managament_menu.hide()
			active_menu = "base_ui"
		_:
			print_debug("Invalid menu name")

func update_labels():
	base_ui.update_labels()
	garage_managament_menu.update_labels()

func show_message(text : String, duration : float):
	match active_menu:
		"base_ui":
			base_ui.show_message(text, duration)
		"garage_managament_menu":
			garage_managament_menu.show_message(text, duration)
		_:
			print_debug("Invalid menu")

func show_travel_locations():
	travel_locations_menu.show()

func update_submenu_list():
	garage_managament_menu.update_submenu_list()

func set_edit_mode(state : bool):
	## TODO: Check if additional checks are needed for each state
	edit_mode_enabled.emit(state)