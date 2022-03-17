extends Button

export(String) var scene
export(float) var fade_out_speed = 1
export(float) var fade_in_speed = 1
export(Color) var color = Color(0, 0, 0)
export(float) var timeout = 0
export(bool) var clickable = false
onready var scene_options = SceneManager.create_options(fade_out_speed, fade_in_speed, color, timeout, clickable)

func _ready() -> void:
	var first_scene_options = SceneManager.create_options(0, 1, Color(1, 1, 1), 1, false)
	SceneManager.show_first_scene(first_scene_options)
	# code break happens if scene is not recognizable
	SceneManager.validate_key(scene)

func _on_button_button_up():
	SceneManager.change_scene(scene, scene_options)

func _on_reset_button_up():
	SceneManager.reset_scene_manager()
