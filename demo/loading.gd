extends Control

# Nodes
onready var progress: ProgressBar = find_node("Progress")
onready var loading: AnimatedSprite = find_node("Loading")
onready var next: Button = find_node("Next")

func _ready():
	SceneManager.connect("load_percent_changed", self, "percent_changed")
	SceneManager.connect("load_finished", self, "loading_finished")
	SceneManager.load_scene_interactive(SceneManager.get_recorded_scene())

func percent_changed(number: int) -> void:
	progress.value = number

func loading_finished() -> void:
	loading.visible = false
	next.visible = true

func _on_next_button_up():
	var fade_out_options = SceneManager.create_options(1.0, "scribbles", 0.2, true)
	var fade_in_options = SceneManager.create_options(1.0, "crooked_tiles", 0.2, true)
	var general_options = SceneManager.create_general_options(Color(0, 0, 0), 0, false, true)
	SceneManager.change_scene_to_loaded_scene(fade_out_options, fade_in_options, general_options)
