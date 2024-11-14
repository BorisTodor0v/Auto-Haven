extends Button

@onready var car_name_label : Label = $VBoxContainer/CarNameLabel
@onready var car_preview = $VBoxContainer/PreviewTextureMargins/CarPreviewTexture
@onready var car_price_label : Label = $VBoxContainer/CarPriceLabel
@onready var sub_viewport : SubViewport = $SubViewport

var preview_scene = preload("res://cars/car_preview_scene/car_preview.tscn")

var car_key : String

func assign_car(key : String):
	car_key = key
	var car_data = CarsData.get_car(key)
	var preview_scene_instance = preview_scene.instantiate()
	preview_scene_instance.set_car(car_data)
	sub_viewport.add_child(preview_scene_instance)
	set_labels(car_data["name"], car_data["price"])

func set_labels(car_name : String, car_price : int) -> void:
	car_name_label.text = car_name
	car_price_label.text = "$%d" % car_price
