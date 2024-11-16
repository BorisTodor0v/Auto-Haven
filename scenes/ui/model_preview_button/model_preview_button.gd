extends Button

@onready var name_label : Label = $VBoxContainer/NameLabel
@onready var preview_texture = $VBoxContainer/PreviewTextureMargins/SubViewportTexture
@onready var price_label : Label = $VBoxContainer/PriceLabel
@onready var sub_viewport : SubViewport = $SubViewport

var preview_scene = preload("res://cars/car_preview_scene/car_preview.tscn")

var car_key : String

func assign_car(car_id : int):
	var player_car_data = PlayerStats.get_car(car_id)
	var general_car_data = CarsData.get_car(player_car_data["model"])
	var preview_scene_instance = preview_scene.instantiate()
	preview_scene_instance.set_car(general_car_data)
	sub_viewport.add_child(preview_scene_instance)
	set_labels(general_car_data["name"], general_car_data["price"])

func set_labels(name : String, price : int) -> void:
	name_label.text = name
	price_label.text = ""
