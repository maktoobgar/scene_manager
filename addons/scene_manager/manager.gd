@tool
extends MarginContainer

# Project Settings property name
const SETTINGS_PROPERTY_NAME := "scene_manager/scenes/scenes_path"
# paths
const PATH: String = "res://addons/scene_manager/scenes.gd"
const ROOT_ADDRESS = "res://"
# prefile
const comment: String = "#\n# Please do not edit anything in this script\n#\n# Just use the editor to change everything you want\n#\n"
const extend_part: String = "extends Node\n\n"
const var_part: String = "var scenes: Dictionary = "
# scene item, ignore item
const _ignore_item = preload("res://addons/scene_manager/ignore_item.tscn")
const _scene_list_item = preload("res://addons/scene_manager/scene_list.tscn")
# icons
const _hide_button_checked = preload("res://addons/scene_manager/icons/GuiChecked.svg")
const _hide_button_unchecked = preload("res://addons/scene_manager/icons/GuiCheckedDisabled.svg")
const _folder_button_checked = preload("res://addons/scene_manager/icons/FolderActive.svg")
const _folder_button_unchecked = preload("res://addons/scene_manager/icons/Folder.svg")
@onready var _ignore_list: Node = self.find_child("ignore_list")
# add save, refresh
@onready var _save_button: Button = self.find_child("save")
@onready var _refresh_button: Button = self.find_child("refresh")
@onready var _auto_save_button: Button = self.find_child("auto_save")
@onready var _auto_refresh_button: Button = self.find_child("auto_refresh")
# add list
@onready var _add_subsection_button: Button = self.find_child("add_subsection")
@onready var _add_section_button: Button = self.find_child("add_section")
@onready var _section_name_line_edit: LineEdit = self.find_child("section_name")
# add ignore
@onready var _address_line_edit: LineEdit = self.find_child("address")
@onready var _file_dialog: FileDialog = self.find_child("file_dialog")
@onready var _hide_button: Button = self.find_child("hide")
@onready var _hide_unhide_button: Button = self.find_child("hide_unhide")
@onready var _add_button: Button = self.find_child("add")
# containers
@onready var _tab_container: TabContainer = self.find_child("tab_container")
@onready var _ignores_container: Node = self.find_child("ignores")
@onready var _ignores_panel_container: Node = self.find_child("ignores_panel")
# generals
@onready var _accept_dialog: AcceptDialog = self.find_child("accept_dialog")

# A dictionary which contains every scenes exact addresses as key and an array 
# assigned as values which categories every section name the scene is part of
#
# Example: { "res://demo/scene3.tscn": ["Character", "Menu"] }
var _sections: Dictionary = {}
var reserved_keys: Array = ["back", "null", "ignore", "refresh",
	"reload", "restart", "exit", "quit"]
var _timer: Timer = null;

# When an ignore item remove button clicks
signal ignore_child_deleted(node: Node)
# When rename happens
signal item_renamed(node: Node)
# When item hides or unhides
signal item_visibility_changed(node: Node, visibility: bool)
# When item adds to a list
signal item_added_to_list(node: Node, list_name: String)
# When item deletes from a list
signal item_removed_from_list(node: Node, list_name: String)
# When a sub section is removed
signal sub_section_removed(node: Node)
# When a section is removed
signal section_removed(node: Node)
# When a scene gets added to a sub section
signal added_to_sub_section(node: Node, sub_section: Node)

# Refreshes the whole UI
func _ready() -> void:
	_on_refresh_button_up()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_filesystem_changed)
	self.ignore_child_deleted.connect(_on_ignore_child_deleted)
	self.item_renamed.connect(_on_item_renamed)
	self.item_visibility_changed.connect(_on_item_visibility_changed)
	self.item_added_to_list.connect(_on_added_to_list)
	self.item_removed_from_list.connect(_on_item_removed_from_list)
	self.sub_section_removed.connect(_on_sub_section_removed)
	self.section_removed.connect(_on_section_removed)
	self.added_to_sub_section.connect(_on_added_to_sub_section)

	# Create a new Timer node
	_timer = Timer.new()
	_timer.wait_time = 0.5
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

func _on_added_to_sub_section(node: Node, sub_section: Node) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

func _on_section_removed(node: Node) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

func _on_sub_section_removed(node: Node) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

func _on_timer_timeout() -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

func _on_item_renamed(node: Node) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_timer.wait_time = 0.5
		_timer.start()

func _on_item_visibility_changed(node: Node, visibility: bool) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

func _on_added_to_list(node: Node, list_name: String) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

func _on_item_removed_from_list(node: Node, list_name: String) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

# Gets called by filesystem changes
func _filesystem_changed() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		if _auto_refresh_button.get_meta("enabled", true):
			_on_refresh_button_up()
			await get_tree().process_frame
			if _auto_save_button.get_meta("enabled", false):
				_save_all(_create_save_dic())

# Returns absolute current working directory
func _absolute_current_working_directory() -> String:
	return ProjectSettings.globalize_path(EditorPlugin.new().get_current_directory())

# Merges two dictionaries together
func _merge_dict(dest: Dictionary, source: Dictionary) -> void:
	for key in source:
		if dest.has(key):
			var dest_value = dest[key]
			var source_value = source[key]
			if typeof(dest_value) == TYPE_DICTIONARY:
				if typeof(source_value) == TYPE_DICTIONARY:
					_merge_dict(dest_value, source_value)
				else:
					dest[key] = source_value
			else:
				dest[key] = source_value
		else:
			dest[key] = source[key]

# Returns names of all lists from UI
func get_all_lists_names_except(excepts: Array = [""]) -> Array:
	var arr: Array = []
	for i in range(len(excepts)):
		excepts[i] = excepts[i].capitalize()
	for node in _get_lists_nodes():
		if node.name in excepts:
			continue
		arr.append(node.name)
	return arr

# Returns names of all sublists from UI and active tab
func get_all_sublists_names_except(excepts: Array = [""]) -> Array:
	var section = _tab_container.get_child(_tab_container.current_tab)
	return section.get_all_sublists()

# Shows a dialog message at the middle of screen
func show_message(title: String, description: String) -> void:
	_accept_dialog.title = title
	_accept_dialog.dialog_text = description
	_accept_dialog.popup_centered(Vector2(400, 100))

# Returns all scenes in current and sub folders of `root_path` address
func _get_scenes(root_path: String, ignores: Array) -> Dictionary:
	var files: Dictionary = {}
	var folders: Array = []
	var dir = DirAccess.open(root_path)
	var original_root_path = root_path
	if root_path[len(root_path) - 1] != "/":
		root_path = root_path + "/"
	if !(original_root_path in ignores) && dir:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547

		if dir.file_exists(root_path + ".gdignore"):
			return files
		while true:
			var file_folder = dir.get_next()
			var exact_address = root_path + file_folder
			if file_folder == "":
				break
			elif dir.current_is_dir():
				folders.append(file_folder)
			elif file_folder.get_extension() == "tscn" && !(exact_address in ignores):
				files[file_folder.replace("."+file_folder.get_extension(), "")] = exact_address

		dir.list_dir_end()

		for folder in folders:
			var new_files: Dictionary = _get_scenes(root_path + folder, ignores)
			if len(new_files) != 0:
				_merge_dict(files, new_files)
	else:
		# If `root_path` was really a file and not a folder, we know the reason and
		# propably this is comming from `_on_ignore_child_deleted`, so just add it to list
		if !(original_root_path in ignores):
			if (!FileAccess.file_exists(original_root_path)):
				print ("Couldn't open ", original_root_path)
			else:
				var splits = original_root_path.split("/", false)
				var file = splits[len(splits) - 1]
				if file.get_extension() == "tscn":
					files[file.replace("."+file.get_extension(), "")] = original_root_path

	return files

# Clears scenes inside a UI list
func _clear_scenes_list(name: String) -> void:
	var list: Node = _get_one_list_node_by_name(name)
	if list != null:
		list.clear_list()

# Clears scenes inside all UI lists
func _clear_all_lists() -> void:
	_sections = {}
	for list in _get_lists_nodes():
		list.clear_list()

# Removes all tabs in scene manager
func _delete_all_tabs() -> void:
	for node in _get_lists_nodes():
		node.free()

# Returns nodes of all section lists from UI in `Scene Manager` tool
func _get_lists_nodes() -> Array:
	var arr: Array = []
	for i in range(_tab_container.get_child_count()):
		arr.append(_tab_container.get_child(i))
	return arr

# Returns node of a specific list in UI
func _get_one_list_node_by_name(name: String) -> Node:
	for node in _get_lists_nodes():
		if name.capitalize() == node.name:
			return node
	return null

# Removes a scene from a specific list
func remove_scene_from_list(section_name: String, scene_name: String, scene_address: String) -> void:
	var list: Node = _get_one_list_node_by_name(section_name)
	list.remove_item(scene_name, scene_address)
	_section_remove(scene_address, section_name)

	# Removes and add in `All` section too so that it updates its place in list
	var all_list = _get_one_list_node_by_name("All")
	var setting = all_list.get_node_by_scene_address(scene_address).get_setting()
	all_list.remove_item(scene_name, scene_address)
	setting.categorized = has_sections(scene_address)
	await all_list.add_item(scene_name, scene_address, setting)

# Adds an item to a list
#
# Used mainly in this script
func _add_scene_to_list(list_name: String, scene_name: String, scene_address: String, setting :ItemSetting) -> void:
	var list: Node = _get_one_list_node_by_name(list_name)
	if list == null:
		return
	await list.add_item(scene_name, scene_address, setting)
	_sections_add(scene_address, list_name)

# Adds an item to a list
#
# This function is used in `scene_item.gd` script and plus doing what it is supposed
# to do, removes and again adds the item in `All` section so that it can be placed
# in currect place in currect section
func add_scene_to_list(list_name: String, scene_name: String, scene_address: String, setting :ItemSetting) -> void:
	_add_scene_to_list(list_name, scene_name, scene_address, setting)

	# Removes and add in `All` section too so that it updates its place in list
	var all_list = _get_one_list_node_by_name("All")
	setting = all_list.get_node_by_scene_address(scene_address).get_setting()
	all_list.remove_item(scene_name, scene_address)
	setting.categorized = has_sections(scene_address)
	await all_list.add_item(scene_name, scene_address, setting)

# Adds an address to ignore list
func _add_ignore_item(address: String) -> void:
	var item = _ignore_item.instantiate()
	item.set_address(address)
	_ignore_list.add_child(item)

# Appends all scenes into their assigned UI lists
#
# This function gets called just from `_on_ignore_child_deleted`
func _append_scenes(scenes: Dictionary) -> void:
	_get_one_list_node_by_name("All").append_scenes(scenes)
	for list in _get_lists_nodes():
		if list.name == "All":
			continue
		for key in scenes:
			if list.name in get_sections(scenes[key]):
				await list.add_item(key, scenes[key], ItemSetting.default())

# Clears all tabs, UI lists and ignore list
func _clear_all() -> void:
	_delete_all_tabs()
	_clear_all_lists()
	_clear_ignore_list()

# Reloads all scenes in UI and in this script
func _reload_scenes() -> void:
	var data: Dictionary = _load_scenes()
	var scenes: Dictionary = _get_scenes(ROOT_ADDRESS, _load_ignores())
	var scenes_values: Array = scenes.values()
	# Reloads all scenes in `Scenes` script in UI and in this script
	for key in data:
		var scene = data[key]
		if key == "_auto_refresh":
			_change_auto_refresh_state(scene)
			continue
		if key == "_auto_save":
			_change_auto_save_state(scene)
			continue
		if key == "_ignores_visible":
			_hide_unhide_ignores_list(scene)
			continue
		var keys = scene.keys()
		assert (("value" in keys) && ("sections" in keys), "Scene Manager Error: this format is not supported. Every scene item has to have 'value' and 'sections' field inside them.'")
		if !(scene["value"] in scenes_values):
			continue
		for section in scene["sections"]:
			var setting: ItemSetting = null
			if "settings" in keys && section in scene["settings"].keys():
				setting = ItemSetting.dictionary_to_item_setting(scene["settings"][section])
			else:
				setting = ItemSetting.default()
			_sections_add(scene["value"], section)
			_add_scene_to_list(section, key, scene["value"], setting)
		var setting: ItemSetting = null
		if "settings" in keys && "All" in scene["settings"].keys():
			setting = ItemSetting.dictionary_to_item_setting(scene["settings"]["All"])
		else:
			setting = ItemSetting.default()
		setting.categorized = has_sections(scene["value"])
		_add_scene_to_list("All", key, scene["value"], setting)

	# Add scenes that are new and are not into `Scenes` script
	var data_values: Array = []
	var data_dics = data.values()
	if data:
		for i in range(len(data_dics)):
			if typeof(data_dics[i]) == TYPE_DICTIONARY:
				data_values.append(data_dics[i]["value"])
	for key in scenes:
		if !(scenes[key] in data_values):
			var setting = ItemSetting.default()
			_add_scene_to_list("All", key, scenes[key], setting)

# Reloads ignores list in UI and in this script
func _reload_ignores() -> void:
	var ignores: Array = _load_ignores()
	_set_ignores(ignores)

# Reloads tabs in UI
func _reload_tabs() -> void:
	var sections: Array = _load_sections()
	if _get_one_list_node_by_name("All") == null:
		_add_scene_list("All")
	for section in sections:
		var found = false
		for list in _get_lists_nodes():
			if list.name == section:
				found = true
		if !found:
			_add_scene_list(section)

# Refresh button
func _on_refresh_button_up() -> void:
	_clear_all()
	_reload_tabs()
	_reload_scenes()
	_reload_ignores()

# `_sections` variable Manager

# Adds passed `section_name` to array value of passed `scene_address` key in `_sections` variable
func _sections_add(scene_address: String, section_name: String) -> void:
	if section_name == "All":
		return
	if !_sections.has(scene_address):
		_sections[scene_address] = []
	if !(section_name in _sections[scene_address]):
		_sections[scene_address].append(section_name)

# Removes passed `section_name` from array value of passed `scene_address` key
func _section_remove(scene_address: String, section_name: String) -> void:
	if !_sections.has(scene_address):
		return
	if section_name in _sections[scene_address]:
		_sections[scene_address].erase(section_name)
	if len(_sections[scene_address]) == 0:
		_sections.erase(scene_address)

# Returns all sections of passed `scene_address`
func get_sections(scene_address: String) -> Array:
	if !_sections.has(scene_address):
		return []
	return _sections[scene_address]

# Returns true or false if passed `scene_address` has sections
func has_sections(scene_address: String) -> bool:
	return _sections.keys().has(scene_address) && _sections[scene_address] != []

# Cleans `_sections` variable from `All` section
func _clean_sections() -> void:
	var scenes: Array = get_all_lists_names_except(["All"])
	for key in _sections:
		var will_be_deleted: Array = []
		for section in _sections[key]:
			if !(section in scenes):
				will_be_deleted.append(section)
		for section in will_be_deleted:
			_sections[key].erase(section)

# End Of `_sections` variable Manager

# Gets called by other nodes in UI
#
# Updates name of all scene_key
func update_all_scene_with_key(scene_key: String, scene_new_key: String, value: String, setting: ItemSetting, except_list: Array = []):
	for list in _get_lists_nodes():
		if list not in except_list:
			list.update_scene_with_key(scene_key, scene_new_key, value, setting)

# Checks for duplications in scenes of lists
func check_duplication():
	var list: Array = _get_one_list_node_by_name("All").check_duplication()
	for node in _get_lists_nodes():
		node.set_reset_theme_for_all()
		if list:
			node.set_duplicate_theme(list)

# Removes `_ignore_list` and `_sections` keys from passed dictionary so that 
# just scene names remain in returned dictionary
func _remove_ignore_list_and_sections_from_dic(dic: Dictionary) -> Dictionary:
	dic.erase("_ignore_list")
	dic.erase("_sections")
	return dic

# Saves all data in `scenes` variable of `scenes.gd` file
func _save_all(data: Dictionary) -> void:
	var file := FileAccess.open(ProjectSettings.get_setting(SETTINGS_PROPERTY_NAME, PATH), FileAccess.WRITE)
	var write_data: String = comment + extend_part + var_part + JSON.new().stringify(data) + "\n"
	file.store_string(write_data)

# Returns all data in `scenes` variable of `scenes.gd` file
func _load_all() -> Dictionary:
	var data: Dictionary = {}

	if _file_exists(ProjectSettings.get_setting(SETTINGS_PROPERTY_NAME, PATH)):
		var file := FileAccess.open(ProjectSettings.get_setting(SETTINGS_PROPERTY_NAME, PATH), FileAccess.READ)
		var string: String = file.get_as_text()
		string = string.substr(string.find("var"), len(string)).replace(var_part, "").strip_escapes()

		var json = JSON.new()
		var err = json.parse(string)
		assert (err == OK, "Scene Manager Error: `scenes.gd` File is corrupted.")
		data = json.data
	return data

# Loads and returns just scenes from `scenes` variable of `scenes.gd` file
func _load_scenes() -> Dictionary:
	return _remove_ignore_list_and_sections_from_dic(_load_all())

# Loads and returns just array value of `_ignore_list` key from `scenes` variable of `scenes.gd` file
func _load_ignores() -> Array:
	var dic: Dictionary = _load_all()
	if dic.has("_ignore_list"):
		return dic["_ignore_list"]
	return []

# Loads and returns just array value of `_sections` key from `scenes` variable of `scenes.gd` file
func _load_sections() -> Array:
	var dic: Dictionary = _load_all()
	if dic.has("_sections"):
		return dic["_sections"]
	return []

# Returns true if a file in a specified address exist
func _file_exists(address: String) -> bool:
	return FileAccess.file_exists(address)

# Returns all scenes data from UI view in a dictionary
func _get_scenes_from_ui() -> Dictionary:
	var list: Node = _get_one_list_node_by_name("All")
	var data: Dictionary = {}
	for node in list.get_list_nodes():
		var value = node.get_value()
		var sections = get_sections(value)
		var settings = {}
		for section in sections:
			var li = _get_one_list_node_by_name(section)
			if li == null:
				continue
			var specific_node = li.get_node_by_scene_address(value)
			var setting = specific_node.get_setting()
			settings[section] = setting.as_dictionary()
		var setting = node.get_setting()
		settings["All"] = setting.as_dictionary()
		data[node.get_key()] = {
			"value": value,
			"sections": sections,
			"settings": settings,
		}
	return data

# Returns all scenes nodes from `All` UI list and returns in an array
#
# Unused method
func _get_scene_nodes_from_view() -> Array:
	var list: Node = _get_one_list_node_by_name("All")
	var nodes: Array = []
	for i in range(list.get_child_count()):
		var node: Node = list.get_child(i)
		nodes.append(node)
	return nodes

# Gathers all data from UI and returns it
func _create_save_dic() -> Dictionary:
	var dic: Dictionary = _get_scenes_from_ui()
	dic["_ignore_list"] = _get_ignores_in_ignore_ui()
	dic["_sections"] = get_all_lists_names_except(["All"])
	dic["_auto_refresh"] = _auto_refresh_button.get_meta("enabled", false)
	dic["_auto_save"] = _auto_save_button.get_meta("enabled", false)
	dic["_ignores_visible"] = _ignores_container.visible
	return dic

# Save button
func _on_save_button_up():
	_clean_sections()
	_save_all(_create_save_dic())

# Returns array of ignore nodes from UI view
func _get_nodes_in_ignore_ui() -> Array:
	var arr: Array = []
	for i in range(_ignore_list.get_child_count()):
		arr.append(_ignore_list.get_child(i))
	return arr

# Returns array of addresses to ignore
func _get_ignores_in_ignore_ui() -> Array:
	var arr: Array = []
	for node in _get_nodes_in_ignore_ui():
		arr.append(node.get_address())
	return arr

# Sets current passed list of ignores into UI instead of others
func _set_ignores(list :Array) -> void:
	_clear_ignore_list()
	for text in list:
		_add_ignore_item(text)

# Clears ignores from UI
func _clear_ignore_list() -> void:
	for node in _get_nodes_in_ignore_ui():
		node.free()

# Returns true if passed address exists in ignore list
func _ignore_exists_in_list(address: String) -> bool:
	for node in _get_nodes_in_ignore_ui():
		if node.get_address() == address or address.begins_with(node.get_address()):
			return true
	return false

# Removes scenes begin with a specific text in all lists
func _remove_scenes_begin_with(text: String):
	for node in _get_lists_nodes():
		node.remove_items_begins_with(text)

# Ignore list Add button up
func _on_add_button_up():
	if _ignore_exists_in_list(_address_line_edit.text):
		_address_line_edit.text = ""
		return
	_add_ignore_item(_address_line_edit.text)
	_remove_scenes_begin_with(_address_line_edit.text)
	_address_line_edit.text = ""
	_add_button.disabled = true
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

# Pops up file dialog to select a ignore folder
func _on_file_dialog_button_button_up():
	_file_dialog.popup_centered(Vector2(600, 600))

# When a file or a dir selects by file dialog
func _on_file_dialog_dir_file_selected(path):
	_address_line_edit.text = path
	_on_address_text_changed(path)

# When an ignore item remove button clicks
func _on_ignore_child_deleted(node: Node) -> void:
	var address: String = node.get_address()
	node.queue_free()
	var ignores: Array = []
	for ignore in _load_ignores():
		if ignore.begins_with(address) && ignore != address:
			ignores.append(ignore)
	_append_scenes(_get_scenes(address, ignores))
	await node.tree_exited
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())

# When ignore address bar text changes
func _on_address_text_changed(new_text: String) -> void:
	if new_text != "":
		if DirAccess.dir_exists_absolute(new_text) || FileAccess.file_exists(new_text) && new_text.begins_with("res://"):
			_add_button.disabled = false
		else:
			_add_button.disabled = true
	else:
		_add_button.disabled = true

# Adds a new list to other lists
func _add_scene_list(text: String) -> void:
	var list = _scene_list_item.instantiate()
	list.name = text.capitalize()
	_tab_container.add_child(list)

# Add section Button
func _on_add_section_button_up():
	if _section_name_line_edit.text != "":
		_add_scene_list(_section_name_line_edit.text)
		_section_name_line_edit.text = ""
		_add_subsection_button.disabled = true
		_add_section_button.disabled = true
		if _auto_save_button.get_meta("enabled", false):
			_save_all(_create_save_dic())

# When section name text changes
func _on_section_name_text_changed(new_text):
	if new_text != "" && !(new_text.capitalize() in get_all_lists_names_except()):
		_add_section_button.disabled = false
	else:
		_add_section_button.disabled = true

	if new_text != "" && _tab_container.get_child(_tab_container.current_tab).name != "All" && !(new_text.capitalize() in get_all_sublists_names_except()):
		_add_subsection_button.disabled = false
	else:
		_add_subsection_button.disabled = true

func _hide_unhide_ignores_list(value: bool) -> void:
	if value:
		_hide_button.icon = _hide_button_checked
		_hide_unhide_button.icon = _hide_button_checked
		_ignores_container.visible = true
		_ignores_panel_container.visible = true
		_hide_unhide_button.visible = false
	else:
		_hide_button.icon = _hide_button_unchecked
		_hide_unhide_button.icon = _hide_button_unchecked
		_ignores_container.visible = false
		_ignores_panel_container.visible = false
		_hide_unhide_button.visible = true

# Hide Button
func _on_hide_button_up():
	_hide_unhide_ignores_list(!_ignores_container.visible)
	_save_all(_create_save_dic())

# Tab changes
func _on_tab_container_tab_changed(tab: int):
	_on_section_name_text_changed(_section_name_line_edit.text)

# Add SubSection Button
func _on_add_subsection_button_up():
	if _section_name_line_edit.text != "":
		var section = _tab_container.get_child(_tab_container.current_tab)
		section.add_subsection(_section_name_line_edit.text)
		_section_name_line_edit.text = ""
		_add_subsection_button.disabled = true
		_add_section_button.disabled = true

func _change_auto_save_state(value: bool) -> void:
	if !value:
		_save_button.disabled = false
		_auto_save_button.set_meta("enabled", false)
		_auto_save_button.icon = _hide_button_unchecked
	else:
		_auto_save_button.set_meta("enabled", true)
		_auto_save_button.icon = _hide_button_checked
	_save_button.disabled = _auto_refresh_button.get_meta("enabled", true) and _auto_save_button.get_meta("enabled", true)

func _on_auto_save_button_up():
	_change_auto_save_state(!_auto_save_button.get_meta("enabled", false))
	_save_all(_create_save_dic())

func _change_auto_refresh_state(value: bool) -> void:
	if !value:
		_auto_refresh_button.set_meta("enabled", false)
		_auto_refresh_button.icon = _folder_button_unchecked
	else:
		_auto_refresh_button.set_meta("enabled", true)
		_auto_refresh_button.icon = _folder_button_checked
	_save_button.disabled = _auto_refresh_button.get_meta("enabled", true) and _auto_save_button.get_meta("enabled", true)

func _on_auto_refresh_button_up():
	_change_auto_refresh_state(!_auto_refresh_button.get_meta("enabled", true))
	_save_all(_create_save_dic())
