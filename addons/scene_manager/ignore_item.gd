tool
extends HBoxContainer

onready var _root: Node = self

func _ready() -> void:
	while true:
		if _root.name == "Scene Manager" || _root.name == "root_container":
			break
		_root = _root.get_parent()

func set_address(addr: String) -> void:
	get_node("address").text = addr
	name = addr

func get_address() -> String:
	return get_node("address").text

func _on_remove_button_up() -> void:
	_root.emit_signal("delete_ignore_child", self)
