@tool
extends Button

# Can drop here
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return get_parent().get_parent()._can_drop_data(at_position, data)

# Drop here
func _drop_data(at_position: Vector2, data: Variant) -> void:
	get_parent().get_parent()._drop_data(at_position, data)
