extends Button

@onready var name_label : Label = $VBoxContainer/NameLabel
@onready var preview_texture = $VBoxContainer/PreviewTextureMargins/SubViewportTexture
@onready var price_label : Label = $VBoxContainer/PriceLabel
@onready var sub_viewport : SubViewport = $SubViewport

var floor_tiles_mesh_library : MeshLibrary = load("res://scenes/world_locations/garage/garage_tile/floor_tiles_mesh_library.tres")

var preview_scene = preload("res://cars/car_preview_scene/car_preview.tscn")

var car_key : String

func assign_car(car_id : String):
	var player_car_data = PlayerStats.get_car(car_id)
	var general_car_data = CarsData.get_car(player_car_data["model"])
	var preview_scene_instance = preview_scene.instantiate()
	preview_scene_instance.set_car(general_car_data)
	sub_viewport.add_child(preview_scene_instance)
	set_labels(general_car_data["name"], -1)

func assign_player_car(car_id : String):
	var player_car_data = PlayerStats.get_car(car_id)
	var general_car_data = CarsData.get_car(player_car_data["model"])
	var preview_scene_instance = preview_scene.instantiate()
	preview_scene_instance.set_player_car(player_car_data)
	sub_viewport.add_child(preview_scene_instance)
	set_labels(general_car_data["name"], -1)

func assign_furniture(furniture_id : String):
	var furniture_item_data = FurnitureData.get_values_from_key(furniture_id)
	var preview_scene_instance = preview_scene.instantiate()
	preview_scene_instance.set_model(furniture_item_data["model_path"], furniture_item_data["preview_scale"])
	sub_viewport.add_child(preview_scene_instance)
	set_labels(furniture_item_data["name"], furniture_item_data["price"])

func assign_wall(wall_id : String):
	var wall_data = FurnitureData.walls[wall_id]
	var preview_scene_instance = preview_scene.instantiate()
	preview_scene_instance.set_model(wall_data["model_path"], wall_data["preview_scale"])
	sub_viewport.add_child(preview_scene_instance)
	set_labels(wall_data["name"], wall_data["price"])

func assign_floor_tile(tile_id : int):
	var preview_scene_instance = preview_scene.instantiate()
	var floor_tile_library_mesh : Mesh = floor_tiles_mesh_library.get_item_mesh(tile_id)
	var floor_tile_mesh_instance_3d : MeshInstance3D = MeshInstance3D.new()
	floor_tile_mesh_instance_3d.mesh = floor_tile_library_mesh
	preview_scene_instance.add_child(floor_tile_mesh_instance_3d)
	sub_viewport.add_child(preview_scene_instance)
	set_labels(floor_tiles_mesh_library.get_item_name(tile_id), 50)

func set_labels(item_name : String, price : int) -> void:
	name_label.text = item_name
	if price == -1:
		price_label.text = ""
	else:
		price_label.text = "$%d" % price
