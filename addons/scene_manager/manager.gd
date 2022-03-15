tool
extends MarginContainer

const PATH: String = "res://scenes.json"
const ROOT_ADDRESS = "res://"

onready var _normal_style_box_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_normal.tres")
onready var _ignore_item = preload("res://addons/scene_manager/ignore_item.tscn")
onready var _scene_list_item = preload("res://addons/scene_manager/scene_list.tscn")
onready var _ignore_list: Node = self.find_node("ignore_list")
onready var _save_button: Button = self.find_node("save")
onready var _refresh_button: Button = self.find_node("refresh")
onready var _add_button: Button = self.find_node("add")
onready var _add_category_button: Button = self.find_node("add_category")
onready var _category_name_line_edit: LineEdit = self.find_node("category_name")
onready var _address_line_edit: LineEdit = self.find_node("address")
onready var _file_dialog: FileDialog = self.find_node("file_dialog")
onready var _tab_container: TabContainer = self.find_node("tab_container")

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

func get_all_lists_names() -> Array:
	var arr: Array = []
	for i in range(_tab_container.get_child_count()):
		arr.append(_tab_container.get_child(i).name)
	return arr

func _get_scenes(root_path: String, ignores: Array) -> Dictionary:
	var files: Dictionary = {}
	var folders: Array = []
	var dir = Directory.new()
	if root_path[len(root_path) - 1] != "/":
		root_path = root_path + "/"
	if !(root_path.substr(0, len(root_path) - 1) in ignores) && dir.open(root_path) == OK:
		dir.list_dir_begin(true, true)

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
	for i in range(_tab_container.get_child_count()):
		var child: Node = _tab_container.get_child(i)
		child.clear_scene_list()

func _delete_all_tabs() -> void:
	for i in range(_tab_container.get_child_count()):
		if _tab_container.get_child(i).name == "All":
			continue
		_tab_container.get_child(i).queue_free()

func _get_list_by_name(name: String) -> Node:
	for i in range(_tab_container.get_child_count()):
		if name == _tab_container.get_child(i).name:
			return _tab_container.get_child(i)
	return null

func remove_scene_from_list(name: String, key: String, value: String) -> void:
	var list: Node = _get_list_by_name(name)
	list.remove_item(key, value)

func add_scene_to_list(name: String, key: String, value: String) -> void:
	var list: Node = _get_list_by_name(name)
	list.add_item(key, value)

func _add_ignore_item(address: String) -> void:
	var item = _ignore_item.instance()
	item.set_address(address)
	_ignore_list.add_child(item)

func _append_scenes(scenes: Dictionary, list_name: String) -> void:
	var node: Node = _get_list_by_name(list_name)
	node.append_scenes(scenes)

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
		if !(data[key]["value"] in scenes_values):
			continue
		for section in data[key]["sections"]:
			add_scene_to_list(section, key, data[key]["value"])

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
	for section in sections:
		_add_scene_list(section)
	if _get_list_by_name("All") != null:
		return
	_add_scene_list("All")

func _on_refresh_button_up() -> void:
	_clear_all()
	_reload_tabs()
	_reload_scenes()
	_reload_ignores()

func _remove_ignore_list_and_sections_from_dic(dic: Dictionary) -> Dictionary:
	dic.erase("_ignore_list")
	dic.erase("_sections")
	return dic

func _save_all(address: String, data: Dictionary) -> void:
	var file = File.new()
	file.open(address, File.WRITE)
	file.store_var(to_json(data))
	file.close()

func _load_all(address: String) -> Dictionary:
	var data: Dictionary = {}

	if _file_exists(address):
		var file = File.new()
		file.open(address, File.READ)
		data = parse_json(file.get_var())
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
	for i in range(list.get_child_count()):
		if i == 0: continue
		var node: Node = list.get_child(i)
		data[node.get_key()] = {
			"value": node.get_value(),
			"sections": node.get_sections(),
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
	var dic: Dictionary = _get_scenes_from_view()
	dic["_ignore_list"] = _get_ignores_in_ignore_view()
	dic["_sections"] = get_all_lists_names()
	_save_all(PATH, dic)

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

func _on_add_button_up():
	if _on_list_exists(_address_line_edit.text):
		_address_line_edit.text = ""
		return
	_add_ignore_item(_address_line_edit.text)
#	_remove_scenes_begin_with(_address_line_edit.text)
	_address_line_edit.text = ""
	_add_button.disabled = true

func _on_file_dialog_button_button_up():
	_file_dialog.popup_centered(Vector2(600, 600))

func _on_file_dialog_dir_file_selected(path):
	_address_line_edit.text = path
	_on_address_text_changed(path)

func _on_delete_ignore_child(node: Node):
	node.queue_free()
#	_append_scenes(_get_scenes(node.get_address(), []))
	yield(get_tree().create_timer(0.1), "timeout")

func _on_address_text_changed(new_text: String):
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
	list.name = text
	_tab_container.add_child(list)

func _on_add_category_button_up():
	if _category_name_line_edit.text != "":
		_add_scene_list(_category_name_line_edit.text)
		_category_name_line_edit.text = ""

func _on_category_name_text_changed(new_text):
	if new_text == "":
		_add_category_button.disabled = true
	else:
		_add_category_button.disabled = false
