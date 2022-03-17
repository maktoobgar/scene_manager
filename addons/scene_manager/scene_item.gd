tool
extends HBoxContainer

onready var _root: Node = self
onready var _popup_menu: PopupMenu = find_node("popup_menu")
onready var _key: String = get_node("key").text

func _ready() -> void:
	while true:
		if _root != null && _root.name == "Scene Manager" || _root.name == "root_container":
			break
		_root = _root.get_parent()

func set_key(text: String) -> void:
	get_node("key").text = text
	name = text
	_key = text

func set_value(text: String) -> void:
	get_node("value").text = text

func get_key() -> String:
	return get_node("key").text

func get_value() -> String:
	return get_node("value").text

func get_key_node() -> Node:
	return get_node("key")

func custom_set_theme(theme: StyleBox) -> void:
	get_key_node().add_stylebox_override("normal", theme)
	get_key_node().add_stylebox_override("focus", theme)

func _on_popup_button_button_up():
	var i: int = 0
	var arr: Array = _root.get_all_lists_names()
	_popup_menu.clear()
	for value in arr:
		if value == "All":
			continue
		_popup_menu.add_check_item(value)
		_popup_menu.set_item_checked(i, value in _root.get_section(get_value()))
		i += 1
	if i == 0:
		return
	_popup_menu.popup(Rect2(get_global_mouse_position(), _popup_menu.rect_size))

func _on_popup_menu_index_pressed(index: int):
	_popup_menu.set_item_checked(index, !_popup_menu.is_item_checked(index))
	if _popup_menu.is_item_checked(index):
		_root.add_scene_to_list(_popup_menu.get_item_text(index), get_key(), get_value())
	else:
		_root.remove_scene_from_list(_popup_menu.get_item_text(index), get_key(), get_value())

func _on_key_value_text_changed() -> void:
	_root.update_all_scene_with_key(_key, get_key(), get_value(), get_parent().get_parent())

func _show_message() -> void:
	_root.show_message("Error", "\"%s\" and an empty string(\"\"), or every other word which will "%
		String(_root.reserved_keys).replace("[", "").replace("]", "").replace(", ", "\", \"") +
		"begin with an '_', are reserved or not allowed to be used as a scene key so please do not use them " +
		"to avoid seeing weird reaction from Scene Manager tool.")

func _check_reserved_keys() -> void:
	if !get_key() || get_key().begins_with("_") || get_key() in _root.reserved_keys:
		_show_message()

func _on_key_gui_input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed():
		if !get_key():
			_show_message()
		elif get_key() != _key:
			_check_reserved_keys()
			_on_key_value_text_changed()
			_key = get_key()
			_root.check_duplication()
