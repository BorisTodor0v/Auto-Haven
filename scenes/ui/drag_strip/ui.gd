extends UI

@onready var cash_label : Label = $RaceTypeSelect/MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/VBoxContainer2/Cash/Label
@onready var rep_label : Label = $RaceTypeSelect/MarginContainer/VBoxContainer/Top/HBoxContainer/HBoxContainer/LevelGauge/Rep/Label

# Race type selection
@onready var race_select : Control = $RaceTypeSelect

# Confirm race selection
@onready var confirm_race_screen : Control = $ConfirmRace
@onready var test_run_confirm_screen : Control = $ConfirmRace/TestRun
@onready var versus_run_confirm_screen : Control = $ConfirmRace/VersusRun
signal race_confirmed(race_type : String)

# Launch / Countdown
@onready var launch_screen : Control = $Launch
@onready var race_start_countdown_label : Label = $Launch/CenterContainer/VBoxContainer/CountdownLabel
signal launch

# Race UI
@onready var race_screen : Control = $Race
@onready var rpm_gauge_redline : TextureProgressBar = $Race/MarginContainer/Control/HBoxContainer/Left/HBoxContainer/Control/RPM/Redline
@onready var rpm_gauge_rpm : TextureProgressBar = $Race/MarginContainer/Control/HBoxContainer/Left/HBoxContainer/Control/RPM

@onready var wager_reminder_label : Label = $Race/MarginContainer/Control/HBoxContainer/Middle/VBoxContainer/WagerLabel
@onready var gear_label : Label = $Race/MarginContainer/Control/HBoxContainer/Right/VBoxContainer/Control/VBoxContainer/Gear/Value
@onready var speed_label : Label = $Race/MarginContainer/Control/HBoxContainer/Right/VBoxContainer/Control/VBoxContainer/Speed/Value
@onready var race_time_label : Label = $Race/MarginContainer/Control/HBoxContainer/Right/VBoxContainer/Control/VBoxContainer/RaceTime/Value

@onready var gearshift_button : Button = $Race/MarginContainer/Control/HBoxContainer/Middle/VBoxContainer/Control2/VBoxContainer/Control2/ShiftGearButton

@onready var nitrous_button : Button = $Race/MarginContainer/Control/HBoxContainer/Middle/VBoxContainer/Control2/VBoxContainer/Control/NOSButton
@onready var nitrous_bar : Control = $Race/MarginContainer/Control/HBoxContainer/Left/HBoxContainer/Nitrous/Bar

signal shift_gear

# Post Race Debrief
@onready var post_race_screen : Control = $PostRace
@onready var result_label : Label = $PostRace/MarginContainer/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResultLabel
@onready var player_reaction_time_label : Label = $PostRace/MarginContainer/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerReactionTimeLabel
@onready var player_run_time_label : Label = $PostRace/MarginContainer/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerRunTimeLabel
@onready var player_total_time_label : Label = $PostRace/MarginContainer/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerTotalTimeLabel
@onready var rival_reaction_time_label : Label = $PostRace/MarginContainer/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OppReactionTime
@onready var rival_run_time_label : Label = $PostRace/MarginContainer/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OppRunTime
@onready var rival_total_time_label : Label = $PostRace/MarginContainer/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OppTotalTime
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
	show_confirm_race_screen("versus_run")

func show_confirm_race_screen(race_type : String):
	match race_type:
		"test_run":
			confirm_race_screen.show()
			versus_run_confirm_screen.hide()
			test_run_confirm_screen.show()
		"versus_run":
			confirm_race_screen.show()
			test_run_confirm_screen.hide()
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
	race_confirmed.emit("test_run")

func _on_start_versus_run_button_pressed():
	race_select.hide()
	test_run_confirm_screen.hide()
	confirm_race_screen.hide()
	launch_screen.show()
	race_confirmed.emit("versus_run")
	print_debug("Start versus run")

func set_countdown_label_text(time : String):
	race_start_countdown_label.text = time

func _on_launch_button_pressed():
	launch.emit()

func show_race_screen():
	launch_screen.hide()
	race_screen.show()

func show_post_race_screen(finish_type : String, run_stats : Dictionary):
	if post_race_screen.visible == false:
		launch_screen.hide()
		race_screen.hide()
		
		if finish_type == "dsq":
			result_label.text = "Disqualified - Jump start"
			rival_reaction_time_label.text = "Rival reaction time: %.3f" % 0
			rival_run_time_label.text = "Rival run time: %.3f" % 0
			rival_total_time_label.text = "Rival total time: %.3f" % 0
		elif finish_type == "win":
			result_label.text = "Victory"
		else:
			result_label.text = "Loss"
		
	player_reaction_time_label.text = "Your reaction time: %.3f" % run_stats["reaction_time"]
	player_run_time_label.text = "Your run time: %.3f" % run_stats["player_run_time"]
	player_total_time_label.text = "Your total time: %.3f" % run_stats["total_time"]
	if finish_type != "dsq":
		rival_reaction_time_label.text = "Rival reaction time: %.3f" % run_stats["rival_reaction_time"]
		rival_run_time_label.text = "Rival run time: %.3f" % run_stats["rival_run_time"]
		rival_total_time_label.text = "Rival total time: %.3f" % run_stats["rival_total_time"]
	
	post_race_screen.show()
	#
	#"reaction_time" : player_reaction_time,
		#"player_run_time": player_time - player_reaction_time,
		#"total_time": player_time,
		#"rival_reaction_time": rival_reaction_time,
		#"rival_run_time": rival_time - rival_reaction_time,
		#"rival_total_time": rival_time

func _on_shift_gear_button_pressed():
	shift_gear.emit()

func _on_end_run_button_pressed():
	post_race_screen.hide()
	race_select.show()
	run_finished.emit()

func set_redline(rpm):
	rpm_gauge_redline.value = 10500 - rpm

func set_rpm(rpm):
	rpm_gauge_rpm.value = rpm

func set_race_labels(gear : int, speed : float, race_time : float):
	gear_label.text = str(gear)
	speed_label.text = "%d KM/H" % (speed * 3.6)
	race_time_label.text = "%.3f" % race_time

func hide_upshift_button():
	gearshift_button.hide()

func show_upshift_button():
	gearshift_button.show()

func hide_nitrous_components():
	nitrous_bar.hide()
	nitrous_button.hide()

func show_nitrous_components():
	nitrous_bar.show()
	nitrous_button.show()

func _on_countdown_timer_timeout():
	print_debug("Timed out")
	pass # Replace with function body.
