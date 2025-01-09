extends UI

# Confirm race
@export var confirm_race_screen : Control
signal race_confirmed

# Launch / Countdown
@export var launch_screen : Control
@export var race_start_countdown_label : Label
signal launch

# Race
@export var race_screen : Control
@export var rpm_gauge_redline : TextureProgressBar
@export var rpm_gauge_rpm : TextureProgressBar
@export var gear_label : Label
@export var speed_label : Label
@export var race_time_label : Label
@export var gearshift_button : Button
@export var nitrous_button : Button
@export var nitrous_bar_holder : Control
@export var nitrous_bar : ProgressBar

signal shift_gear
signal fire_nitrous

# Post race debrief / results
@export var post_race_screen : Control
@export var result_label : Label
@export var player_reaction_time_label : Label
@export var player_run_time_label : Label
@export var player_total_time_label : Label
@export var rival_reaction_time_label : Label
@export var rival_run_time_label : Label
@export var rival_total_time_label : Label
@export var rewards_label : Label
signal run_finished

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_start_run_button_pressed():
	confirm_race_screen.hide()
	launch_screen.show()
	race_confirmed.emit()
	print_debug("Start street race")

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

func _on_shift_gear_button_pressed():
	shift_gear.emit()

func _on_end_run_button_pressed():
	post_race_screen.hide()
	confirm_race_screen.show()
	self.hide()
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
	nitrous_bar_holder.hide()
	nitrous_button.hide()

func show_nitrous_components():
	nitrous_bar_holder.show()
	nitrous_button.show()

func _on_countdown_timer_timeout():
	print_debug("Timed out")
	pass # Replace with function body.

func _on_nos_button_pressed():
	fire_nitrous.emit()

func hide_nitrous_button():
	nitrous_button.hide()

func show_nitrous_button():
	nitrous_button.show()

func set_nitrous_bar_max_value(max_value : float):
	nitrous_bar.max_value = max_value

func set_nitrous_bar_value(value : float):
	nitrous_bar.value = value
