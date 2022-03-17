extends Node

const FADE: String = "fade"
const COLOR: String = "color"
const NO_COLOR: String = "no_color"
const BLACK: Color = Color(0, 0, 0)

onready var _menu: Dictionary = _load_scenes("res://scenes.json")
onready var _fade_color_rect: ColorRect = find_node("fade")
onready var _animation_player: AnimationPlayer = find_node("animation_player")
onready var _color: Color = Color(0, 0, 0)
onready var _in_transition: bool = false
onready var _stack: Array = []
onready var _current_scene: String = ""
onready var _first_time: bool = true
onready var _reserved_keys: Array = ["back", "null", "", "ignore", "refresh",
	"reload", "restart", "exit"]

class Options:
	# based on seconds
	var fade_out_speed: float = 1
	var fade_in_speed: float = 1
	var color: Color = Color(0, 0, 0)
	var timeout: float = 0
	var clickable: bool = true

func _set_current_scene() -> void:
	var root_key: String = get_tree().current_scene.filename
	for key in _menu:
		if typeof(_menu[key]) == TYPE_DICTIONARY:
			if _menu[key]["value"] == root_key:
				_current_scene = key
		else:
			if _menu[key] == root_key:
				_current_scene = key
	assert (
		_current_scene != "",
		"Scene Manager Error: loaded scene is not defined in scene manager tool."
	)

func _ready() -> void:
	_set_current_scene()

func _file_exists(address: String) -> void:
	assert (
		Directory.new().file_exists(address),
		"Scene Manager Error: `%s` file does not exist, please save your scenes by save button in tool gui."% address
	)

func _load_scenes(address: String) -> Dictionary:
	var data: Dictionary = {}

	_file_exists(address)
	var file = File.new()
	file.open(address, File.READ)
	var data_var = file.get_as_text()
	assert (
		validate_json(data_var) == "",
		"Scene Manager Error: `scenes.json` File is corrupted or you are comming from a lower %s"%
		"version.\nIf you are comming from a lower version than 1.2.0, clean your %s"%
		"`scenes.json` file to look like a clean, valid json file(like: `{data}`) %s"%
		"and then run your game again."
	)

	data = parse_json(data_var)

	if data.has("_ignore_list"):
		data.erase("_ignore_list")
	if data.has("_sections"):
		data.erase("_sections")
	file.close()

	return data

# actual change of color
func _process(delta):
	_fade_color_rect.color = Color(_color.r, _color.g, _color.b, _fade_color_rect.color.a)

# `speed` unit is in seconds
func _fade_in(speed: float) -> bool:
	if speed == 0:
		return false
	_animation_player.play(FADE, -1, 1 / speed, false)
	return true

# `speed` unit is in seconds
func _fade_out(speed: float) -> bool:
	if speed == 0:
		return false
	_animation_player.play(FADE, -1, -1 / speed, true)
	return true

# sets the new color
func _set_color(color: Color = Color(0, 0, 0)) -> void:
	_color = color

# activates `in_transition` mode
func _set_in_transition() -> void:
	set_process(true)
	_in_transition = true

# deactivates `in_transition` mode
func _set_out_transition() -> void:
	yield(get_tree(), "idle_frame")
	set_process(false)
	_in_transition = false

# adds current scene to `_stack`
func _append_stack(key: String) -> void:
	_stack.append(_current_scene)
	_current_scene = key

# pops latest added scene
func _pop_stack() -> String:
	var pop = _stack.pop_back()
	if pop:
		_current_scene = pop
	return _current_scene

# changes scene to the previous scene
func _back() -> bool:
	var pop: String = _pop_stack()
	if pop && typeof(_menu[pop]) == TYPE_DICTIONARY:
		get_tree().change_scene(_menu[pop]["value"])
		return true
	elif pop:
		get_tree().change_scene(_menu[pop])
		return true
	return false

# restart the same scene
func _refresh() -> bool:
	if typeof(_menu[_current_scene]) == TYPE_DICTIONARY:
		get_tree().change_scene(_menu[_current_scene]["value"])
	else:
		get_tree().change_scene(_menu[_current_scene])
	return true

# checks different states of key and make actual transitions happen
func _change_scene(key: String) -> bool:
	if key == "back":
		return _back()

	elif key == "null" || key == "ignore" || !key:
		return false

	elif key == "reload" || key == "refresh" || key == "restart":
		return _refresh()

	elif key == "exit":
		get_tree().quit(0)

	else:
		if typeof(_menu[key]) == TYPE_DICTIONARY:
			get_tree().change_scene(_menu[key]["value"])
		else:
			get_tree().change_scene(_menu[key])
		_append_stack(key)
		return true
	return false

func _set_clickable(clickable: bool) -> void:
	if clickable:
		_fade_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_fade_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

func _timeout(timeout: float) -> bool:
	if timeout != 0:
		_animation_player.play(COLOR, -1, 1, false)
		return true
	return false

# resets the `_current_scene` and clears `_stack`
func reset_scene_manager() -> void:
	_set_current_scene()
	_stack.clear()

func create_options(fade_out_speed: float = 1, fade_in_speed: float = 1,
  color: Color = BLACK, timeout: float = 0, clickable: bool = true) -> Options:
	var options: Options = Options.new()
	options.fade_out_speed = fade_out_speed
	options.fade_in_speed = fade_in_speed
	options.color = color
	options.timeout = timeout
	options.clickable = clickable
	return options

func validate_key(key: String) -> void:
	if key in _reserved_keys:
		return
	assert(
		_menu.has(key) == true,
		"Scene Manager Error: `%s` key is not recognized, please double check."% key
	)

func show_first_scene(options: Options) -> void:
	if _first_time:
		_set_in_transition()
		_set_color(options.color)
		_set_clickable(options.clickable)
		yield(get_tree().create_timer(options.timeout), "timeout")
		if _fade_in(options.fade_in_speed):
			yield(_animation_player, "animation_finished")
		_set_clickable(true)
		_set_out_transition()
		_first_time = false

func change_scene(key: String, options: Options) -> void:
	if (_menu.has(key) || key in _reserved_keys) && !_in_transition:
		_first_time = false
		_set_in_transition()
		_set_color(options.color)
		_set_clickable(options.clickable)
		if _fade_out(options.fade_out_speed):
			yield(_animation_player, "animation_finished")
		if _change_scene(key):
			yield(get_tree(), "node_added")
		if _timeout(options.timeout):
			yield(get_tree().create_timer(options.timeout), "timeout")
		_animation_player.play(NO_COLOR, -1, 1, false)
		if _fade_in(options.fade_in_speed):
			yield(_animation_player, "animation_finished")
		_set_clickable(true)
		_set_out_transition()
