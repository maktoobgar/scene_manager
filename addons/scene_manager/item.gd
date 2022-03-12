tool
extends HBoxContainer

var _duplicate_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_duplicate.tres")
onready var _list_node: Node = get_parent()

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
	var parent_node = _list_node.get_duplications(new_text, self)
	if parent_node != null:
		var node: Node = parent_node.get_key_node()
		var me: Node = self.get_key_node()
		node.add_stylebox_override("normal", _duplicate_line_edit)
		me.add_stylebox_override("normal", _duplicate_line_edit)
		node.add_stylebox_override("focus", _duplicate_line_edit)
		me.add_stylebox_override("focus", _duplicate_line_edit)
		return
	else:
		_list_node.all_nodes_to_default_theme()
	_list_node.check_if_saved_values_are_same_with_view()
