extends Control

@onready var locations_list : VBoxContainer = $MarginContainer/Panel/MarginContainer/VBoxContainer/Middle/Locations/List/MarginContainer/ScrollContainer/VBoxContainer
@onready var location_description : RichTextLabel = $MarginContainer/Panel/MarginContainer/VBoxContainer/Middle/Locations/Description/MarginContainer/Panel/MarginContainer/RichTextLabel
@export var location_preview : TextureRect

var selected_location : String = "garage"

signal travel_to_location(location_name : String)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure the list is initially empty
	for list_item in locations_list.get_children():
		list_item.queue_free()
	# Fill with data for locations
	for location in LocationsData.get_locations():
		var button : Button = Button.new()
		button.text = LocationsData.get_location(location)["name"]
		locations_list.add_child(button)
		# Passes the key of the location
		button.connect("pressed", _on_location_list_item_pressed.bind(location))
	_on_location_list_item_pressed(selected_location)

func _on_location_list_item_pressed(_location : String):
	var location = LocationsData.get_location(_location)
	var image_texture = load(location["image_preview_path"]) as Texture2D
	location_preview.set_texture(image_texture)
	selected_location = _location
	location_description.text = location["description"]

func on_cancel_button_pressed():
	self.hide()

func _on_travel_to_location_button_pressed():
	self.hide()
	travel_to_location.emit(selected_location)
