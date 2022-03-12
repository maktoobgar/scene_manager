extends Node

onready var menu: Dictionary = _load_scenes("res://scenes.json")

func _file_exists(address: String) -> void:
	assert (
		Directory.new().file_exists(address),
		"Error: `%s` file does not exist, please save your scenes by save button in tool gui."% address
	)

func _load_scenes(address: String) -> Dictionary:
	var data: Dictionary = {}

	_file_exists(address)
	var file = File.new()
	file.open(address, File.READ)
	data = parse_json(file.get_var())
	file.close()

	return data

func validate_key(key: String) -> void:
	assert(
		menu.has(key) == true,
		"ERROR: `%s` key is not recognized, please double check."% key
	)

func change_scene(key: String) -> void:
	if menu.has(key):
		get_tree().change_scene(menu[key])
