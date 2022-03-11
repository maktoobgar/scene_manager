extends MarginContainer

onready var Menu: Dictionary = get_node("VBoxContainer/HBoxContainer/container/list").menu_data

func change_scene(key: String) -> void:
	if Menu.has(key):
		get_tree().change_scene(Menu[key])
