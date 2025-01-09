extends UI
## Base UI components
@export var base_ui : Control
## Racer interaction screen components
@export var racer_interact_screen : Control
@export var racer_data_label : Label
@export var player_cash_label : Label
@export var negotiation_buttons : Control
@export var counter_offer_input : SpinBox
# The accept offer and propose counter-offer button are in a separate array from the decline/cancel
# button because once a negotiation is cancelled, the accept and counter-offer buttons are meant to
# be fully disabled whilst the cancel button needs to be enabled to close the menu.
@export var negotiation_controls : Array[Button]
@export var decline_negotiation_button : Button
@export var start_race_container : Control
@export var wager_negotiation_labels : Array[Label] # \
# Array of Labels indexes:
# 0 - First Racer offer				| First phase of negotiation
# 1 - First Player counter-offer	|
# 2 - Second Racer offer			| Second phase of negotiation
# 3 - Second Player counter-offer	|
# 4 - Third and final Racer offer	| Third phase of negotiation
# 5 - Third and final Player counter-offer	|
# 6 - Negotiations result
@export var current_wager_label : Label
## Race UI components
@export var race_ui : Control
signal run_finished

var negotiation_phase : int = 0
var current_wager : int = 0

signal leave_location
signal begin_race(wager : int)
signal racer_interaction_menu_closed(can_enable_raycast : bool)

func _ready():
	update_labels()
	race_ui.connect("run_finished", run_finished.emit)

func update_labels():
	$BaseUI/VBoxContainer/BaseUI.update_labels()
	player_cash_label.text = "Cash: $%d" % PlayerStats.get_cash()

func _on_leave_location_button_pressed():
	leave_location.emit()

func _on_decline_wager_button_pressed():
	racer_interact_screen.hide()
	negotiation_phase = 0
	base_ui.show()
	racer_interaction_menu_closed.emit(true)

func _on_accept_wager_button_pressed():
	negotiation_buttons.hide()
	start_race_container.show()
	wager_negotiation_labels[6].text = "Deal."

func _on_start_race_button_pressed():
	racer_interact_screen.hide()
	begin_race.emit(current_wager)
	racer_interaction_menu_closed.emit(false)

func _on_propose_counter_offer_button_pressed():
	match negotiation_phase:
		1:
			wager_negotiation_labels[1].text = "Counter-offer: $%d" % counter_offer_input.value
			negotiate_wager(negotiation_phase, counter_offer_input.value, true)
		2:
			wager_negotiation_labels[3].text = "Counter-offer: $%d" % counter_offer_input.value
			negotiate_wager(negotiation_phase, counter_offer_input.value, true)
		3:
			wager_negotiation_labels[5].text = "Counter-offer: $%d" % counter_offer_input.value
			negotiate_wager(negotiation_phase, counter_offer_input.value, true)
		_:
			pass

func show_racer_interact_screen(racer_data : Dictionary):
	## Reset interaction screen to default state
	racer_interact_screen.show()
	update_labels()
	
	for label in wager_negotiation_labels:
		label.text = ""
	
	counter_offer_input.value = counter_offer_input.min_value
	
	for button in negotiation_controls:
		button.disabled = false
	counter_offer_input.editable = true
	decline_negotiation_button.text = "DECLINE"
	
	negotiation_buttons.show()
	start_race_container.hide()
	
	## Fill with new data
	var acceleration : float = 0
	for i in racer_data["car_data"]["acceleration_rate_for_gear"]:
		acceleration += i
	acceleration /= racer_data["car_data"]["acceleration_rate_for_gear"].size()
	
	var display_data : String = \
		"Racer data:
		Car: %s %s
		Top speed: %d
		Max RPM: %d
		Acceleration: %.2f
		Has nitrous: %s
		Rep: %d
		Wins: %d
		Losses: %d
		" % [
			racer_data["car_data"]["manufacturer"],
			racer_data["car_data"]["name"],
			(racer_data["car_data"]["top_speed_mps"]*3.6),
			(racer_data["car_data"]["max_rpm"]),
			acceleration,
			"Yes" if racer_data["upgrades"]["nitrous"] > 0 else "No",
			racer_data["rep"],
			racer_data["wins"],
			racer_data["losses"]
			]
	racer_data_label.text = display_data
	negotiation_phase = 1
	negotiate_wager(negotiation_phase, 0, false)

## Negotiate wager for race. Phases can range from 1 to 3.
## offer = 0 indicates no offer has been made, aka it's the first offer.
## check_offer = true - Player is giving an offer, make the racer consider it
## check_offer = false - Racer is making an offer
func negotiate_wager(phase : int, offer : int, check_offer : bool):
	match negotiation_phase:
		1:
			# Make initial offer
			if offer == 0:
				var initial_wager : int
				if PlayerStats.get_cash() < 1000:
					cancel_negotiations()
					wager_negotiation_labels[6].text = ""
					current_wager_label.text = "Not enough money to wager for a race ($1000 minimum)"
				else:
					if PlayerStats.get_cash() > 10000:
						if PlayerStats.get_cash() > 30000:
							initial_wager = randi_range(5000, 30000)
						else:
							initial_wager = randi_range(5000, PlayerStats.get_cash())
					elif PlayerStats.get_cash() >= 1000:
						initial_wager = randi_range(1000, PlayerStats.get_cash())
					wager_negotiation_labels[0].text = "Initial wager: $%d" % initial_wager
					wager_negotiation_labels[6].text = "Negotiations in progress"
					current_wager = initial_wager
					current_wager_label.text = "Current wager: $%d" % initial_wager
			else: # Consider first player counter-offer
				# TODO: Use a timer to simulate thinking about the offer
				# TODO: Add a label that tells the player that the racer is thinking about the offer (change the current_wager_label.text to dots or "Thinking..."
				if racer_consider_offer(current_wager, offer) == true:
					racer_accept_offer()
					current_wager = offer
				else:
					var new_offer : int = generate_counter_offer(offer)
					negotiation_phase += 1
					negotiate_wager(negotiation_phase, new_offer, false)
		2:
			# Make second offer
			print_debug("Second phase of negotiation")
			if check_offer == false:
				wager_negotiation_labels[2].text = "Next offer: $%d" % offer
				current_wager = offer
				current_wager_label.text = "Current wager: $%d" % offer
			else:
				if racer_consider_offer(current_wager, offer) == true:
					racer_accept_offer()
					current_wager = offer
				else:
					var new_offer : int = generate_counter_offer(offer)
					negotiation_phase += 1
					negotiate_wager(negotiation_phase, new_offer, false)
		3:
			# Make third and final offer
			print_debug("Third phase of negotiation")
			if check_offer == false:
				wager_negotiation_labels[4].text = "Next offer: $%d" % offer
				current_wager = offer
				current_wager_label.text = "Current wager: $%d" % offer
			else:
				if racer_consider_offer(current_wager, offer) == true:
					racer_accept_offer()
				else:
					cancel_negotiations()
		_:
			pass

## True accepts offer, can start racing. False denies offer, makes another offer.
## Currently always false to test messages
func racer_consider_offer(current_wager : int, player_offer : int) -> bool:
	# TODO: Expand logic for accepting/denying counter-offers
	# 2 predicates:
	# Difference between player and racer rep	(Equal, Greater, Lesser)
	# Difference between player and racer offer	(Equal, Greater, Lesser)
	# Player is not making any sensible counter-offer, just repeating the offer given by the racer
	if current_wager == player_offer:
		return true
	else:
		return false

func cancel_negotiations():
	wager_negotiation_labels[6].text = "No deal."
	for button in negotiation_controls:
		button.disabled = true
	counter_offer_input.editable = false
	decline_negotiation_button.text = "CANCEL"

func racer_accept_offer():
	negotiation_buttons.hide()
	start_race_container.show()
	wager_negotiation_labels[6].text = "Deal."

func generate_counter_offer(offer : int) -> int:
	var difference_between_offers : int = abs(offer-current_wager)
	var smaller_offer : int
	if current_wager < offer:
		smaller_offer = current_wager
	else:
		smaller_offer = offer
	return smaller_offer+((difference_between_offers / 2) + (difference_between_offers / 2)*randf_range(.25, .75))

func show_race_ui():
	base_ui.hide()
	racer_interact_screen.hide()
	race_ui.show()

func hide_race_ui():
	base_ui.show()
	race_ui.hide()

func _on_wager_input_value_changed(value):
	if value > PlayerStats.get_cash():
		counter_offer_input.value = PlayerStats.get_cash()
