extends Object
class_name ItemSetting

var visibility: bool = true

func _init(visibility = true) -> void:
	self.visibility = visibility

func as_dictionary() -> Dictionary:
	return {
		"visibility": self.visibility
	}

static func dictionary_to_item_setting(input: Dictionary) -> ItemSetting:
	var visibility = input["visibility"] if input.has("visibility") else true
	return ItemSetting.new(visibility)

static func default() -> ItemSetting:
	return ItemSetting.new(true)
