@tool
extends Node

# Scene itema and sub_section to instance and add in list
const _scene_item = preload("res://addons/scene_manager/scene_item.tscn")
const _sub_section = preload("res://addons/scene_manager/sub_section.tscn")
# Duplicate + normal scene theme
const _duplicate_line_edit: StyleBox = preload("res://addons/scene_manager/themes/line_edit_duplicate.tres")
# Open close icons
const _eye_open = preload("res://addons/scene_manager/icons/eye_open.png")
const _eye_close = preload("res://addons/scene_manager/icons/eye_close.png")
# variables
@onready var _container: VBoxContainer = find_child("container")
@onready var _delete_list_button: Button = find_child("delete_list")
@onready var _hidden_button: Button = find_child("hidden")
var _root: Node = self
var _main_subsection: Node = null
var _secondary_subsection: Node = null

# Finds and fills `_root` variable properly
#
# Start up of `All` list
func _ready() -> void:
	while true:
		if _root == null:
			## If we are here, we are running in editor, so get out
			break
		elif _root.name == "Scene Manager" || _root.name == "menu":
			break
		_root = _root.get_parent()

	if self.name == "All":
		_delete_list_button.icon = null
		_delete_list_button.disabled = true
		_delete_list_button.focus_mode = Control.FOCUS_NONE

		var sub = _sub_section.instantiate()
		sub._root = _root
		sub.name = "Uncategorized"
		_container.add_child(sub)
		sub.open()
		sub.hide_delete_button()
		_main_subsection = sub

		var sub2 = _sub_section.instantiate()
		sub._root = _root
		sub2.name = "Categorized"
		_container.add_child(sub2)
		sub2.hide_delete_button()
		_secondary_subsection = sub2
	else:
		var sub = _sub_section.instantiate()
		sub._root = _root
		sub.name = "All"
		sub.visible = false
		_container.add_child(sub)
		sub.open()
		sub.hide_delete_button()
		_main_subsection = sub

# Determines item can be visible with current settings or not
func determine_item_visibility(setting: ItemSetting) -> bool:
	return true if _hidden_button.icon == _eye_close && !setting.visibility else true if _hidden_button.icon == _eye_open && setting.visibility else false

# Adds an item to list
func add_item(key: String, value: String, setting: ItemSetting) -> void:
	if !self.is_node_ready():
		await self.ready
	var item = _scene_item.instantiate()
	item.set_key(key)
	item.set_value(value)
	item.set_setting(setting)
	item.visible = determine_item_visibility(setting)
	item._list = self
	if name == "All":
		if !setting.categorized:
			_main_subsection.add_item(item)
		else:
			_secondary_subsection.add_item(item)
	else:
		if setting.subsection != "":
			var subsection = find_subsection(setting.subsection)
			if subsection:
				subsection.add_item(item)
			else:
				add_subsection(setting.subsection).add_item(item)
		else:
			_main_subsection.add_item(item)

# Finds and returns a sub_section in the list
func find_subsection(key: String) -> Node:
	for i in range(_container.get_child_count()):
		var element = _container.get_child(i)
		if element.name == key:
			return element
	return null

# Removes an item from list
func remove_item(key: String, value: String) -> void:
	for i in range(_container.get_child_count()):
		var children: Array = _container.get_child(i).get_items()
		for j in range(len(children)):
			if children[j].get_key() == key && children[j].get_value() == value:
				children[j].queue_free()
				return

# Removes items that their value begins with passed value
func remove_items_begins_with(value: String) -> void:
	for i in range(_container.get_child_count()):
		var children: Array = _container.get_child(i).get_items()
		for j in range(len(children)):
			if children[j].get_value().begins_with(value):
				children[j].queue_free()

# Clear all scene records from UI list
func clear_list() -> void:
	for i in range(_container.get_child_count()):
		_container.get_child(i).queue_free()

# Appends all scenes into UI list
#
# This function is used for new items that are new in project directory and are
# not saved before, so they have no settings
#
# Input example:
# {"scene_key": "scene_address", "scene_key": "scene_address", ...}
func append_scenes(nodes: Dictionary) -> void:
	if name == "All":
		for key in nodes:
			add_item(key, nodes[key], ItemSetting.new(true, _root.has_sections(nodes[key])))
	else:
		for key in nodes:
			add_item(key, nodes[key], ItemSetting.default())

# Return an array of record nodes from UI list
func get_list_nodes() -> Array:
	if _container == null:
		_container = find_child("container")
	var arr: Array[Node] = []
	for i in range(_container.get_child_count()):
		var nodes = _container.get_child(i).get_items()
		arr.append_array(nodes)
	return arr

# Returns a specific node from passed scene name
func get_node_by_scene_name(scene_name: String) -> Node:
	for i in range(_container.get_child_count()):
		var items = _container.get_child(i).get_items()
		for j in range(len(items)):
			if items[j].get_key() == scene_name:
				return items[j]
	return null

# Returns a specific node from passed scene address
func get_node_by_scene_address(scene_address: String) -> Node:
	for i in range(_container.get_child_count()):
		var items = _container.get_child(i).get_items()
		for j in range(len(items)):
			if items[j].get_value() == scene_address:
				return items[j]
	return null

# Update a specific scene record with passed data in UI
func update_scene_with_key(key: String, new_key: String, value: String, setting: ItemSetting) -> void:
	for i in range(_container.get_child_count()):
		var children: Array[Node] = _container.get_child(i).get_items()
		for j in range(len(children)):
			if children[j].get_key() == key && children[j].get_value() == value:
				children[j].set_key(new_key)
				children[j].set_setting(setting)

# Checks duplication in current list and return their scene addresses in an array from UI
func check_duplication() -> Array:
	var all: Array[Node] = get_list_nodes()
	var arr: Array[String] = []
	for i in range(len(all)):
		var j: int = i + 1
		while j < len(all):
			var child1: Node = all[i]
			var child2: Node = all[j]
			if child1.get_key() == child2.get_key():
				if !(child1.get_key() in arr):
					arr.append(child1.get_key())
			j += 1
	return arr

# Reset theme for all children in UI
func set_reset_theme_for_all() -> void:
	for i in range(_container.get_child_count()):
		var children: Array[Node] = _container.get_child(i).get_items()
		for j in range(len(children)):
			children[j].remove_custom_theme()

# Sets duplicate theme for children in passed list in UI
func set_duplicate_theme(list: Array) -> void:
	for i in range(_container.get_child_count()):
		var children: Array[Node] = _container.get_child(i).get_items()
		for j in range(len(children)):
			if children[j].get_key() in list:
				children[j].custom_set_theme(_duplicate_line_edit)

# Returns all names of sublist
func get_all_sublists() -> Array:
	var arr: Array[String] = []
	for i in range(_container.get_child_count()):
		arr.append(_container.get_child(i).name)
	return arr

# Adds a subsection
func add_subsection(text: String) -> Control:
	var sub = _sub_section.instantiate()
	sub._root = _root
	sub.name = text.capitalize()
	_container.add_child(sub)
	return sub

# List deletion
func _on_delete_list_button_up() -> void:
	if self.name == "All":
		return
	queue_free()
	await self.tree_exited
	_root.section_removed.emit(self)

# Refreshes `visible` of all items in list
func _refresh_visible_of_all_items() -> void:
	for i in range(_container.get_child_count()):
		var children: Array[Node] = _container.get_child(i).get_items()
		for j in range(len(children)):
			children[j].visible = determine_item_visibility(children[j].get_setting())

# Hidden Button
func _on_hidden_button_up():
	if _hidden_button.icon == _eye_open:
		_hidden_button.icon = _eye_close
		_refresh_visible_of_all_items()
	elif _hidden_button.icon == _eye_close:
		_hidden_button.icon = _eye_open
		_refresh_visible_of_all_items()
