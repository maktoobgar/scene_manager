@tool
extends Control

# Nodes
@onready var button: Button = find_child("Button")
@onready var delete_button: Button = find_child("Delete")
@onready var list: VBoxContainer = find_child("List")
# Open close icons
const _open = preload("res://addons/scene_manager/icons/GuiOptionArrowDown.svg")
const _close = preload("res://addons/scene_manager/icons/GuiOptionArrowRight.png")
# Instances
const _scene_item = preload("res://addons/scene_manager/scene_item.tscn")

# If it is "All" subsection, open it
func _ready() -> void:
	button.text = name
	if name == "All" && get_child_count() == 0:
		visible = false

# Add child
func add_item(item: Node) -> void:
	item._sub_section = self
	list.add_child(item)

# Removes an item from list
func remove_item(item: Node) -> void:
	list.remove_child(item)

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

# Action on child counting
func _check_count():
	if list.get_child_count() == 0:
		if name == "All":
			visible = false
		else:
			enable_delete_button()
	else:
		if name == "All":
			visible = true
		else:
			disable_delete_button()

# When a node adds
func child_entered():
	_check_count()

# When a node removes
func child_exited():
	_check_count()

# Hides delete button of subsection
func hide_delete_button():
	delete_button.visible = false

# Disables delete button
func disable_delete_button():
	delete_button.disabled = true

# Enables delete button
func enable_delete_button():
	delete_button.disabled = false

# Returns if we can drop here or not
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if !(data is Dictionary):
		return false
	data = data as Dictionary
	return data.has("node") && data.has("parent")

# Function to actually do the dropping
func _drop_data(at_position: Vector2, data: Variant) -> void:
	data = data as Dictionary
	var parent = data["parent"] as Node
	var node = data["node"] as Node
	var setting = node.get_setting() as ItemSetting
	if parent == self:
		return
	parent.remove_item(node)
	setting.subsection = name
	node.set_setting(setting)
	node.set_subsection(self)
	add_item(node)
	open()

# Button Delete 
func _on_delete_button_up():
	queue_free()
