extends Node

const FADE_OUT = "fade_out"
const FADE_IN = "fade_in"
const IDLE = "idle"

onready var _menu: Dictionary = _load_scenes("res://scenes.json")
onready var _fade_color_rect: ColorRect = find_node("fade")
onready var _animation_player: AnimationPlayer = find_node("animation_player")
onready var _color: Color = Color(0, 0, 0)
onready var _in_transition: bool = false

class Options:
	# based on seconds
	var fade_out_speed: float = 1
	var fade_in_speed: float = 1
	var color: Color = Color(0, 0, 0)
	var timeout: float = 0

func _file_exists(address: String) -> void:
	assert (
		Directory.new().file_exists(address),
		"Error: `%s` file does not exist, please save your scenes by save button in tool gui."% address
	)

func _load_scenes(address: String) -> Dictionary:
	var data: Dictionary = {}

	_file_exists(address)
	var file = File.new()
	file.open(address, File.READ)
	data = parse_json(file.get_var())
	file.close()

	return data

func _process(delta):
	if _in_transition:
		_fade_color_rect.color = Color(_color.r, _color.g, _color.b, _fade_color_rect.color.a)

# `speed` unit is in seconds
func _fade_in(speed: float) -> void:
	_animation_player.play("fade", -1, 1 / speed, false)

# `speed` unit is in seconds
func _fade_out(speed: float) -> void:
	_animation_player.play("fade", -1, -1 / speed, true)

func _set_color(color: Color = Color(0, 0, 0)) -> void:
	_color = color

func _set_in_transition() -> void:
	_in_transition = true

func _set_out_transition() -> void:
	_in_transition = false

func create_options(fade_out_speed: float, fade_in_speed: float, color: Color, timeout: float = 0) -> Options:
	var options: Options = Options.new()
	options.fade_out_speed = fade_out_speed
	options.fade_in_speed = fade_in_speed
	options.color = color
	options.timeout = timeout
	return options

func validate_key(key: String) -> void:
	assert(
		_menu.has(key) == true,
		"ERROR: `%s` key is not recognized, please double check."% key
	)

func change_scene(key: String, options: Options) -> void:
	if _menu.has(key) && !_in_transition:
		_set_color(options.color)
		_set_in_transition()
		_fade_out(options.fade_out_speed)
		yield(_animation_player, "animation_finished")
		get_tree().change_scene(_menu[key])
		yield(get_tree(), "node_added")
		yield(get_tree().create_timer(options.timeout), "timeout")
		_fade_in(options.fade_in_speed)
		yield(_animation_player, "animation_finished")
		_set_out_transition()
