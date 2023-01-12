class_name ItemSetting

var visibility: bool = true
var categorized: bool = false
var subsection: String = ""

func _init(visibility = true, categorized = false, subsection = "") -> void:
	self.visibility = visibility
	self.categorized = categorized
	self.subsection = subsection

func as_dictionary() -> Dictionary:
	return {
		"visibility": self.visibility,
		"subsection": self.subsection,
	}

static func dictionary_to_item_setting(input: Dictionary) -> ItemSetting:
	var visibility = input["visibility"] if input.has("visibility") else true
	var subsection = input["subsection"] if input.has("subsection") else ""
	return ItemSetting.new(visibility, false, subsection)

static func default() -> ItemSetting:
	return ItemSetting.new()

func duplicate() -> ItemSetting:
	return new(self.visibility, self.categorized, self.subsection)
