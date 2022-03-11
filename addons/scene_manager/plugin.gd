tool
extends EditorPlugin

var menu: Node

func _enter_tree():
	menu = preload("res://addons/scene_manager/menu.tscn").instance()
	menu.name = "Scene Manager"

	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, menu)

func _exit_tree():
	remove_control_from_docks(menu)
	menu.free()
