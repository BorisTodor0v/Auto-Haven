extends UI

@onready var base_ui : UI = $BaseUI
@onready var garage_managament_menu : UI = $GarageManagamentMenu
var active_menu = "base_ui"

signal hire_mechanic
signal expand_garage
signal open_menu(menu_name : String)

# Called when the node enters the scene tree for the first time.
func _ready():
	base_ui.connect("open_menu", pass_open_menu_signal)
	garage_managament_menu.connect("open_menu", pass_open_menu_signal)
	garage_managament_menu.connect("hire_mechanic", pass_hire_mechanic_signal)
	garage_managament_menu.connect("expand_garage", pass_expand_garage_signal)

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

## Instead of changing the menu from the "change_active_menu" function in this script, a signal is
## passed to the base scene to run a check if the game is ready to change the menu. For example:
## If the player leaves the garage managament menu while expanding the garage, the tiles that can 
## be unlocked will always be displayed, which should not happen outside of the managament menu.
func pass_open_menu_signal(menu_name : String):
	open_menu.emit(menu_name)

func pass_hire_mechanic_signal():
	hire_mechanic.emit()

func pass_expand_garage_signal():
	expand_garage.emit()
