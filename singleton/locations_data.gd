extends Node
## Location / Scene handler

var locations = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the furniture items from furniture_items.json
	if FileAccess.file_exists("res://data/world_locations.json"):
		var world_locations_file = FileAccess.open("res://data/world_locations.json", FileAccess.READ)
		var world_locations_json = JSON.parse_string(world_locations_file.get_as_text())
		world_locations_file.close()
		locations = world_locations_json
	else:
		# Make this a dialog window that pops up and then quits the game
		print_debug("File world_locations.json in game directory /data not found!")
		get_tree().quit()

func get_locations():
	return locations

func get_location(key : String):
	return locations[key]
