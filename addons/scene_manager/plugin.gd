@tool
extends EditorPlugin

var menu: Node

const SETTINGS_PROPERTY_NAME := "scene_manager/scenes_path"
const DEFAULT_PATH_TO_SCENES := "res://addons/scene_manager/scenes.gd"
	
# Plugin installation
func _enter_tree():
	
	var path_to_scenes = DEFAULT_PATH_TO_SCENES
	
	# Adding settings property to Project/Settings & loading
	if !ProjectSettings.has_setting(SETTINGS_PROPERTY_NAME):
		ProjectSettings.set_setting(SETTINGS_PROPERTY_NAME, DEFAULT_PATH_TO_SCENES)
		var property_info = {
			"name": SETTINGS_PROPERTY_NAME,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "scenes.gd"
		}
		ProjectSettings.add_property_info(property_info)
		
		ProjectSettings.set_initial_value(SETTINGS_PROPERTY_NAME, DEFAULT_PATH_TO_SCENES)
		ProjectSettings.set_as_basic(SETTINGS_PROPERTY_NAME, true)
		
		# Restart is required as path to Scenes singleton has changed
		ProjectSettings.set_restart_if_changed(SETTINGS_PROPERTY_NAME, true)
		
		ProjectSettings.save()
	else:
		path_to_scenes = ProjectSettings.get_setting(SETTINGS_PROPERTY_NAME)
	
	add_autoload_singleton("SceneManager", "res://addons/scene_manager/scene_manager.tscn")
	add_autoload_singleton("Scenes", path_to_scenes)
	menu = preload("res://addons/scene_manager/menu.tscn").instantiate()
	menu.name = "Scene Manager"

	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, menu)

# Plugin uninstallation
func _exit_tree():
	
 #TBD: find a way to remove Project's Settings Property. Not sure if it's possible right now
#	ProjectSettings.set_setting(SETTINGS_PROPERTY_NAME, null) 
	
	remove_autoload_singleton("SceneManager")
	remove_autoload_singleton("Scenes")
	remove_control_from_docks(menu)
	menu.free()
