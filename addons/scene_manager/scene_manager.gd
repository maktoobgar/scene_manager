extends MarginContainer

onready var Menu: Dictionary = get_node("VBoxContainer/ScrollContainer/container/list").menu_data

func validate_key(key: String) -> void:
	assert(
		Menu.has(key) == true,
		"ERROR: `%s` key is not recognized, please double check."% key
	)

func change_scene(key: String) -> void:
	if Menu.has(key):
		get_tree().change_scene(Menu[key])
