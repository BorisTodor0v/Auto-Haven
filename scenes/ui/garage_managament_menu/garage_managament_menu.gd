extends UI

signal open_menu(menu_name : String)
signal hire_mechanic

@onready var cash_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/CashLabel
@onready var rep_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/RepLabel
@onready var mechanics_label : Label = $OptionsScreen/VBoxContainer/Top/HBoxContainer/Control/MarginContainer/Panel/MarginContainer/CenterContainer/VBoxContainer/MechanicsCountLabel

func update_labels():
	cash_label.text = "Cash: $%3d" % PlayerStats.get_cash()
	rep_label.text = "Rep: %3d" % PlayerStats.get_rep()
	mechanics_label.text = "Mechanics: " + str(PlayerStats.get_available_mechanics()) + "/" + str(PlayerStats.get_total_mechanics())

# Back button in base Garage Managament Menu, go back to base UI
func _leave_garage_managament_menu():
	open_menu.emit("base_ui")

func _on_hire_mechanic_button_pressed():
	hire_mechanic.emit()
