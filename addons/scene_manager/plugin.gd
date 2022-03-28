tool
extends EditorPlugin

var menu: Node

func _enter_tree():
	add_autoload_singleton("SceneManager", "res://addons/scene_manager/scene_manager.tscn")
	add_autoload_singleton("Scenes", "res://addons/scene_manager/scenes.gd")
	menu = preload("res://addons/scene_manager/menu.tscn").instance()
	menu.name = "Scene Manager"

	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, menu)

func _exit_tree():
	remove_autoload_singleton("SceneManager")
	remove_autoload_singleton("Scenes")
	remove_control_from_docks(menu)
	menu.free()
