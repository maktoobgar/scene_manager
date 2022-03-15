tool
extends HBoxContainer

onready var _duplicate_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_duplicate.tres")
onready var _root: Node = self

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

func set_id(text: String) -> void:
	get_node("id").text = text

func get_key() -> String:
	return get_node("key").text

func get_value() -> String:
	return get_node("value").text

func get_id() -> String:
	return get_node("id").text

func get_key_node() -> Node:
	return get_node("key")

func _on_key_value_text_changed(new_text):
	var duplications = _root.get_duplications()
	_root.all_nodes_to_default_theme()
	if duplications != []:
		for node in duplications:
			var key_line_edit: LineEdit = node.get_key_node()
			key_line_edit.add_stylebox_override("normal", _duplicate_line_edit)
			key_line_edit.add_stylebox_override("focus", _duplicate_line_edit)
	_root.check_if_saved_values_are_same_with_view()
