extends UI

@onready var cash_label : Label = $RaceTypeSelect/MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/VBoxContainer2/Cash/Label
@onready var rep_label : Label = $RaceTypeSelect/MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/LevelGauge/Rep/Label

# Race type selection
@onready var race_select : Control = $RaceTypeSelect

# Confirm race selection
@onready var confirm_race_screen : Control = $ConfirmRace
@onready var test_run_confirm_screen : Control = $ConfirmRace/TestRun
@onready var versus_run_confirm_screen : Control = $ConfirmRace/VersusRun
signal race_confirmed

# Launch / Countdown
@onready var launch_screen : Control = $Launch

# Race UI
@onready var race_screen : Control = $Race

# Post Race Debrief
@onready var post_race_screen : Control = $PostRace
signal run_finished

signal leave_location

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_labels():
	cash_label.text = "Cash: $%d" % PlayerStats.get_cash()
	rep_label.text = "Rep: %d" % PlayerStats.get_rep()

func _on_return_to_garage_button_pressed():
	leave_location.emit()

func _on_test_run_button_pressed():
	show_confirm_race_screen("test_run")

func _on_versus_run_button_pressed():
	print_debug("To be implemented: Opponent generation + Driving mechanics")

func show_confirm_race_screen(race_type : String):
	match race_type:
		"test_run":
			confirm_race_screen.show()
			test_run_confirm_screen.show()
		"versus_run":
			confirm_race_screen.show()
			versus_run_confirm_screen.show()
		_:
			print_debug("Invalid race type")

func _on_cancel_run_button_pressed():
	confirm_race_screen.hide()
	test_run_confirm_screen.hide()
	versus_run_confirm_screen.hide()
	race_select.show()

func _on_start_test_run_button_pressed():
	race_select.hide()
	test_run_confirm_screen.hide()
	confirm_race_screen.hide()
	launch_screen.show()
	race_confirmed.emit()

func _on_launch_button_pressed():
	launch_screen.hide()
	race_screen.show()

func _on_shift_gear_button_pressed():
	race_screen.hide()
	post_race_screen.show()

func _on_end_run_button_pressed():
	post_race_screen.hide()
	race_select.show()
	run_finished.emit()
