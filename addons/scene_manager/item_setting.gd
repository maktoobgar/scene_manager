class_name ItemSetting

var visibility: bool = true
var categorized: bool = false

func _init(visibility = true, categorized = false) -> void:
	self.visibility = visibility
	self.categorized = categorized

func as_dictionary() -> Dictionary:
	return {
		"visibility": self.visibility,
		"categorized": self.categorized
	}

static func dictionary_to_item_setting(input: Dictionary) -> ItemSetting:
	var visibility = input["visibility"] if input.has("visibility") else true
	var categorized = input["categorized"] if input.has("categorized") else false
	return ItemSetting.new(visibility, categorized)

static func default() -> ItemSetting:
	return ItemSetting.new()

func duplicate() -> ItemSetting:
	return new(self.visibility, self.categorized)
