# Scene Manager

<p align="center">
<img src="icon.png"/>
</p>

A tool to manage transition between different scenes.

## Features

**Recently Added**:

* [X] Loading scenes interactive is possible. (Loading scene code example added)
* [X] Ability to limit how much deep scene manager is allowed to record previous scenes which affects in changing scene to `back`(previous scene) functionality

**All**:

* [X] A fully responsive tool menu structure to manage and categorize your scene
* [X] Save button that saves all scenes in a dictionary
* [X] Refresh button that refreshes the tool with latest saved status of the scenes
* [X] List duplication check for keys
* [X] Smooth transition between scenes
* [X] Demo
* [X] Memory performance
* [X] Ignore folder feature which ignores some folders you said to ignore in `Scene Manager` addon tool
* [X] Categorization for scenes
* [X] Ignore folder section can hide optionally
* [X] Change to previous scenes is allowed and possible and handled
* [X] Fully customizable transitions
* [X] Customizable entering the first scene of the game transition
* [X] Reset `Scene Manager` function to assume the current scene as the first ever seen scene (to ignore previous scenes and don't go back to them by changing scene to the previous scene)
* [X] Arrangeable scene categories(they will reset to alphabetic order after refresh or save button)
* [X] Fade in and fade out with different desired patterns
* [X] You can create instance of a scene just by calling the scene with a key
* [X] Transition is so much customizable
* [X] `SceneManager` tool will ignore scenes inside folders with `.gdignore` file inside them
## How To Use?

1. Copy and paste `scene_manager` folder which is inside `addons` folder. (don't change the `scene_manager` folder name)
2. From editor toolbar, choose **`Project > Project Settings...`** then in **`Plugins`** tab, activate scene_manager plugin.
3. Use `Scene Manager` tab on right side of the screen(on default godot theme view) to manage your scenes.
4. After you are done with managing your scenes, always **save** your changes so that your changes have effect inside your actual game.

**Note**: After activating `Scene Manager` tool, you have access to **SceneManager** script globally from anywhere in your scripts and you can use it to change scenes and ... (for more information, read [SceneManager](#scenemanager) section)
**Note**: This tool saves your scenes data inside `res://addons/scene_manager/scenes.gd` file, if you want to have your latest changes and avoid redefining your scene keys, **do not** remove it, **do not** change it or modify it in anyway.

## Tool View

This is the tool that you will see on your right side of the godot editor after activating `scene_manager` plugin. By **Add Category** button under scenes categories you can create new categories to manage your scenes.

<p align="center">
<img src="images/tool.png"/>
</p>

### Double key checker:
If editing of a scene key causes at least two keys of another scene match, both of them will get red color and you have to fix the duplication, otherwise the plugin does not work properly as you expect it to work.

<p align="center">
<img src="images/tool_double_key.png"/>
</p>

### Ignore Folder:

Every folder that is added inside this section will be ignored and scenes inside them will not get included inside scenes categories section(the section above this section).

<p align="center">
<img src="images/ignore.png"/>
</p>

## Demo

Just a simple demo to show some abilities of this addon:

<p align="center">
<img src="./images/demo.gif"/>
</p>

### Demo Description

1. Scene \<number\>: this button calls `change_scene` function and goes to next scene.
2. Reset: after pressing this button, you don't go back to the previous seen scenes by pressing back button but if you do, you actually restart your scene.
3. Reload: reloads the current scene.
4. Back: goes back to previous scene. (or restarts if there is no previous scene)
5. Nothing: just shows a transition but actually does nothing.
6. Exit: after fading out of the screen, quits the game.

### Demo Code

**Note**: You can use `SceneManager` node in your game after you activated `scene_manager` plugin.

```gdscript
extends Button

export(String) var scene
export(float) var fade_out_speed = 1.0
export(float) var fade_in_speed = 1.0
export(String) var fade_out_pattern = "fade"
export(String) var fade_in_pattern = "fade"
export(float, 0, 1) var fade_out_smoothness = 0.1
export(float, 0, 1) var fade_in_smoothness = 0.1
export(bool) var fade_out_inverted = false
export(bool) var fade_in_inverted = false
export(Color) var color = Color(0, 0, 0)
export(float) var timeout = 0.0
export(bool) var clickable = false
export(bool) var add_to_back = true

onready var fade_out_options = SceneManager.create_options(fade_out_speed, fade_out_pattern, fade_out_smoothness, fade_out_inverted)
onready var fade_in_options = SceneManager.create_options(fade_in_speed, fade_in_pattern, fade_in_smoothness, fade_in_inverted)
onready var general_options = SceneManager.create_general_options(color, timeout, clickable, add_to_back)

func _ready() -> void:
	var fade_in_first_scene_options = SceneManager.create_options(1, "fade")
	var first_scene_general_options = SceneManager.create_general_options(Color(0, 0, 0), 1, false)
	SceneManager.show_first_scene(fade_in_first_scene_options, first_scene_general_options)
	# code breaks if scene is not recognizable
	SceneManager.validate_scene(scene)
	# code breaks if pattern is not recognizable
	SceneManager.validate_pattern(fade_out_pattern)
	SceneManager.validate_pattern(fade_in_pattern)

func _on_button_button_up():
	SceneManager.change_scene(scene, fade_out_options, fade_in_options, general_options)

func _on_reset_button_up():
	SceneManager.reset_scene_manager()

func _on_loading_scene_button_up():
	SceneManager.set_recorded_scene(scene)
	SceneManager.change_scene("loading", fade_out_options, fade_in_options, general_options)
```

Loading Scene Code Example:

```gdscript
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
```

## SceneManager

This is the node you use inside your game code and it has these functions:
1. `validate_scene`(**key**: String) -> void:
   * Checks and validates passed **key** in scenes keys. (breaks game if key doesn't exist in scenes keys)
2. `validate_pattern`(**key**: String) -> void:
   * Checks and validates passed **key** in patterns keys. (breaks game if key doesn't exist in patterns keys)
3. `safe_validate_scene`(**key**: String) -> bool:
   * Safely validates the scene key and does not break the game.
4. `safe_validate_pattern`(**key**: String) -> bool:
    * Safely validates the pattern key and does not break the game.
5. `change_scene`(**key**: String, **fade_out_options**: Options, **fade_in_options**: Options, **general_options**: GeneralOptions) -> void:
   * Changes scene if key is valid, otherwise nothing happens.
   * **fade_out_options** and **fade_in_options** are some configurations you can put in the function to customize your fade_in to the scene or fade_out of the current scene and you can create `Options` objects by calling `create_options` function.
   * **general_options** are common configurations that effect transition in both fade_in and fade_out transitions and you can create `GeneralOptions` by calling `create_general_options` functions.
   * **Note**: `back` as value of scene variable, causes going back to previous scene.
   * **Note**: `null`, `ignore` or an empty string as value of scene variable, causes nothing but just showing scene transition and does not change scenes at all.
   * **Note**: `refresh`, `reload` or `restart` as value of scene variable, causes refreshing the current scene.
   * **Note**: `exit` or `quit` as value of scene variable, causes exiting out of the game.
   * **Note**: Any value as **key** variable which starts with an `_` will be ignored.
6. `create_options`(**fade_speed**: float = 1, **fade_pattern**: String = "fade", **smoothness**: float = 0.1, **inverted**: bool = false) -> Options:
   * Creates `Options` object for `change_scene` function.
   * **fade_speed** = speed of fading out of the scene or fading into the scene in seconds.
   * **fade_pattern** = name of a shader pattern which is in `addons/scene_manager/shader_patterns` folder for fading out or fading into the scene. (if you use `fade` or an empty string, it causes a simple fade screen transition)
   * **smoothness** = defines roughness of pattern's edges. (this value is between 0-1 and more near to 1, softer edges and more near to 0, harder edges)
   * **inverted** = inverts the pattern.
7. `create_general_options`(**color**: Color = Color(0, 0, 0), **timeout**: float = 0, **clickable**: bool = true, **add_to_back**: bool = true) -> GeneralOptions:
   * **color** = color for the whole transition.
   * **timeout** = between this scene and next scene, there would be a gap which can take much longer that usual(default is 0) by your choice by changing this option.
   * **clickable** = makes the scene behind the transition visuals clickable or not.
   * **add_to_back** = if true, you can go back to current scene after changing scene to next scene by going to "back" scene which means previous scene.
8. `show_first_scene`(**fade_in_options**: Options, **general_options**: GeneralOptions) -> void:
   * Call this method inside `_ready` function of a node with a script which that node is inside the first scene that game jumps into it and this causes to have a smooth transition into the first game scene.
   * This function works just once at the beginning of the first game scene. After that, if you call this function again, nothing happens.
   * **fade_in_options** = creates it by calling `create_options` function.
   * **general_options** = creates it by calling `create_general_options` function.
9. `reset_scene_manager`() -> void:
   * Sets current active scene as a starting point so that we can't go back to previous scenes with changing scene to `back` scene.
10. `create_scene_instance`(**key**: String) -> Node:
    * Returns scene instance of passed scene key (blocking)
11. `set_back_limit`(**input**: int) -> void:
    * Limits how much deep scene manager is allowed to record previous scenes which affects in changing scene to `back`(previous scene) functionality.
    * Allowed `input` values:
      1.  input = -1 => unlimited (default)
      2.  input =  0 => we can not go back to any previous scenes
      3.  input >  0 => we can go back to `input` or less previous scenes
12. `get_scene`(**key**: String) -> PackedScene:
    * Returns PackedScene of passed scene key (blocking)
13. `load_scene_interactive`(**key**: String) -> void:
    * Loads scene interactive.
    * **Note**: Connect to `load_percent_changed(value: int)` and `load_finished` signals to listen to updates on your scene loading status.
14. `get_loaded_scene`() -> PackedScene:
    * Returns loaded scene.
    * **Note**: If scene is not loaded, blocks and waits until scene is ready. (acts blocking in code and may freeze your game, make sure scene is ready to get)
15. `change_scene_to_loaded_scene`(**fade_out_options**: Options, **fade_in_options**: Options, **general_options**: GeneralOptions) -> void:
    * Changes scene to interactively loaded scene.
    * Checkout function number 5 (`change_scene`) to understand what **fade_out_options**, **fade_in_options** and **general_options** are.
16. `get_previous_scene`() -> String:
    * Returns previous scene. (the scene before current scene)
17. `get_previous_scene_at`(**index**: int) -> String:
    * Returns a specific previous scene at an exact index position
18. `pop_previous_scene`() -> String:
    * Returns previous scene and removes it from list of previous scenes.
19. `previous_scenes_length`() -> int:
    * Returns how many scenes there are in list of previous scenes.
20. `set_recorded_scene`(**key**: String) -> void:
    * Records a scene key to be used for loading scenes to know where to go after getting loaded into loading scene or just for next scene to know where to go next.
21. `get_recorded_scene`() -> String:
    * Returns recorded scene by `set_recorded_scene` function.
