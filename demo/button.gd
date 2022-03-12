extends Button

export(String) var scene
export(float) var fade_out_speed = 1
export(float) var fade_in_speed = 1
export(Color) var color = Color(0, 0, 0)
export(float) var timeout = 0

func _ready() -> void:
	# code break happens if scene is not recognizable
	SceneManager.validate_key(scene)

func _on_button_up():
	var scene_options = SceneManager.create_options(fade_out_speed, fade_in_speed, color, timeout)
	SceneManager.change_scene(scene, scene_options)
