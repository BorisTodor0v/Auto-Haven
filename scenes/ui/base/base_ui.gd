extends UI

@onready var cash_label : Label = $MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/VBoxContainer2/Cash/Label
@onready var rep_label : Label = $MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/LevelGauge/Rep/Label
@onready var mechanics_label : Label = $MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/VBoxContainer2/Mechanics/Label

@onready var message = $MarginContainer/VBoxContainer/Bottom/VBoxContainer/MessageContainer/MessageBackground
@onready var message_timer : Timer = $Timers/MessageTimer
@onready var message_label : Label = $MarginContainer/VBoxContainer/Bottom/VBoxContainer/MessageContainer/MessageBackground/MessageLabel

signal open_menu(menu_name : String)
signal travel_button_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	message.hide()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_labels():
	cash_label.text = "Cash: $%3d" % PlayerStats.get_cash()
	rep_label.text = "Rep: %3d" % PlayerStats.get_rep()
	mechanics_label.text = "Mechanics: " + str(PlayerStats.get_available_mechanics()) + "/" + str(PlayerStats.get_total_mechanics())

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
