tool
extends HBoxContainer


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
