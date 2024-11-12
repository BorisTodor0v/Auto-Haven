extends UI

@onready var base_ui : UI = $BaseUI
@onready var garage_managament_menu : UI = $GarageManagamentMenu
var active_menu = "base_ui"

signal hire_mechanic

# Called when the node enters the scene tree for the first time.
func _ready():
	base_ui.connect("open_menu", change_active_menu)
	garage_managament_menu.connect("open_menu", change_active_menu)
	garage_managament_menu.connect("hire_mechanic", pass_hire_mechanic_signal)

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
	
func pass_hire_mechanic_signal():
	hire_mechanic.emit()
