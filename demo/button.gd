extends Button

export(String) var scene

func _ready() -> void:
	# code break happens if scene is not recognizable
	SceneManager.validate_key(scene)

func _on_button_up():
	SceneManager.change_scene(scene)
