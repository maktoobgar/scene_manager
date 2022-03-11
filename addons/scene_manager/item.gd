tool
extends HBoxContainer

var normal_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_normal.tres")
var duplicate_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_duplicate.tres")

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
	var parent_node = get_parent().get_duplications(new_text, self)
	if parent_node != null:
		var node: Node = parent_node.get_key_node()
		var me: Node = self.get_key_node()
		node.add_stylebox_override("normal", duplicate_line_edit)
		me.add_stylebox_override("normal", duplicate_line_edit)
		node.add_stylebox_override("focus", duplicate_line_edit)
		me.add_stylebox_override("focus", duplicate_line_edit)
		return
	else:
		get_parent().all_nodes_to_default_theme()
	get_parent().check_if_saved_values_are_same_with_view()
