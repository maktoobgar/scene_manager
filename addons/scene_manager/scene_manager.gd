extends Node

# consts
const FADE: String = "fade"
const COLOR: String = "color"
const NO_COLOR: String = "no_color"
const BLACK: Color = Color(0, 0, 0)
# variables
@onready var _fade_color_rect: ColorRect = find_child("fade")
@onready var _animation_player: AnimationPlayer = find_child("animation_player")
@onready var _in_transition: bool = false
@onready var _stack: Array = []
@onready var _stack_limit: int = -1
@onready var _current_scene: String = ""
@onready var _first_time: bool = true
@onready var _patterns: Dictionary = {}
@onready var _reserved_keys: Array = ["back", "null", "ignore", "refresh",
	"reload", "restart", "exit", "quit"]
var _load_scene: String = ""
var _load_progress: Array = []
var _recorded_scene: String = ""
# signals
signal load_finished
signal load_percent_changed(value: int)
signal scene_changed
signal fade_in_started
signal fade_out_started
signal fade_in_finished
signal fade_out_finished

class Options:
	# based checked seconds
	var fade_speed: float = 1
	var fade_pattern: String = "fade"
	var smoothness: float = 0.1
	var inverted: bool = false

class GeneralOptions:
	var color: Color = Color(0, 0, 0)
	var timeout: float = 0
	var clickable: bool = true
	var add_to_back: bool = true

func _current_scene_is_ignored(scene_file_path: String) -> bool:
	for ignore_path in Scenes.scenes._ignore_list:
		if scene_file_path.begins_with(ignore_path):
			return true
	return false

# sets current scene to starting point (used for `back` functionality)
func _set_current_scene() -> void:
	var scene_file_path: String = get_tree().current_scene.scene_file_path
	_current_scene = _get_scene_key_by_value(scene_file_path)

	assert (!(_current_scene == "" and !_current_scene_is_ignored(scene_file_path)), "Scene Manager Error: loaded scene is not defined in scene manager tool, to fix this, on Scene Manager UI panel, just once click on refresh and then save buttons respectively.")
	if _current_scene == "":
		push_warning("loaded scene is ignored by scene manager, it means that you can not go back to this scene by 'back' key word.")

# gets patterns from `addons/scene_manager/shader_patterns`
func _get_patterns() -> void:
	var root_path: String = "res://addons/scene_manager/shader_patterns/"
	var dir := DirAccess.open(root_path)
	if dir:
		dir.list_dir_begin()

		while true:
			var file_folder: String = dir.get_next()
			if file_folder == "":
				break
			elif file_folder.get_extension() == "import":
				file_folder = file_folder.replace(".import", "")
			if file_folder.get_extension() == "png":
				var key = file_folder.replace("."+file_folder.get_extension(), "")
				if !(key in _patterns.keys()):
					_patterns[key] = load(root_path + file_folder)

		dir.list_dir_end()

# set current scene and get patterns from `addons/scene_manager/shader_patterns` folder
func _ready() -> void:
	set_process(false)
	_set_current_scene()
	_get_patterns()

# `speed` unit is in seconds
func _fade_in(speed: float) -> bool:
	if speed == 0:
		return false
	fade_in_started.emit()
	_animation_player.play(FADE, -1, 1 / speed, false)
	return true

# `speed` unit is in seconds
func _fade_out(speed: float) -> bool:
	if speed == 0:
		return false
	fade_out_started.emit()
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
	if _stack_limit == -1:
		_stack.append(_current_scene)
	elif _stack_limit > 0:
		if _stack_limit <= len(_stack):
			for i in range(len(_stack) - _stack_limit + 1):
				_stack.pop_front()
			_stack.append(_current_scene)
		else:
			_stack.append(_current_scene)
	_current_scene = key

# pops most recent added scene to `_stack`
func _pop_stack() -> String:
	var pop = _stack.pop_back()
	if pop:
		_current_scene = pop
	return _current_scene

# changes scene to the previous scene
func _back() -> bool:
	var pop: String = _pop_stack()
	if pop:
		get_tree().change_scene_to_file(Scenes.scenes[pop]["value"])
		return true
	return false

# returns the scene key of the passed scene value (scene address)
func _get_scene_key_by_value(path: String) -> String:
	var found_key = ""
	for key in Scenes.scenes:
		if key.begins_with("_"):
			continue
		if Scenes.scenes[key]["value"] == path:
			found_key = key
	return found_key

# restart the same scene
func _refresh() -> bool:
	get_tree().change_scene_to_file(Scenes.scenes[_current_scene]["value"])
	return true

# checks different states of scene and make actual transitions happen
func _change_scene(scene, add_to_back: bool) -> bool:
	# when scenes get instanciate, they will loose their `scene_instance.scene_file_path`
	# varialbe value which is used to reload the current scene again in this addon and that's
	# why I'm fixing this up by hand and I'm not using `get_tree().change_scene_to_packed()`
	# fuction in here
	if scene is PackedScene:
		scene.get_local_scene()
		var scene_instance = scene.instantiate()
		var root = get_tree().get_root()
		get_tree().get_current_scene().free()
		root.add_child(scene_instance)
		get_tree().set_current_scene(scene_instance)
		if (_load_scene == ""):
			assert(false, "Scene Manager Error: please use this addon as described")
		var path: String = _load_scene
		var found_key: String = _get_scene_key_by_value(path)
		scene_instance.scene_file_path = _load_scene
		if add_to_back && found_key != "":
			_append_stack(found_key)
		_load_scene = ""
		return true

	if scene is Node:
		var root = get_tree().get_root()
		get_tree().get_current_scene().free()
		root.add_child(scene)
		get_tree().set_current_scene(scene)
		var path: String = scene.scene_file_path
		var found_key: String = _get_scene_key_by_value(path)
		if add_to_back && found_key != "":
			_append_stack(found_key)
		return true

	if scene == "back":
		return _back()

	elif scene == "null" || scene == "ignore" || scene == "":
		return false

	elif scene == "reload" || scene == "refresh" || scene == "restart":
		return _refresh()

	elif scene == "exit" || scene == "quit":
		get_tree().quit(0)

	else:
		get_tree().change_scene_to_file(Scenes.scenes[scene]["value"])
		if add_to_back:
			_append_stack(scene)
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
		_fade_color_rect.material.set_shader_parameter("linear_fade", true)
		_fade_color_rect.material.set_shader_parameter("color", Vector3(general_options.color.r, general_options.color.g, general_options.color.b))
		_fade_color_rect.material.set_shader_parameter("custom_texture", null)
	else:
		_fade_color_rect.material.set_shader_parameter("linear_fade", false)
		_fade_color_rect.material.set_shader_parameter("custom_texture", _patterns[options.fade_pattern])
		_fade_color_rect.material.set_shader_parameter("inverted", options.inverted)
		_fade_color_rect.material.set_shader_parameter("smoothness", options.smoothness)
		_fade_color_rect.material.set_shader_parameter("color", Vector3(general_options.color.r, general_options.color.g, general_options.color.b))

# used for interactive change scene
func _process(_delta: float):
	var prevPercent: int = 0
	if len(_load_progress) != 0:
		prevPercent = int(_load_progress[0] * 100)
	var status = ResourceLoader.load_threaded_get_status(_load_scene, _load_progress)
	var nextPercent: int = int(_load_progress[0] * 100)
	if prevPercent != nextPercent:
		load_percent_changed.emit(nextPercent)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		_load_progress = []
		load_finished.emit()
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass
	else:
		assert(false, "Scene Manager Error: for some reason, loading failed, I don't know why")

# limits how much deep scene manager is allowed to record previous scenes which
# affects in changing scene to `back`(previous scene) functionality
#
# allowed `input` values:
# input = -1 => unlimited (default)
# input =  0 => we can not go back to any previos scenes
# input >  0 => we can go back to `input` or less previous scenes
func set_back_limit(input: int) -> void:
	assert(input >= -1, "Scene Manager Error: input must to >= -1")
	_stack_limit = input
	if input == 0:
		_stack.clear()
	elif input > 0:
		if input <= len(_stack):
			for i in range(len(_stack) - input):
				_stack.pop_front()

# resets the `_current_scene` and clears `_stack`
func reset_scene_manager() -> void:
	_set_current_scene()
	_stack.clear()

# creates options for fade_out or fade_in transition
func create_options(fade_speed: float = 1.0, fade_pattern: String = "fade", smoothness: float = 0.1, inverted: bool = false) -> Options:
	var options: Options = Options.new()
	options.fade_speed = fade_speed
	options.fade_pattern = fade_pattern
	options.smoothness = smoothness
	options.inverted = inverted
	return options

# creates options for common properties in transition
# add_to_back means that you can go back to the scene if you
# change scene to `back` scene
func create_general_options(color: Color = Color(0, 0, 0), timeout: float = 0.0, clickable: bool = true, add_to_back: bool = true) -> GeneralOptions:
	var options: GeneralOptions = GeneralOptions.new()
	options.color = color
	options.timeout = timeout
	options.clickable = clickable
	options.add_to_back = add_to_back
	return options

# validates passed scene key
func validate_scene(key: String) -> void:
	assert((key in _reserved_keys || key == "" || Scenes.scenes.has(key) == true) && !key.begins_with("_"), "Scene Manager Error: `%s` key is not recognized, please double check. You may have the scene in your File System but Scene Manager has no idea, clicking refresh and then save buttons respectively may fix the problem."% key)

# validates passed scene key
func safe_validate_scene(key: String) -> bool:
	return (key in _reserved_keys || key == "" || Scenes.scenes.has(key) == true) && !key.begins_with("_")

# validates passed pattern key
func validate_pattern(key: String) -> void:
	var errorPart1 := "Scene Manager Error: `%s` key for shader pattern is not recognizable, please double check.\n"% key
	var keys := _patterns.keys()
	var stringKeys := ""

	for i in range(0,keys.size()):
		if i == 0:
			stringKeys = "\"%s\"" % keys[0]
			continue
		stringKeys += ", \"%s\"" % keys[i]
	var errorPart2 := "Acceptable keys are \"%s\" , \"fade\"."%stringKeys
	assert(key in _patterns || key == "fade" || key == "",errorPart1 + errorPart2)

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
			await get_tree().create_timer(general_options.timeout).timeout
		if _fade_in(fade_in_options.fade_speed):
			await _animation_player.animation_finished
			fade_in_finished.emit()
		_set_clickable(true)
		_set_out_transition()

# returns scene instance of passed scene key (blocking)
#
# Note: you can activate `use_sub_threads` but just know that In the newest 
# versions of Godot there seems to be a bug that can cause a threadlock in
# the resource loader that will result in infinite loading of the scene 
# without any error.
#
# Related Github Issues About `use_sub_threads`:
#
# https://github.com/godotengine/godot/issues/85255
# https://github.com/godotengine/godot/issues/84012
func create_scene_instance(key: String, use_sub_threads = false) -> Node:
	return get_scene(key, use_sub_threads).instantiate()

# returns PackedScene of passed scene key (blocking)
#
# Note: you can activate `use_sub_threads` but just know that In the newest 
# versions of Godot there seems to be a bug that can cause a threadlock in
# the resource loader that will result in infinite loading of the scene 
# without any error.
#
# Related Github Issues About `use_sub_threads`:
#
# https://github.com/godotengine/godot/issues/85255
# https://github.com/godotengine/godot/issues/84012
func get_scene(key: String, use_sub_threads = false) -> PackedScene:
	validate_scene(key)
	var address = Scenes.scenes[key]["value"]
	ResourceLoader.load_threaded_request(address, "", use_sub_threads, ResourceLoader.CACHE_MODE_REUSE)
	return ResourceLoader.load_threaded_get(address)

# changes current scene to the next scene
func change_scene(scene, fade_out_options: Options, fade_in_options: Options, general_options: GeneralOptions) -> void:
	if (scene is PackedScene || scene is Node || (typeof(scene) == TYPE_STRING && safe_validate_scene(scene) && !_in_transition)):
		_first_time = false
		_set_in_transition()
		_set_clickable(general_options.clickable)
		_set_pattern(fade_out_options, general_options)
		if _fade_out(fade_out_options.fade_speed):
			await _animation_player.animation_finished
			fade_out_finished.emit()
		if _change_scene(scene, general_options.add_to_back):
			if !(scene is Node || scene is PackedScene):
				await get_tree().node_added
			scene_changed.emit()
		if _timeout(general_options.timeout):
			await get_tree().create_timer(general_options.timeout).timeout
		_animation_player.play(NO_COLOR, -1, 1, false)
		_set_pattern(fade_in_options, general_options)
		if _fade_in(fade_in_options.fade_speed):
			await _animation_player.animation_finished
			fade_in_finished.emit()
		_set_clickable(true)
		_set_out_transition()

# Change scene with no effect
func no_effect_change_scene(scene, hold_timeout: float = 0.0, add_to_back: bool = true):
	if (scene is PackedScene || scene is Node || (typeof(scene) == TYPE_STRING && safe_validate_scene(scene) && !_in_transition)):
		_first_time = false
		_set_in_transition()
		await get_tree().create_timer(hold_timeout).timeout
		if _change_scene(scene, add_to_back):
			if !(scene is Node):
				await get_tree().node_added
		_set_out_transition()

# imports loaded scene into the scene tree but doesn't change the scene
# maily used when your new loaded scene has a loading phase when added to scene tree
# so to use this, first has to call `load_scene_interactive` to load your scene
# and then have to listen on `load_finished` signal and after the signal emits,
# you call this function and this function adds the loaded scene to the scene
# tree but exactly behind the current scene so that you still can not see the new scene
func add_loaded_scene_to_scene_tree() -> void:
	if _load_scene != "":
		var scene_resource = ResourceLoader.load_threaded_get(_load_scene) as PackedScene
		if scene_resource:
			var scene = scene_resource.instantiate()
			scene.scene_file_path = _load_scene
			var root = get_tree().get_root()
			root.add_child(scene)
			root.move_child(scene, root.get_child_count() - 2)
			_load_scene = ""

# when you added the loaded scene to the scene tree by `add_loaded_scene_to_scene_tree`
# function, you call this function after you are sure that the added scene to scene tree
# is completely ready and functional to change the active scene
func change_scene_to_existing_scene_in_scene_tree(fade_out_options: Options, fade_in_options: Options, general_options: GeneralOptions) -> void:
	_set_in_transition()
	_set_clickable(general_options.clickable)
	_set_pattern(fade_out_options, general_options)
	if _fade_out(fade_out_options.fade_speed):
		await _animation_player.animation_finished
		fade_out_finished.emit()
	# actual change scene goes here
	var root = get_tree().get_root()
	# delete the loading screen scene
	root.get_child(root.get_child_count() - 1).free()
	# get the loaded, completely generated scene
	var scene = root.get_child(root.get_child_count() - 1)
	# inform godot which now this is the current scene
	get_tree().set_current_scene(scene)
	# keeping the track of current scene and previous scenes
	var path: String = scene.scene_file_path
	var found_key: String = _get_scene_key_by_value(path)
	if general_options.add_to_back && found_key != "":
		_append_stack(found_key)
	# timeout and ...
	if _timeout(general_options.timeout):
		await get_tree().create_timer(general_options.timeout).timeout
	_animation_player.play(NO_COLOR, -1, 1, false)
	_set_pattern(fade_in_options, general_options)
	if _fade_in(fade_in_options.fade_speed):
		await _animation_player.animation_finished
		fade_in_finished.emit()
	_set_clickable(true)
	_set_out_transition()

# loads scene interactive
# connect to `load_percent_changed(value: int)` and `load_finished` signals
# to listen to updates on your scene loading status
#
# Note: you can activate `use_sub_threads` but just know that In the newest 
# versions of Godot there seems to be a bug that can cause a threadlock in
# the resource loader that will result in infinite loading of the scene 
# without any error.
#
# Related Github Issues About `use_sub_threads`:
#
# https://github.com/godotengine/godot/issues/85255
# https://github.com/godotengine/godot/issues/84012
func load_scene_interactive(key: String, use_sub_threads = false) -> void:
	if safe_validate_scene(key):
		set_process(true)
		_load_scene = Scenes.scenes[key]["value"]
		ResourceLoader.load_threaded_request(_load_scene, "", use_sub_threads, ResourceLoader.CACHE_MODE_IGNORE)

# returns loaded scene
#
# If scene is not loaded, blocks and waits until scene is ready. (acts blocking in code
# and may freeze your game, make sure scene is ready to get)
func get_loaded_scene() -> PackedScene:
	if _load_scene != "":
		return ResourceLoader.load_threaded_get(_load_scene) as PackedScene
	return null

# changes scene to loaded scene
func change_scene_to_loaded_scene(fade_out_options: Options, fade_in_options: Options, general_options: GeneralOptions) -> void:
	if _load_scene != "":
		var scene = ResourceLoader.load_threaded_get(_load_scene) as PackedScene
		if scene:
			change_scene(scene, fade_out_options, fade_in_options, general_options)

# returns previous scene (scene before current scene)
func get_previous_scene() -> String:
	return _stack[len(_stack) - 1]

# returns a specific previous scene at an exact index position
func get_previous_scene_at(index: int) -> String:
	if index < len(_stack):
		return _stack[index]
	return ""

# pops from the back stack and returns previous scene (scene before current scene)
func pop_previous_scene() -> String:
	return _pop_stack()

# returns how many scenes there are in list of previous scenes.
func previous_scenes_length() -> int:
	return len(_stack)

# records a scene key to be used for loading scenes to know where to go after getting loaded
# into loading scene or just for next scene to know where to go next
func set_recorded_scene(key: String) -> void:
	validate_scene(key)
	_recorded_scene = key

# returns recorded scene
func get_recorded_scene() -> String:
	return _recorded_scene

# pause (fadeout). You can resume afterwards.
func pause(fade_out_options: Options, general_options: GeneralOptions) -> void:
	_set_in_transition()
	_set_clickable(general_options.clickable)
	_set_pattern(fade_out_options, general_options)
	if _fade_out(fade_out_options.fade_speed):
		await _animation_player.animation_finished
		fade_out_finished.emit()

## resume (fadein) after pause
func resume(fade_in_options: Options, general_options: GeneralOptions) -> void:
	_set_clickable(general_options.clickable)
	_set_pattern(fade_in_options, general_options)
	if _fade_in(fade_in_options.fade_speed):
		await _animation_player.animation_finished
		fade_in_finished.emit()
	_set_out_transition()
	_set_clickable(true)
