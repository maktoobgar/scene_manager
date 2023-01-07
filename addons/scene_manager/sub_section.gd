@tool
extends Node

# Nodes
@onready var button: Button = find_child("Button")
@onready var list: VBoxContainer = find_child("List")
# Open close icons
const _open = preload("res://addons/scene_manager/icons/GuiOptionArrowDown.svg")
const _close = preload("res://addons/scene_manager/icons/GuiOptionArrowRight.png")

# If it is "All" subsection, open it
func _ready() -> void:
	button.text = name

# Add child
func add_item(item: Node) -> void:
	list.add_child(item)

# Open list
func open() -> void:
	list.visible = true
	button.icon = _open

# Close list
func close() -> void:
	list.visible = false
	button.icon = _close

# Returns list of items
func get_items() -> Array:
	return list.get_children()

# Close Open Functionality
func _on_button_up():
	if button.icon == _open:
		close()
	else:
		open()
