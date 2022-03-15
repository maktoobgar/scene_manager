tool
extends HBoxContainer

onready var _duplicate_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_duplicate.tres")
onready var _root: Node = self
onready var _popup_menu: PopupMenu = find_node("popup_menu")
onready var _sections: Array = []

func _ready() -> void:
	while true:
		if _root != null && _root.name == "Scene Manager" || _root.name == "root_container":
			break
		_root = _root.get_parent()

func set_key(text: String) -> void:
	get_node("key").text = text
	name = text

func set_value(text: String) -> void:
	get_node("value").text = text

func get_key() -> String:
	return get_node("key").text

func get_value() -> String:
	return get_node("value").text

func get_id() -> String:
	return get_node("id").text

func get_key_node() -> Node:
	return get_node("key")

func get_sections() -> Array:
	return _sections

func set_sections(secs: Array) -> void:
	_sections = secs

func _on_key_value_text_changed(new_text):
	pass
#	var duplications = _root.get_duplications()
#	_root.all_nodes_to_default_theme()
#	if duplications != []:
#		for node in duplications:
#			var key_line_edit: LineEdit = node.get_key_node()
#			key_line_edit.add_stylebox_override("normal", _duplicate_line_edit)
#			key_line_edit.add_stylebox_override("focus", _duplicate_line_edit)

func _on_popup_button_button_up():
	var i: int = 0
	var arr: Array = _root.get_all_lists_names()
	_popup_menu.clear()
	for value in arr:
		if value == "All":
			continue
		_popup_menu.add_check_item(value)
		_popup_menu.set_item_checked(i, value in _sections)
		i += 1
	if i == 0:
		return
	_popup_menu.popup(Rect2(get_global_mouse_position(), _popup_menu.rect_size))

func _on_popup_menu_index_pressed(index: int):
	if _popup_menu.is_item_checked(index):
		_sections.append(_popup_menu.get_item_text(index))
		_root.add_scene_to_list(_popup_menu.get_item_text(index))
	else:
		_sections.remove(_sections.find(_popup_menu.get_item_text(index)))
		_root.remove_scene_from_list(_popup_menu.get_item_text(index))
