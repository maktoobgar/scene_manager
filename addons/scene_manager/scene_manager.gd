extends Node

const FADE: String = "fade"
const COLOR: String = "color"
const NO_COLOR: String = "no_color"
const BLACK: Color = Color(0, 0, 0)

onready var _fade_color_rect: ColorRect = find_node("fade")
onready var _animation_player: AnimationPlayer = find_node("animation_player")
onready var _in_transition: bool = false
onready var _stack: Array = []
onready var _current_scene: String = ""
onready var _first_time: bool = true
onready var _patterns: Dictionary = {}
onready var _reserved_keys: Array = ["back", "null", "ignore", "refresh",
	"reload", "restart", "exit", "quit"]

class Options:
	# based on seconds
	var fade_speed: float = 1
	var fade_pattern: String = "fade"
	var smoothness: float = 0.1
	var inverted: bool = false

class GeneralOptions:
	var color: Color = Color(0, 0, 0)
	var timeout: float = 0
	var clickable: bool = true

# sets current scene to starting point (used for `back` functionality)
func _set_current_scene() -> void:
	var root_key: String = get_tree().current_scene.filename
	for key in Scenes.scenes:
		if key.begins_with("_"):
			continue
		if Scenes.scenes[key]["value"] == root_key:
			_current_scene = key
	assert (
		_current_scene != "",
		"Scene Manager Error: loaded scene is not defined in scene manager tool."
	)

# gets patterns from `addons/scene_manager/shader_patterns`
func _get_patterns() -> void:
	var dir = Directory.new()
	var root_path: String = "res://addons/scene_manager/shader_patterns/"
	if dir.open(root_path) == OK:
		dir.list_dir_begin(true, true)

		while true:
			var file_folder: String = dir.get_next()
			if file_folder == "":
				break
			if file_folder.get_extension() == "png":
				_patterns[file_folder.replace("."+file_folder.get_extension(), "")] = load(root_path + file_folder)

		dir.list_dir_end()

# set current scene and get patterns from `addons/scene_manager/shader_patterns` folder
func _ready() -> void:
	_set_current_scene()
	_get_patterns()

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

# activates `in_transition` mode
func _set_in_transition() -> void:
	_in_transition = true

# deactivates `in_transition` mode
func _set_out_transition() -> void:
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
	if pop:
		get_tree().change_scene(Scenes.scenes[pop]["value"])
		return true
	return false

# restart the same scene
func _refresh() -> bool:
	get_tree().change_scene(Scenes.scenes[_current_scene]["value"])
	return true

# checks different states of key and make actual transitions happen
func _change_scene(key: String) -> bool:
	if key == "back":
		return _back()

	elif key == "null" || key == "ignore" || !key:
		return false

	elif key == "reload" || key == "refresh" || key == "restart":
		return _refresh()

	elif key == "exit" || key == "quit":
		get_tree().quit(0)

	else:
		get_tree().change_scene(Scenes.scenes[key]["value"])
		_append_stack(key)
		return true
	return false

# makes menu clickable or unclickable during transitions
func _set_clickable(clickable: bool) -> void:
	if clickable:
		_fade_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_fade_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

# sets color if timeout exists
func _timeout(timeout: float) -> bool:
	if timeout != 0:
		_animation_player.play(COLOR, -1, 1, false)
		return true
	return false

# sets properties for transitions
func _set_pattern(options: Options, general_options: GeneralOptions) -> void:
	if !(options.fade_pattern in _patterns):
		options.fade_pattern = "fade"
	if options.fade_pattern == "fade":
		_fade_color_rect.material.set_shader_param("linear_fade", true)
		_fade_color_rect.material.set_shader_param("color", Vector3(general_options.color.r, general_options.color.g, general_options.color.b))
		_fade_color_rect.material.set_shader_param("custom_texture", null)
	else:
		_fade_color_rect.material.set_shader_param("linear_fade", false)
		_fade_color_rect.material.set_shader_param("custom_texture", _patterns[options.fade_pattern])
		_fade_color_rect.material.set_shader_param("inverted", options.inverted)
		_fade_color_rect.material.set_shader_param("smoothness", options.smoothness)
		_fade_color_rect.material.set_shader_param("color", Vector3(general_options.color.r, general_options.color.g, general_options.color.b))

# creates scene instance for in code usage
func create_scene_instance(key: String) -> Node:
	validate_scene(key)
	return load(Scenes.scenes[key]["value"]).instance()

# resets the `_current_scene` and clears `_stack`
func reset_scene_manager() -> void:
	_set_current_scene()
	_stack.clear()

# creates options for fade_out or fade_in transition
func create_options(fade_speed: float = 1, fade_pattern: String = "fade", smoothness: float = 0.1, inverted: bool = false) -> Options:
	var options: Options = Options.new()
	options.fade_speed = fade_speed
	options.fade_pattern = fade_pattern
	options.smoothness = smoothness
	options.inverted = inverted
	return options

# creates options for common properties in transition
func create_general_options(color: Color = Color(0, 0, 0), timeout: float = 0, clickable: bool = true) -> GeneralOptions:
	var options: GeneralOptions = GeneralOptions.new()
	options.color = color
	options.timeout = timeout
	options.clickable = clickable
	return options

# validates passed scene key
func validate_scene(key: String) -> void:
	assert(
		key in _reserved_keys || !key || Scenes.scenes.has(key) == true,
		"Scene Manager Error: `%s` key for scene is not recognized, please double check."% key
	)

# validates passed scene key
func safe_validate_scene(key: String) -> bool:
	return key in _reserved_keys || !key || Scenes.scenes.has(key) == true

# validates passed pattern key
func validate_pattern(key: String) -> void:
	assert(
		key in _patterns || key == "fade" || key == "",
		"Scene Manager Error: `%s` key for shader pattern is not recognizable, please double check."% key + "%s"%
		"\nAcceptable keys are \"%s\""% 
		String(_patterns.keys()).replace("[", "").replace("]", "").replace(", ", "\", \"") + " %s"% ", \"fade\"."
	)

# validates passed pattern key
func safe_validate_pattern(key: String) -> bool:
	return key in _patterns || key == "fade" || key == ""

# makes a fade_in transition for the first loaded scene in the game
func show_first_scene(fade_in_options: Options, general_options: GeneralOptions) -> void:
	if _first_time:
		_first_time = false
		_set_in_transition()
		_set_clickable(general_options.clickable)
		_set_pattern(fade_in_options, general_options)
		if _timeout(general_options.timeout):
			yield(get_tree().create_timer(general_options.timeout), "timeout")
		if _fade_in(fade_in_options.fade_speed):
			yield(_animation_player, "animation_finished")
		_set_clickable(true)
		_set_out_transition()

# changes current scene to the next scene
func change_scene(key: String, fade_out_options: Options, fade_in_options: Options, general_options: GeneralOptions) -> void:
	if (Scenes.scenes.has(key) || key in _reserved_keys || !key) && !_in_transition && !key.begins_with("_"):
		_first_time = false
		_set_in_transition()
		_set_clickable(general_options.clickable)
		_set_pattern(fade_out_options, general_options)
		if _fade_out(fade_out_options.fade_speed):
			yield(_animation_player, "animation_finished")
		if _change_scene(key):
			yield(get_tree(), "node_added")
		if _timeout(general_options.timeout):
			yield(get_tree().create_timer(general_options.timeout), "timeout")
		_animation_player.play(NO_COLOR, -1, 1, false)
		_set_pattern(fade_in_options, general_options)
		if _fade_in(fade_in_options.fade_speed):
			yield(_animation_player, "animation_finished")
		_set_clickable(true)
		_set_out_transition()
