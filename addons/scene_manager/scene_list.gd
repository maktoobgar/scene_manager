tool
extends ScrollContainer

onready var _id: int = 1
onready var _container: VBoxContainer = find_node("container")
onready var _scene_item = preload("res://addons/scene_manager/scene_item.tscn")

func add_item(key: String, value: String) -> void:
	var item = _scene_item.instance()
	item.set_key(key)
	item.set_value(value)
	_container.add_child(item)
	_id += 1

func remove_item(key: String, value: String) -> void:
	for i in range(self.get_child_count()):
		if i == 0:
			continue
		var child: Node = self.get_child(i)
		if child.get_key() == key && child.get_value() == value:
			child.queue_free()
			return

func clear_scene_list() -> void:
	for i in range(_container.get_child_count()):
		if i == 0:
			continue
		_container.get_child(i).queue_free()

func append_scenes(nodes: Dictionary) -> void:
	for key in nodes:
		add_item(key, nodes[key]["value"])
