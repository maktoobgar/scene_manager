tool
extends MarginContainer

# paths
const PATH: String = "res://addons/scene_manager/scenes.gd"
const ROOT_ADDRESS = "res://"

# prefile
const comment: String = "#\n# Please do not edit anything in this script\n#\n# Just use the editor to change everything you want\n#\n"
const extend_part: String = "extends Node\n\n"
const var_part: String = "var scenes: Dictionary = "

# scene item, ignore item
onready var _ignore_item = preload("res://addons/scene_manager/ignore_item.tscn")
onready var _scene_list_item = preload("res://addons/scene_manager/scene_list.tscn")
# icons
onready var _hide_button_checked = preload("res://addons/scene_manager/icons/GuiChecked.svg")
onready var _hide_button_unchecked = preload("res://addons/scene_manager/icons/GuiCheckedDisabled.svg")
onready var _ignore_list: Node = self.find_node("ignore_list")
# add save, refresh
onready var _save_button: Button = self.find_node("save")
onready var _refresh_button: Button = self.find_node("refresh")
# add category
onready var _add_category_button: Button = self.find_node("add_category")
onready var _category_name_line_edit: LineEdit = self.find_node("category_name")
# add section
onready var _add_section_button: Button = self.find_node("add_section")
onready var _section_name_line_edit: LineEdit = self.find_node("section_name")
# add ignore
onready var _address_line_edit: LineEdit = self.find_node("address")
onready var _file_dialog: FileDialog = self.find_node("file_dialog")
onready var _hide_button: Button = self.find_node("hide")
onready var _add_button: Button = self.find_node("add")
# containers
onready var _tab_container: TabContainer = self.find_node("tab_container")
onready var _ignores_container: Node = self.find_node("ignores")
# generals
onready var _accept_dialog: AcceptDialog = self.find_node("accept_dialog")

var _sections: Dictionary = {}
var reserved_keys: Array = ["back", "null", "ignore", "refresh",
	"reload", "restart", "exit", "quit"]

signal delete_ignore_child(node)

func _ready() -> void:
	_on_refresh_button_up()
	self.connect("delete_ignore_child", self, "_on_delete_ignore_child")

func _absolute_current_working_directory() -> String:
	return ProjectSettings.globalize_path(Directory.new().get_current_dir())

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

func get_all_lists_names(except: String = "") -> Array:
	var arr: Array = []
	for node in _get_lists_nodes():
		if node.name == except.capitalize():
			continue
		arr.append(node.name)
	return arr

func show_message(title: String, description: String) -> void:
	_accept_dialog.window_title = title
	_accept_dialog.dialog_text = description
	_accept_dialog.popup_centered(Vector2(400, 100))

func _get_scenes(root_path: String, ignores: Array) -> Dictionary:
	var files: Dictionary = {}
	var folders: Array = []
	var dir = Directory.new()
	if root_path[len(root_path) - 1] != "/":
		root_path = root_path + "/"
	if !(root_path.substr(0, len(root_path) - 1) in ignores) && dir.open(root_path) == OK:
		dir.list_dir_begin(true, true)

		if dir.file_exists(root_path + ".gdignore"):
			return files
		while true:
			var file_folder = dir.get_next()
			if file_folder == "":
				break
			elif dir.current_is_dir():
				folders.append(file_folder)
			elif file_folder.get_extension() == "tscn":
				files[file_folder.replace("."+file_folder.get_extension(), "")] = root_path + file_folder

		dir.list_dir_end()

		for folder in folders:
			var new_files: Dictionary = _get_scenes(root_path + folder, ignores)
			if len(new_files) != 0:
				_merge_dict(files, new_files)
	else:
		if !(root_path.substr(0, len(root_path) - 1) in ignores):
			print("Couldn't open ", root_path)

	return files

func _clear_scenes_list(name: String) -> void:
	var list: Node = _get_list_by_name(name)
	list.clear_scene_list()

func _clear_all_lists() -> void:
	_sections = {}
	for node in _get_lists_nodes():
		node.clear_scene_list()

func _delete_all_tabs() -> void:
	for node in _get_lists_nodes():
		if node.name == "All":
			continue
		node.free()

func _get_lists_nodes() -> Array:
	var arr: Array = []
	for i in range(_tab_container.get_child_count()):
		arr.append(_tab_container.get_child(i))
	return arr

func _get_list_by_name(name: String) -> Node:
	for node in _get_lists_nodes():
		if name.capitalize() == node.name:
			return node
	return null

func remove_scene_from_list(name: String, key: String, value: String) -> void:
	var list: Node = _get_list_by_name(name)
	list.remove_item(key, value)
	_section_remove(name, value)

func add_scene_to_list(name: String, key: String, value: String) -> void:
	var list: Node = _get_list_by_name(name)
	list.add_item(key, value)
	_section_add(name, value)

func _add_ignore_item(address: String) -> void:
	var item = _ignore_item.instance()
	item.set_address(address)
	_ignore_list.add_child(item)

func _append_scenes(scenes: Dictionary) -> void:
	_get_list_by_name("All").append_scenes(scenes)
	for node in _get_lists_nodes():
		for key in scenes:
			if node.name in get_section(scenes[key]):
				node.add_item(key, scenes[key])

func _clear_all() -> void:
	_delete_all_tabs()
	_clear_all_lists()
	_clear_ignore_list()

func _reload_scenes() -> void:
	var data: Dictionary = _load_scenes(PATH)
	var scenes: Dictionary = _get_scenes(ROOT_ADDRESS, _load_ignores(PATH))
	var scenes_dics: Array = scenes.values()
	var scenes_values: Array = []
	for i in range(len(scenes_dics)):
		scenes_values.append(scenes_dics[i])
	for key in data:
		assert (
			("value" in data[key].keys()) && ("sections" in data[key].keys()),
			"Scene Manager Error: this format is not supported. %s"%
			"Every scene item has to have 'value' and 'sections' field inside them.'"
		)
		if !(data[key]["value"] in scenes_values):
			continue
		for section in data[key]["sections"]:
			_section_add(section, data[key]["value"])
			add_scene_to_list(section, key, data[key]["value"])
		add_scene_to_list("All", key, data[key]["value"])

	var data_values: Array = []
	if data:
		var data_dics = data.values()
		for i in range(len(data_dics)):
			data_values.append(data_dics[i]["value"])
	for key in scenes:
		if !(scenes[key] in data_values):
			add_scene_to_list("All", key, scenes[key])

func _reload_ignores() -> void:
	var ignores: Array = _load_ignores(PATH)
	_set_ignores(ignores)

func _reload_tabs() -> void:
	var sections: Array = _load_sections(PATH)
	if _get_list_by_name("All") == null:
		_add_scene_list("All")
	for section in sections:
		_add_scene_list(section)

func _on_refresh_button_up() -> void:
	_clear_all()
	_reload_tabs()
	_reload_scenes()
	_reload_ignores()

# _sections Manager

func _section_add(section: String, value: String) -> void:
	if section == "All":
		return
	if !_sections.has(value):
		_sections[value] = []
	if !(section in _sections[value]):
		_sections[value].append(section)

func _section_remove(section: String, value: String) -> void:
	if !_sections.has(value):
		return
	if section in _sections[value]:
		_sections[value].erase(section)
	if len(_sections[value]) == 0:
		_sections.erase(value)

func get_section(value: String) -> Array:
	if !_sections.has(value):
		return []
	return _sections[value]

func _clean_sections() -> void:
	var scenes: Array = get_all_lists_names("All")
	for key in _sections:
		var will_be_deleted: Array = []
		for section in _sections[key]:
			if !(section in scenes):
				will_be_deleted.append(section)
		for section in will_be_deleted:
			_sections[key].erase(section)

# End Of _sections Manager

func update_all_scene_with_key(key: String, new_key: String, value: String, except: Node):
	for node in _get_lists_nodes():
		if node != except:
			node.update_scene_with_key(key, new_key, value)

func _remove_ignore_list_and_sections_from_dic(dic: Dictionary) -> Dictionary:
	if dic.has("_ignore_list"):
		dic.erase("_ignore_list")
	if dic.has("_sections"):
		dic.erase("_sections")
	return dic

func _save_all(address: String, data: Dictionary) -> void:
	var file = File.new()
	file.open(address, File.WRITE)
	var write_data: String = comment + extend_part + var_part + to_json(data) + "\n"
	file.store_string(write_data)
	file.close()

func _load_all(address: String) -> Dictionary:
	var data: Dictionary = {}

	if _file_exists(address):
		var file: File = File.new()
		file.open(address, File.READ)
		var string: String = file.get_as_text()
		string = string.substr(string.find("var"), len(string)).replace(var_part, "").strip_escapes()

		assert (
			validate_json(string) == "",
			"Scene Manager Error: `scenes.gd` File is corrupted."
		)
		data = parse_json(string)
		file.close()
	return data

func _load_scenes(address: String) -> Dictionary:
	return _remove_ignore_list_and_sections_from_dic(_load_all(address))

func _load_ignores(address: String) -> Array:
	var dic: Dictionary = _load_all(address)
	if dic.has("_ignore_list"):
		return dic["_ignore_list"]
	return []

func _load_sections(address: String) -> Array:
	var dic: Dictionary = _load_all(address)
	if dic.has("_sections"):
		return dic["_sections"]
	return []

func _file_exists(address: String) -> bool:
	return Directory.new().file_exists(address)

func _get_scenes_from_view() -> Dictionary:
	var list: Node = _get_list_by_name("All")
	var data: Dictionary = {}
	for node in list.get_scene_nodes():
		data[node.get_key()] = {
			"value": node.get_value(),
			"sections": get_section(node.get_value()),
		}
	return data

func _get_scene_nodes_from_view() -> Array:
	var list: Node = _get_list_by_name("All")
	var nodes: Array = []
	for i in range(list.get_child_count()):
		if i == 0: continue
		var node: Node = list.get_child(i)
		nodes.append(node)
	return nodes

func _on_save_button_up():
	_clean_sections()
	var dic: Dictionary = _get_scenes_from_view()
	dic["_ignore_list"] = _get_ignores_in_ignore_view()
	dic["_sections"] = get_all_lists_names("All")
	_save_all(PATH, dic)
	_on_refresh_button_up()

func _get_nodes_in_ignore_view() -> Array:
	var arr: Array = []
	for i in range(_ignore_list.get_child_count()):
		if i == 0:
			continue
		arr.append(_ignore_list.get_child(i))
	return arr

func _get_ignores_in_ignore_view() -> Array:
	var arr: Array = []
	for node in _get_nodes_in_ignore_view():
		arr.append(node.get_address())
	return arr

func _set_ignores(list :Array) -> void:
	_clear_ignore_list()
	for text in list:
		_add_ignore_item(text)

func _clear_ignore_list() -> void:
	for node in _get_nodes_in_ignore_view():
		node.free()

func _on_list_exists(address: String) -> bool:
	for node in _get_nodes_in_ignore_view():
		if node.get_address() == address:
			return true
	return false

func _remove_scenes_begin_with(text: String):
	for node in _get_lists_nodes():
		node.remove_items_begins_with(text)

func _on_add_button_up():
	if _on_list_exists(_address_line_edit.text):
		_address_line_edit.text = ""
		return
	_add_ignore_item(_address_line_edit.text)
	_remove_scenes_begin_with(_address_line_edit.text)
	_address_line_edit.text = ""
	_add_button.disabled = true

func _on_file_dialog_button_button_up():
	_file_dialog.popup_centered(Vector2(600, 600))

func _on_file_dialog_dir_file_selected(path):
	_address_line_edit.text = path
	_on_address_text_changed(path)

func _on_delete_ignore_child(node: Node) -> void:
	var address: String = node.get_address()
	node.queue_free()
	var ignores: Array = []
	for ignore in _load_ignores(PATH):
		if ignore.begins_with(address) && ignore != address:
			ignores.append(ignore)
	_append_scenes(_get_scenes(address, ignores))

func _on_address_text_changed(new_text: String) -> void:
	if new_text != "":
		var dir = Directory.new()
		if dir.dir_exists(new_text) || dir.file_exists(new_text) && new_text.begins_with("res://"):
			_add_button.disabled = false
		else:
			_add_button.disabled = true
	else:
		_add_button.disabled = true

func _add_scene_list(text: String) -> void:
	var list = _scene_list_item.instance()
	list.name = text.capitalize()
	_tab_container.add_child(list)

func _on_add_category_button_up():
	if _category_name_line_edit.text != "":
		_add_scene_list(_category_name_line_edit.text)
		_category_name_line_edit.text = ""
		_add_category_button.disabled = true

func _on_category_name_text_changed(new_text):
	if new_text != "" && !(new_text.capitalize() in get_all_lists_names()):
		_add_category_button.disabled = false
	else:
		_add_category_button.disabled = true

func check_duplication():
	var list: Array = _get_list_by_name("All").check_duplication()
	for node in _get_lists_nodes():
		node.set_reset_theme_for_all()
		if list:
			node.set_duplicate_theme(list)

func _on_hide_button_up():
	if _ignores_container.visible:
		_hide_button.icon = _hide_button_unchecked
		_ignores_container.visible = false
	else:
		_hide_button.icon = _hide_button_checked
		_ignores_container.visible = true
