@tool
extends MarginContainer

const SETTINGS_PROPERTY_NAME := "scene_manager/scenes/scenes_path"
const PATH: String = "res://addons/scene_manager/scenes.gd"
const ROOT_ADDRESS = "res://"
const comment: String = "#\n# Please do not edit anything in this script\n#\n# Just use the editor to change everything you want\n#\n"
const extend_part: String = "extends Node\n\n"
const var_part: String = "var scenes: Dictionary = "

const _ignore_item = preload("res://addons/scene_manager/ignore_item.tscn")
const _scene_list_item = preload("res://addons/scene_manager/scene_list.tscn")
const _hide_button_checked = preload("res://addons/scene_manager/icons/GuiChecked.svg")
const _hide_button_unchecked = preload("res://addons/scene_manager/icons/GuiCheckedDisabled.svg")
const _folder_button_checked = preload("res://addons/scene_manager/icons/FolderActive.svg")
const _folder_button_unchecked = preload("res://addons/scene_manager/icons/Folder.svg")

@onready var _ignore_list: Node = self.find_child("ignore_list")
@onready var _save_button: Button = self.find_child("save")
@onready var _refresh_button: Button = self.find_child("refresh")
@onready var _auto_save_button: Button = self.find_child("auto_save")
@onready var _auto_refresh_button: Button = self.find_child("auto_refresh")
@onready var _add_subsection_button: Button = self.find_child("add_subsection")
@onready var _add_section_button: Button = self.find_child("add_section")
@onready var _section_name_line_edit: LineEdit = self.find_child("section_name")
@onready var _address_line_edit: LineEdit = self.find_child("address")
@onready var _file_dialog: FileDialog = self.find_child("file_dialog")
@onready var _hide_button: Button = self.find_child("hide")
@onready var _hide_unhide_button: Button = self.find_child("hide_unhide")
@onready var _add_button: Button = self.find_child("add")
@onready var _tab_container: TabContainer = self.find_child("tab_container")
@onready var _ignores_container: Node = self.find_child("ignores")
@onready var _ignores_panel_container: Node = self.find_child("ignores_panel")
@onready var _accept_dialog: AcceptDialog = self.find_child("accept_dialog")

var _sections: Dictionary = {}
var reserved_keys: Array = [
	"back", "null", "ignore", "refresh", "reload", "restart", "exit", "quit"
]
var _timer: Timer = null

var _scene_cache: Dictionary = {}
var _ignore_cache: Array = []
var _section_cache: Array = []
var _filesystem_cache: Dictionary = {}
var _last_scan_time: int = 0
const CACHE_LIFETIME := 5000
const BATCH_SIZE := 20

signal ignore_child_deleted(node: Node)
signal item_renamed(node: Node)
signal item_visibility_changed(node: Node, visibility: bool)
signal item_added_to_list(node: Node, list_name: String)
signal item_removed_from_list(node: Node, list_name: String)
signal sub_section_removed(node: Node)
signal section_removed(node: Node)
signal added_to_sub_section(node: Node, sub_section: Node)


func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	_setup_timer()
	_connect_signals()
	_setup_filesystem_monitoring()
	await _deferred_refresh()


func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = 0.5
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)


func _connect_signals() -> void:
	self.ignore_child_deleted.connect(_on_ignore_child_deleted)
	self.item_renamed.connect(_on_item_renamed)
	self.item_visibility_changed.connect(_on_item_visibility_changed)
	self.item_added_to_list.connect(_on_added_to_list)
	self.item_removed_from_list.connect(_on_item_removed_from_list)
	self.sub_section_removed.connect(_on_sub_section_removed)
	self.section_removed.connect(_on_section_removed)
	self.added_to_sub_section.connect(_on_added_to_sub_section)


func _setup_filesystem_monitoring() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_filesystem_changed)


func _deferred_refresh() -> void:
	_clear_all()
	await get_tree().process_frame
	_reload_tabs()
	await get_tree().process_frame
	_reload_scenes()
	await get_tree().process_frame
	_reload_ignores()


func _get_scenes(root_path: String, ignores: Array) -> Dictionary:
	var current_time := Time.get_ticks_msec()
	if _filesystem_cache.has(root_path) and current_time - _last_scan_time < CACHE_LIFETIME:
		return _filesystem_cache[root_path]

	var files := {}
	var scan_queue := [[root_path, root_path]]

	while not scan_queue.is_empty():
		var current := scan_queue.pop_front()
		var path: String = current[0]
		var base_path: String = current[1]

		if path in ignores:
			continue

		var dir := DirAccess.open(path)
		if not dir:
			continue

		if dir.file_exists(".gdignore"):
			continue

		dir.list_dir_begin()

		while true:
			var file := dir.get_next()
			if file == "":
				break

			var full_path := path.path_join(file)

			if dir.current_is_dir():
				scan_queue.push_back([full_path, base_path])
			elif file.ends_with(".tscn") and not (full_path in ignores):
				var key := file.get_basename()
				files[key] = full_path

		dir.list_dir_end()

	_filesystem_cache[root_path] = files
	_last_scan_time = current_time
	return files


func _reload_scenes() -> void:
	var data := _load_scenes()
	var scenes := _get_scenes(ROOT_ADDRESS, _load_ignores())
	var scenes_values := scenes.values()

	if data.has("_auto_refresh"):
		_change_auto_refresh_state(data["_auto_refresh"])
	if data.has("_auto_save"):
		_change_auto_save_state(data["_auto_save"])
	if data.has("_ignores_visible"):
		_hide_unhide_ignores_list(data["_ignores_visible"])

	var batch := []
	for key in data:
		if key.begins_with("_"):
			continue

		var scene = data[key]
		if not ("value" in scene and "sections" in scene):
			continue

		if not (scene["value"] in scenes_values):
			continue

		batch.append({"key": key, "scene": scene})

		if batch.size() >= BATCH_SIZE:
			await _process_scene_batch(batch)
			batch.clear()

	if not batch.is_empty():
		await _process_scene_batch(batch)

	var data_values := []
	for dic in data.values():
		if typeof(dic) == TYPE_DICTIONARY and dic.has("value"):
			data_values.append(dic["value"])

	for key in scenes:
		if not (scenes[key] in data_values):
			await _add_scene_to_list("All", key, scenes[key], ItemSetting.default())


func _process_scene_batch(batch: Array) -> void:
	for item in batch:
		var key = item["key"]
		var scene = item["scene"]

		for section in scene["sections"]:
			var setting = _get_scene_setting(scene, section)
			_sections_add(scene["value"], section)
			await _add_scene_to_list(section, key, scene["value"], setting)

		var all_setting = _get_scene_setting(scene, "All")
		all_setting.categorized = has_sections(scene["value"])
		await _add_scene_to_list("All", key, scene["value"], all_setting)

		await get_tree().process_frame


func _get_scene_setting(scene: Dictionary, section: String) -> ItemSetting:
	if scene.has("settings") and scene["settings"].has(section):
		return ItemSetting.dictionary_to_item_setting(scene["settings"][section])
	return ItemSetting.default()


func _load_all() -> Dictionary:
	var settings_path := ProjectSettings.get_setting(SETTINGS_PROPERTY_NAME, PATH)
	if not FileAccess.file_exists(settings_path):
		return {}

	var file := FileAccess.open(settings_path, FileAccess.READ)
	var content := file.get_as_text()
	var json_str := (
		content.substr(content.find("var"), content.length()).replace(var_part, "").strip_escapes()
	)

	var json := JSON.new()
	var err := json.parse(json_str)
	assert(err == OK, "Scene Manager Error: `scenes.gd` File is corrupted.")

	return json.data


func _save_all(data: Dictionary) -> void:
	var settings_path := ProjectSettings.get_setting(SETTINGS_PROPERTY_NAME, PATH)
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	var json_str := JSON.new().stringify(data)
	file.store_string(comment + extend_part + var_part + json_str + "\n")


func _load_scenes() -> Dictionary:
	return _remove_ignore_list_and_sections_from_dic(_load_all())


func _load_ignores() -> Array:
	var data := _load_all()
	return data.get("_ignore_list", [])


func _load_sections() -> Array:
	var data := _load_all()
	return data.get("_sections", [])


func _remove_ignore_list_and_sections_from_dic(dic: Dictionary) -> Dictionary:
	var result := dic.duplicate()
	result.erase("_ignore_list")
	result.erase("_sections")
	return result


func _on_refresh_button_up() -> void:
	await _deferred_refresh()


func _clear_all() -> void:
	_delete_all_tabs()
	_clear_all_lists()
	_clear_ignore_list()
	_scene_cache.clear()
	_ignore_cache.clear()
	_section_cache.clear()


func _get_lists_nodes() -> Array:
	var arr: Array = []
	for i in range(_tab_container.get_child_count()):
		arr.append(_tab_container.get_child(i))
	return arr


func _get_one_list_node_by_name(name: String) -> Node:
	for node in _get_lists_nodes():
		if name.capitalize() == node.name:
			return node
	return null


func _clear_all_lists() -> void:
	_sections.clear()
	for list in _get_lists_nodes():
		list.clear_list()


func _delete_all_tabs() -> void:
	for node in _get_lists_nodes():
		node.free()


func _reload_tabs() -> void:
	var sections := _load_sections()
	if _get_one_list_node_by_name("All") == null:
		_add_scene_list("All")
	for section in sections:
		if not _get_one_list_node_by_name(section):
			_add_scene_list(section)


func _add_scene_list(text: String) -> void:
	var list = _scene_list_item.instantiate()
	list.name = text.capitalize()
	_tab_container.add_child(list)


func _add_scene_to_list(
	list_name: String, scene_name: String, scene_address: String, setting: ItemSetting
) -> void:
	var list := _get_one_list_node_by_name(list_name)
	if list == null:
		return
	await list.add_item(scene_name, scene_address, setting)
	_sections_add(scene_address, list_name)


func _sections_add(scene_address: String, section_name: String) -> void:
	if section_name == "All":
		return
	if not _sections.has(scene_address):
		_sections[scene_address] = []
	if not (section_name in _sections[scene_address]):
		_sections[scene_address].append(section_name)


func has_sections(scene_address: String) -> bool:
	return _sections.has(scene_address) and not _sections[scene_address].is_empty()


func get_sections(scene_address: String) -> Array:
	return _sections.get(scene_address, [])


func _reload_ignores() -> void:
	var ignores := _load_ignores()
	_set_ignores(ignores)


func _set_ignores(list: Array) -> void:
	_clear_ignore_list()
	for text in list:
		_add_ignore_item(text)


func _add_ignore_item(address: String) -> void:
	var item = _ignore_item.instantiate()
	item.set_address(address)
	_ignore_list.add_child(item)


func _clear_ignore_list() -> void:
	for node in _get_nodes_in_ignore_ui():
		node.queue_free()


func _get_nodes_in_ignore_ui() -> Array:
	var arr: Array = []
	for i in range(_ignore_list.get_child_count()):
		arr.append(_ignore_list.get_child(i))
	return arr


func _get_ignores_in_ignore_ui() -> Array:
	var arr: Array = []
	for node in _get_nodes_in_ignore_ui():
		arr.append(node.get_address())
	return arr


func _create_save_dic() -> Dictionary:
	var dic := {}
	var list := _get_one_list_node_by_name("All")
	if list:
		for node in list.get_list_nodes():
			var value = node.get_value()
			var sections = get_sections(value)
			var settings = {}
			for section in sections:
				var li = _get_one_list_node_by_name(section)
				if li:
					var specific_node = li.get_node_by_scene_address(value)
					if specific_node:
						settings[section] = specific_node.get_setting().as_dictionary()
			var setting = node.get_setting()
			settings["All"] = setting.as_dictionary()
			dic[node.get_key()] = {
				"value": value,
				"sections": sections,
				"settings": settings,
			}

	dic["_ignore_list"] = _get_ignores_in_ignore_ui()
	dic["_sections"] = get_all_lists_names_except(["All"])
	dic["_auto_refresh"] = _auto_refresh_button.get_meta("enabled", false)
	dic["_auto_save"] = _auto_save_button.get_meta("enabled", false)
	dic["_ignores_visible"] = _ignores_container.visible
	return dic


func _on_save_button_up() -> void:
	_clean_sections()
	_save_all(_create_save_dic())


func _clean_sections() -> void:
	var scenes: Array = get_all_lists_names_except(["All"])
	for key in _sections:
		var will_be_deleted: Array = []
		for section in _sections[key]:
			if not (section in scenes):
				will_be_deleted.append(section)
		for section in will_be_deleted:
			_sections[key].erase(section)


func get_all_lists_names_except(excepts: Array = [""]) -> Array:
	var arr: Array = []
	for i in range(len(excepts)):
		excepts[i] = excepts[i].capitalize()
	for node in _get_lists_nodes():
		if not (node.name in excepts):
			arr.append(node.name)
	return arr


func get_all_sublists_names_except(excepts: Array = [""]) -> Array:
	var section = _tab_container.get_child(_tab_container.current_tab)
	return section.get_all_sublists()


func _ignore_exists_in_list(address: String) -> bool:
	for node in _get_nodes_in_ignore_ui():
		if node.get_address() == address or address.begins_with(node.get_address()):
			return true
	return false


func _remove_scenes_begin_with(text: String) -> void:
	for node in _get_lists_nodes():
		node.remove_items_begins_with(text)


func _on_add_button_up() -> void:
	if _ignore_exists_in_list(_address_line_edit.text):
		_address_line_edit.text = ""
		return
	_add_ignore_item(_address_line_edit.text)
	_remove_scenes_begin_with(_address_line_edit.text)
	_address_line_edit.text = ""
	_add_button.disabled = true
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())


func _on_file_dialog_button_button_up() -> void:
	_file_dialog.popup_centered(Vector2(600, 600))


func _on_file_dialog_dir_file_selected(path: String) -> void:
	_address_line_edit.text = path
	_on_address_text_changed(path)


func _on_ignore_child_deleted(node: Node) -> void:
	var address: String = node.get_address()
	node.queue_free()
	var ignores: Array = []
	for ignore in _load_ignores():
		if ignore.begins_with(address) and ignore != address:
			ignores.append(ignore)
	_append_scenes(_get_scenes(address, ignores))
	await node.tree_exited
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())


func _append_scenes(scenes: Dictionary) -> void:
	_get_one_list_node_by_name("All").append_scenes(scenes)
	for list in _get_lists_nodes():
		if list.name == "All":
			continue
		for key in scenes:
			if list.name in get_sections(scenes[key]):
				await list.add_item(key, scenes[key], ItemSetting.default())


func _on_address_text_changed(new_text: String) -> void:
	if new_text != "":
		if (
			DirAccess.dir_exists_absolute(new_text)
			or (FileAccess.file_exists(new_text) and new_text.begins_with("res://"))
		):
			_add_button.disabled = false
		else:
			_add_button.disabled = true
	else:
		_add_button.disabled = true


func _on_section_name_text_changed(new_text: String) -> void:
	if new_text != "" and not (new_text.capitalize() in get_all_lists_names_except()):
		_add_section_button.disabled = false
	else:
		_add_section_button.disabled = true

	if (
		new_text != ""
		and _tab_container.get_child(_tab_container.current_tab).name != "All"
		and not (new_text.capitalize() in get_all_sublists_names_except())
	):
		_add_subsection_button.disabled = false
	else:
		_add_subsection_button.disabled = true


func _on_add_section_button_up() -> void:
	if _section_name_line_edit.text != "":
		_add_scene_list(_section_name_line_edit.text)
		_section_name_line_edit.text = ""
		_add_subsection_button.disabled = true
		_add_section_button.disabled = true
		if _auto_save_button.get_meta("enabled", false):
			_save_all(_create_save_dic())


func _on_add_subsection_button_up() -> void:
	if _section_name_line_edit.text != "":
		var section = _tab_container.get_child(_tab_container.current_tab)
		section.add_subsection(_section_name_line_edit.text)
		_section_name_line_edit.text = ""
		_add_subsection_button.disabled = true
		_add_section_button.disabled = true


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


func _on_hide_button_up() -> void:
	_hide_unhide_ignores_list(!_ignores_container.visible)
	_save_all(_create_save_dic())


func _on_tab_container_tab_changed(tab: int) -> void:
	_on_section_name_text_changed(_section_name_line_edit.text)


func _change_auto_save_state(value: bool) -> void:
	if not value:
		_save_button.disabled = false
		_auto_save_button.set_meta("enabled", false)
		_auto_save_button.icon = _hide_button_unchecked
	else:
		_auto_save_button.set_meta("enabled", true)
		_auto_save_button.icon = _hide_button_checked
	_save_button.disabled = (
		_auto_refresh_button.get_meta("enabled", true)
		and _auto_save_button.get_meta("enabled", true)
	)


func _on_auto_save_button_up() -> void:
	_change_auto_save_state(!_auto_save_button.get_meta("enabled", false))
	_save_all(_create_save_dic())


func _change_auto_refresh_state(value: bool) -> void:
	if not value:
		_auto_refresh_button.set_meta("enabled", false)
		_auto_refresh_button.icon = _folder_button_unchecked
	else:
		_auto_refresh_button.set_meta("enabled", true)
		_auto_refresh_button.icon = _folder_button_checked
	_save_button.disabled = (
		_auto_refresh_button.get_meta("enabled", true)
		and _auto_save_button.get_meta("enabled", true)
	)


func _on_auto_refresh_button_up() -> void:
	_change_auto_refresh_state(!_auto_refresh_button.get_meta("enabled", true))
	_save_all(_create_save_dic())


func _filesystem_changed() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		if _auto_refresh_button.get_meta("enabled", true):
			await _deferred_refresh()
			if _auto_save_button.get_meta("enabled", false):
				_save_all(_create_save_dic())


func show_message(title: String, description: String) -> void:
	_accept_dialog.title = title
	_accept_dialog.dialog_text = description
	_accept_dialog.popup_centered(Vector2(400, 100))


func update_all_scene_with_key(
	scene_key: String,
	scene_new_key: String,
	value: String,
	setting: ItemSetting,
	except_list: Array = []
) -> void:
	for list in _get_lists_nodes():
		if list not in except_list:
			list.update_scene_with_key(scene_key, scene_new_key, value, setting)


func check_duplication() -> void:
	var list: Array = _get_one_list_node_by_name("All").check_duplication()
	for node in _get_lists_nodes():
		node.set_reset_theme_for_all()
		if list:
			node.set_duplicate_theme(list)


func remove_scene_from_list(
	section_name: String, scene_name: String, scene_address: String
) -> void:
	var list: Node = _get_one_list_node_by_name(section_name)
	list.remove_item(scene_name, scene_address)
	_section_remove(scene_address, section_name)

	var all_list = _get_one_list_node_by_name("All")
	var setting = all_list.get_node_by_scene_address(scene_address).get_setting()
	all_list.remove_item(scene_name, scene_address)
	setting.categorized = has_sections(scene_address)
	await all_list.add_item(scene_name, scene_address, setting)


func add_scene_to_list(
	list_name: String, scene_name: String, scene_address: String, setting: ItemSetting
) -> void:
	await _add_scene_to_list(list_name, scene_name, scene_address, setting)

	var all_list = _get_one_list_node_by_name("All")
	setting = all_list.get_node_by_scene_address(scene_address).get_setting()
	all_list.remove_item(scene_name, scene_address)
	setting.categorized = has_sections(scene_address)
	await all_list.add_item(scene_name, scene_address, setting)


func _section_remove(scene_address: String, section_name: String) -> void:
	if not _sections.has(scene_address):
		return
	if section_name in _sections[scene_address]:
		_sections[scene_address].erase(section_name)
	if _sections[scene_address].is_empty():
		_sections.erase(scene_address)


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


func _on_section_removed(node: Node) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())


func _on_sub_section_removed(node: Node) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())


func _on_added_to_sub_section(node: Node, sub_section: Node) -> void:
	if _auto_save_button.get_meta("enabled", false):
		_save_all(_create_save_dic())
