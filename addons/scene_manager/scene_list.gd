@tool
extends Node

# Constants for scene items and subsections
const _scene_item = preload("res://addons/scene_manager/scene_item.tscn")
const _sub_section = preload("res://addons/scene_manager/sub_section.tscn")
const _duplicate_line_edit: StyleBox = preload(
	"res://addons/scene_manager/themes/line_edit_duplicate.tres"
)
const _eye_open = preload("res://addons/scene_manager/icons/eye_open.png")
const _eye_close = preload("res://addons/scene_manager/icons/eye_close.png")

# Node references
@onready var _container: VBoxContainer = find_child("container")
@onready var _delete_list_button: Button = find_child("delete_list")
@onready var _hidden_button: Button = find_child("hidden")

# Instance variables
var _root: Node = self
var _main_subsection: Node = null
var _secondary_subsection: Node = null

# Optimization: Object pooling
var _scene_item_pool: Array[Node] = []
const POOL_SIZE := 50  # Adjust based on typical usage

# Optimization: Caching
var _node_cache: Dictionary = {}
var _subsection_cache: Dictionary = {}
var _is_initialized := false

# Optimization: Batch processing
const BATCH_SIZE := 20


func _ready() -> void:
	_initialize_root()

	# Initialize based on list type
	if self.name == "All":
		_initialize_all_list()
	else:
		_initialize_regular_list()

	# Pre-populate object pool
	_initialize_object_pool()

	_is_initialized = true


func _initialize_root() -> void:
	while _root != null:
		if _root.name == "Scene Manager" || _root.name == "menu":
			break
		_root = _root.get_parent()
		if _root == null:
			break


func _initialize_all_list() -> void:
	_delete_list_button.icon = null
	_delete_list_button.disabled = true
	_delete_list_button.focus_mode = Control.FOCUS_NONE

	_main_subsection = _create_subsection("Uncategorized", true)
	_main_subsection.open()
	_main_subsection.hide_delete_button()

	_secondary_subsection = _create_subsection("Categorized", false)
	_secondary_subsection.hide_delete_button()


func _initialize_regular_list() -> void:
	var sub = _create_subsection("All", false)
	sub.open()
	sub.hide_delete_button()
	_main_subsection = sub


func _initialize_object_pool() -> void:
	for i in range(POOL_SIZE):
		var item = _scene_item.instantiate()
		_scene_item_pool.append(item)


func _create_subsection(name: String, is_open: bool) -> Node:
	var sub = _sub_section.instantiate()
	sub._root = _root
	sub.name = name
	_container.add_child(sub)
	if is_open:
		sub.open()
	return sub


# Optimization: Object pooling methods
func _get_scene_item() -> Node:
	if _scene_item_pool.is_empty():
		return _scene_item.instantiate()
	return _scene_item_pool.pop_back()


func _return_to_pool(item: Node) -> void:
	if _scene_item_pool.size() < POOL_SIZE:
		item.get_parent().remove_child(item)
		_scene_item_pool.append(item)
	else:
		item.queue_free()


# Optimization: Batch processing for adding items
func add_items_batch(items: Array) -> void:
	var current_batch := []

	for i in range(items.size()):
		current_batch.append(items[i])

		if current_batch.size() >= BATCH_SIZE || i == items.size() - 1:
			for item_data in current_batch:
				add_item(item_data.key, item_data.value, item_data.setting)
			await get_tree().process_frame
			current_batch.clear()


func add_item(key: String, value: String, setting: ItemSetting) -> void:
	if !self.is_node_ready():
		await self.ready

	var item = _get_scene_item()
	item.set_key(key)
	item.set_value(value)
	item.set_setting(setting)
	item.visible = determine_item_visibility(setting)
	item._list = self

	# Cache the item for faster lookups
	_node_cache[value] = item

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


func determine_item_visibility(setting: ItemSetting) -> bool:
	if _hidden_button.icon == _eye_close:
		return !setting.visibility
	return setting.visibility


# Optimization: Cached subsection lookup
func find_subsection(key: String) -> Node:
	if _subsection_cache.has(key):
		return _subsection_cache[key]

	for child in _container.get_children():
		if child.name == key:
			_subsection_cache[key] = child
			return child
	return null


func remove_item(key: String, value: String) -> void:
	# Use cached lookup if available
	if _node_cache.has(value):
		var item = _node_cache[value]
		_node_cache.erase(value)
		_return_to_pool(item)
		return

	# Fallback to manual search
	for subsection in _container.get_children():
		var items = subsection.get_items()
		for item in items:
			if item.get_key() == key && item.get_value() == value:
				_return_to_pool(item)
				return


func remove_items_begins_with(value: String) -> void:
	var items_to_remove := []

	# Collect all items to remove first
	for subsection in _container.get_children():
		var items = subsection.get_items()
		for item in items:
			if item.get_value().begins_with(value):
				items_to_remove.append(item)

	# Then remove them in batch
	for item in items_to_remove:
		_return_to_pool(item)
		if _node_cache.has(item.get_value()):
			_node_cache.erase(item.get_value())


func clear_list() -> void:
	_node_cache.clear()
	_subsection_cache.clear()

	for child in _container.get_children():
		child.queue_free()


func append_scenes(nodes: Dictionary) -> void:
	var items_to_add := []

	for key in nodes:
		var setting = (
			ItemSetting.new(true, _root.has_sections(nodes[key]))
			if name == "All"
			else ItemSetting.default()
		)
		items_to_add.append({"key": key, "value": nodes[key], "setting": setting})

	add_items_batch(items_to_add)


# Optimization: Cached node lookup
func get_node_by_scene_address(scene_address: String) -> Node:
	return _node_cache.get(scene_address)


func get_node_by_scene_name(scene_name: String) -> Node:
	for value in _node_cache:
		var node = _node_cache[value]
		if node.get_key() == scene_name:
			return node
	return null


func update_scene_with_key(
	key: String, new_key: String, value: String, setting: ItemSetting
) -> void:
	if _node_cache.has(value):
		var node = _node_cache[value]
		if node.get_key() == key:
			node.set_key(new_key)
			node.set_setting(setting)
			return

	# Fallback to manual search if not in cache
	for subsection in _container.get_children():
		var items = subsection.get_items()
		for item in items:
			if item.get_key() == key && item.get_value() == value:
				item.set_key(new_key)
				item.set_setting(setting)
				return


func check_duplication() -> Array:
	var key_map := {}
	var duplicates: Array[String] = []

	for value in _node_cache:
		var node = _node_cache[value]
		var key = node.get_key()

		if key_map.has(key):
			if !(key in duplicates):
				duplicates.append(key)
		else:
			key_map[key] = true

	return duplicates


func set_reset_theme_for_all() -> void:
	for node in _node_cache.values():
		node.remove_custom_theme()


func set_duplicate_theme(list: Array) -> void:
	for node in _node_cache.values():
		if node.get_key() in list:
			node.custom_set_theme(_duplicate_line_edit)


func get_all_sublists() -> Array:
	return _container.get_children().map(func(child): return child.name)


func add_subsection(text: String) -> Control:
	var sub = _sub_section.instantiate()
	sub._root = _root
	sub.name = text.capitalize()
	_container.add_child(sub)
	_subsection_cache[text.capitalize()] = sub
	return sub


func _on_delete_list_button_up() -> void:
	if self.name == "All":
		return
	queue_free()
	await self.tree_exited
	_root.section_removed.emit(self)


func _refresh_visible_of_all_items() -> void:
	for node in _node_cache.values():
		node.visible = determine_item_visibility(node.get_setting())


func _on_hidden_button_up() -> void:
	_hidden_button.icon = _eye_close if _hidden_button.icon == _eye_open else _eye_open
	_refresh_visible_of_all_items()


func get_list_nodes() -> Array:
	return _node_cache.values()
