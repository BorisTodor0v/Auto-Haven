extends Node

var furniture_items : Dictionary = {}
var walls : Dictionary = {}

## How this dictionary works:
## print(furniture_item) - Key
## print(furniture_data.get(furniture_item)["name"]) - Value "name" from key
## print(furniture_data.get(furniture_item)["price"]) - Value "price" from key

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the furniture items from furniture_items.json
	if FileAccess.file_exists("res://data/furniture_items.json"):
		var furniture_items_file = FileAccess.open("res://data/furniture_items.json", FileAccess.READ)
		var furniture_items_json = JSON.parse_string(furniture_items_file.get_as_text())
		furniture_items_file.close()
		furniture_items = furniture_items_json
	else:
		# Make this a dialog window that pops up and then quits the game
		print_debug("File furniture_items.json in game directory /data not found!")
		get_tree().quit()
	
	# Get the walls from walls.json
	if FileAccess.file_exists("res://data/walls.json"):
		var walls_items_file = FileAccess.open("res://data/walls.json", FileAccess.READ)
		var walls_items_json = JSON.parse_string(walls_items_file.get_as_text())
		walls_items_file.close()
		walls = walls_items_json
	else:
		# Make this a dialog window that pops up and then quits the game
		print_debug("File walls.json in game directory /data not found!")
		get_tree().quit()

func get_furniture_items():
	return furniture_items

func get_values_from_key(key : String):
	return furniture_items.get(key)

func get_walls():
	return walls
