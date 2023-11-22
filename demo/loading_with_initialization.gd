extends Control

# Nodes
@onready var progress: ProgressBar = find_child("Progress")
@onready var loading: AnimatedSprite2D = find_child("Loading")
@onready var next: Button = find_child("Next")
@onready var label: Label = find_child("Label")

var gap = 30

func _ready():
	SceneManager.load_percent_changed.connect(percent_changed)
	SceneManager.load_finished.connect(loading_finished)
	SceneManager.load_scene_interactive(SceneManager.get_recorded_scene())

func percent_changed(number: int) -> void:
	# the last `gap%` is for the loaded scene itself to load its own data or initialize or world generate or ...
	progress.value = max(number - gap, 0)
	if progress.value >= 90:
		label.text = "World Generation . . ."

func loading_finished() -> void:
	# All loading processes are finished now
	if progress.value == 100:
		loading.visible = false
		next.visible = true
		label.text = ""
	# Loading finishes and world initialization or world generation or whatever you wanna call it will start
	elif progress.value == 70:
		SceneManager.add_loaded_scene_to_scene_tree()
		gap = 0
		label.text = "Scene Initialization . . ."

func _on_next_button_up():
	var fade_out_options = SceneManager.create_options(1.0, "scribbles", 0.2, true)
	var fade_in_options = SceneManager.create_options(1.0, "crooked_tiles", 0.2, true)
	var general_options = SceneManager.create_general_options(Color(0, 0, 0), 0, false, true)
	SceneManager.change_scene_to_existing_scene_in_scene_tree(fade_out_options, fade_in_options, general_options)
