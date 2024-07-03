@tool
extends HBoxContainer

@onready var _root: Node = self

# Finds and fills `_root` variable properly
func _ready() -> void:
	while true:
		if _root == null:
			## If we are here, we are running in editor, so get out
			break
		elif _root.name == "Scene Manager" || _root.name == "menu":
			break
		_root = _root.get_parent()

# Sets address of current ignore item
func set_address(addr: String) -> void:
	get_node("address").text = addr
	name = addr

# Returns address of current ignore item
func get_address() -> String:
	return get_node("address").text

# Remove Button
func _on_remove_button_up() -> void:
	_root.emit_signal("ignore_child_deleted", self)
