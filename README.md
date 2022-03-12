# Scene Manager

A tool to manage transition between different scenes.

Under development...

## Features

* [X] Main tool menu structure added
* [X] Save button added
* [X] Refresh button added
* [X] List duplication check added
* [X] Save button (enable disable) automation feature added
* [X] New change_scene function added
* [X] Scroll to scene objects added
* [X] Demo added

## How To Use?

1. Copy and paste `scene_manager` folder which is inside `addons` folder. (don't change the `scene_manager` folder name)
2. From editor toolbar, choose **`Project > Project Settings...`** then in **`Plugins`** tab, activate scene_manager plugin.
3. Use `Scene Manager` tab on right side of the screen(on default godot theme view) to manage your scenes.
4. After you are done with managing your scenes, always **save** your changes so that your changes have effect inside your actual game.

**Note**: This tool saves your scenes data inside `res://scenes.json` file, if you want to have your latest changes and avoid redefining your scene keys, do not remove it.

**Note**: Surely do not ignore `res://scenes.json` file from your git tool.

## Tool View

This is the tool that you will see on your right side of the godot editor after activating `scene_manager` plugin:

<p align="center">
<img src="images/tool.png"/>
</p>

### Double key checker:
If editing of a scene key causes two keys of two different scenes match, both of them will get red color and you have to fix the duplication, otherwise the plugin does not work properly as you expect it to work.

<p align="center">
<img src="images/tool_double_key.png"/>
</p>

## Demo

The only amount of written code for this demo is just 6 lines:

<p align="center">
<img src="./images/demo.gif"/>
</p>

### Demo Code

**Note**: You can use `SceneManager` node in your game after you activated `scene_manager` plugin.

```
extends Button

export(String) var scene

func _ready() -> void:
	# code break happens if scene is not recognizable
	SceneManager.validate_key(scene)

func _on_button_up():
	SceneManager.change_scene(scene)
```

1. SceneManager.validate_key(scene):
   * This function does validate the scene you have written inside exported `scene` variable and if this scene key does not exist in the dictionary of tool, code will break and inform you about problem.
2. SceneManager.change_scene(scene):
   * Simply just changes the scene.

## SceneManager

This is the node you use inside your game code and it has these functions:
1. validate_key(key: String) -> void:
   * Checks and validate the key you will to use. (breaks game if key doesn't exist)
2. change_scene(key: String) -> void:
   * Changes scene if key is valid, otherwise nothing happens.
