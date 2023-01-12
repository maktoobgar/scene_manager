@tool
extends Button

# Get and return drag data
func _get_drag_data(at_position: Vector2) -> Variant:
	return get_parent()._get_drag_data(at_position)
