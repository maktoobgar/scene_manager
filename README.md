# Scene Manager

<p align="center">
<img src="icon.png"/>
</p>

A tool to manage transition between different scenes.

## Features

* [X] Main tool menu structure
* [X] Save button
* [X] Refresh button
* [X] List duplication check
* [X] New change_scene function
* [X] Scroll to scene objects
* [X] Demo
* [X] Memory performance
* [X] Scene transitions
* [X] Ignore folders section
* [X] Categorization for scenes
* [X] Ignore folder section can hide optionally
* [X] Change to previous scene
* [X] Fully customizable transitions
* [X] Customizable entering transition
* [X] Reset scene manager function to reset first scene to the current scene
* [X] Arrangeable scene categories(they will reset to alphabetic order with refresh or save button)
## How To Use?

1. Copy and paste `scene_manager` folder which is inside `addons` folder. (don't change the `scene_manager` folder name)
2. From editor toolbar, choose **`Project > Project Settings...`** then in **`Plugins`** tab, activate scene_manager plugin.
3. Use `Scene Manager` tab on right side of the screen(on default godot theme view) to manage your scenes.
4. After you are done with managing your scenes, always **save** your changes so that your changes have effect inside your actual game.

**Note**: This tool saves your scenes data inside `res://scenes.json` file, if you want to have your latest changes and avoid redefining your scene keys, do not remove it.

**Note**: Surely do not ignore `res://scenes.json` file from your git tool.

## Tool View

This is the tool that you will see on your right side of the godot editor after activating `scene_manager` plugin. By **Add Category** button under scenes categories you can create new categories.

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

The only amount of written code for this demo is just 16 lines:

<p align="center">
<img src="./images/demo.gif"/>
</p>

### Demo Code

**Note**: You can use `SceneManager` node in your game after you activated `scene_manager` plugin.

```
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
```

## SceneManager

This is the node you use inside your game code and it has these functions:
1. `validate_key`(key: String) -> void:
   * Checks and validate the key you will to use. (breaks game if key doesn't exist)
2. `change_scene`(key: String, options: Options) -> void:
   * Changes scene if key is valid, otherwise nothing happens.
   * options is a bunch of options you can put in to customize your transitions and you can create that `Options` object by calling `create_options` function.
   * **Note**: `back` as value of scene variable, causes going back to previous scene.
   * **Note**: `null`, `ignore` or an empty string as value of scene variable, causes nothing but just showing scene transition and does not change scenes at all.
   * **Note**: `refresh`, `reload` or `restart` as value of scene variable, causes refreshing the current scene.
   * **Note**: `exit` or `quit` as value of scene variable, causes exiting smoothly out of the game.
   * **Note**: Any other value in scene variable which starts with an `_` will be ignored.
3. `create_options`(fade_out_speed: float = 1, fade_in_speed: float = 1,
  color: Color = BLACK, timeout: float = 0, clickable: bool = true) -> Options:
   * Creates Options object for `change_scene` function.
   * fade_out_speed(second) = speed of going to black screen.
   * fade_in_speed(second) = speed of going to next scene from black screen.
   * color = color of screen which is between current scene and next scene. (It's color is black by default)
   * timeout(second) = between this scene and next scene, there would be a gap which can take much longer that usual(default is 0) by your choice by changing this option.
4. `show_first_scene`(options: Options) -> void:
   * Call this method inside `_ready` function of a node with a script which that node is inside the first scene that game jumps into it and this causes to have a smooth transition into the first game scene.
   * This function works just once at the beginning of the first game scene. After that, if you call this function again, nothing happens.
5. `reset_scene_manager`() -> void:
   * Sets current active scene as a starting point so that we can't go back to previous scenes with changing scene to `back` scene.