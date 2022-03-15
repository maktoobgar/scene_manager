tool
extends MarginContainer

const PATH: String = "res://scenes.json"
const ROOT_ADDRESS = "res://"

onready var _id: int = 1
onready var _normal_style_box_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_normal.tres")
onready var _scene_item = preload("res://addons/scene_manager/scene_item.tscn")
onready var _ignore_item = preload("res://addons/scene_manager/ignore_item.tscn")
onready var _ignore_list: Node = self.find_node("ignore_list")
onready var _scene_list: Node = self.find_node("scene_list")
onready var _save_button: Button = self.find_node("save")
onready var _refresh_button: Button = self.find_node("refresh")
onready var _add_button: Button = self.find_node("add")
onready var _address_line_edit: LineEdit = self.find_node("address")
onready var _file_dialog: FileDialog = self.find_node("file_dialog")

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

func _clear_scenes_list() -> void:
	_id = 1
	while _scene_list.get_child_count() > 1:
		_scene_list.get_child(1).free()

func _add_scene_item(key: String, value: String) -> void:
	var item = _scene_item.instance()
	item.set_id(String(_id))
	item.set_key(key)
	item.set_value(value)
	_scene_list.add_child(item)
	_id += 1

func _add_ignore_item(address: String) -> void:
	var item = _ignore_item.instance()
	item.set_address(address)
	_ignore_list.add_child(item)

func _append_scenes(scenes: Dictionary) -> void:
	for key in scenes:
		_add_scene_item(key, scenes[key])

func _clear_all() -> void:
	_clear_scenes_list()
	_clear_ignore_list()

func _reload_scenes() -> void:
	var data: Dictionary = _load_scenes(PATH)
	var scenes: Dictionary = _get_scenes(ROOT_ADDRESS, _load_ignores(PATH))
	var scenes_values: Array = scenes.values()
	for key in data:
		if !(data[key] in scenes_values):
			continue
		_add_scene_item(key, data[key])

	var data_values: Array = []
	if data:
		data_values = data.values()
	for key in scenes:
		if !(scenes[key] in data_values):
			_add_scene_item(key, scenes[key])

func _reload_ignores() -> void:
	var ignores: Array = _load_ignores(PATH)
	_set_ignores(ignores)

func _on_refresh_button_up() -> void:
	_clear_all()
	_reload_scenes()
	_reload_ignores()
	check_if_saved_values_are_same_with_view()

func _remove_ignore_list_from_dic(dic: Dictionary) -> Dictionary:
	dic.erase("_ignore_list")
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
	return _remove_ignore_list_from_dic(_load_all(address))

func _load_ignores(address: String) -> Array:
	var dic: Dictionary = _load_all(address)
	if dic.has("_ignore_list"):
		return dic["_ignore_list"]
	return []

func _file_exists(address: String) -> bool:
	return Directory.new().file_exists(address)

func _get_scenes_from_view() -> Dictionary:
	var data: Dictionary = {}
	for i in range(_scene_list.get_child_count()):
		if i == 0: continue
		var node: Node = _scene_list.get_child(i)
		data[node.get_key()] = node.get_value()
	return data

func _get_scene_nodes_from_view(except: Node = null) -> Array:
	var nodes: Array = []
	for i in range(_scene_list.get_child_count()):
		if i == 0: continue
		var node: Node = _scene_list.get_child(i)
		if node != except:
			nodes.append(node)
	return nodes

func get_duplications() -> Array:
	var arr: Array = []
	var scenes: Array = _get_scene_nodes_from_view()
	for node1 in scenes:
		for node2 in scenes:
			if node1 != node2 && node1.get_key() == node2.get_key():
				arr.append(node1)
	return arr

func _check_scenes_list() -> bool:
	var loaded_scenes = _load_scenes(PATH)
	var view_scenes = _get_scenes_from_view()
	if len(loaded_scenes) != len(view_scenes):
		_save_button.disabled = false
		return false
	for key in view_scenes:
		if !loaded_scenes.has(key) || loaded_scenes[key] != view_scenes[key]:
			_save_button.disabled = false
			return false
	_save_button.disabled = true
	return true

func _check_ignore_list() -> bool:
	var loaded_ignores: Array = _load_ignores(PATH)
	var view_ignores: Array = _get_ignores_in_ignore_view()
	if len(view_ignores) != len(loaded_ignores):
		_save_button.disabled = false
		return false
	for ignore in view_ignores:
		if !(ignore in loaded_ignores):
			_save_button.disabled = false
			return false
	_save_button.disabled = true
	return true

func check_if_saved_values_are_same_with_view():
	if _check_scenes_list():
		if _check_ignore_list():
			pass

func all_nodes_to_default_theme():
	for node in _get_scene_nodes_from_view():
		node = node.get_key_node()
		node.add_stylebox_override("normal", _normal_style_box_line_edit)
		node.add_stylebox_override("focus", _normal_style_box_line_edit)

func _on_save_button_up():
	var dic: Dictionary = _get_scenes_from_view()
	dic["_ignore_list"] = _get_ignores_in_ignore_view()
	_save_all(PATH, dic)
	check_if_saved_values_are_same_with_view()

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

func _reindex_scenes_view() -> void:
	var scenes: Array = _get_scene_nodes_from_view()
	_id = 1
	for scene in scenes:
		scene.set_id(String(_id))
		_id += 1

func _remove_scenes_begin_with(text: String) -> void:
	var scenes: Array = _get_scene_nodes_from_view()
	for node in scenes:
		if node.get_value().begins_with(text):
			node.free()
	_reindex_scenes_view()

func _on_add_button_up():
	if _on_list_exists(_address_line_edit.text):
		_address_line_edit.text = ""
		return
	_add_ignore_item(_address_line_edit.text)
	_remove_scenes_begin_with(_address_line_edit.text)
	_address_line_edit.text = ""
	_add_button.disabled = true
	check_if_saved_values_are_same_with_view()

func _on_file_dialog_button_button_up():
	_file_dialog.popup_centered(Vector2(600, 600))

func _on_file_dialog_dir_file_selected(path):
	_address_line_edit.text = path
	_on_address_text_changed(path)

func _on_delete_ignore_child(node: Node):
	node.queue_free()
	_append_scenes(_get_scenes(node.get_address(), []))
	yield(get_tree().create_timer(0.1), "timeout")
	check_if_saved_values_are_same_with_view()

func _on_address_text_changed(new_text: String):
	if new_text != "":
		var dir = Directory.new()
		if dir.dir_exists(new_text) || dir.file_exists(new_text) && new_text.begins_with("res://"):
			_add_button.disabled = false
		else:
			_add_button.disabled = true
	else:
		_add_button.disabled = true
