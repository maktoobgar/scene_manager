CHANGELOG
=========

UNRELEASED
----------


2.2.1 (2023-01-22)
------------------

* 🐛 fix: #2, fixed problem in exporting game with scene manager

2.2.0 (2023-01-06)
------------------

* feat: added ability to load scenes interactive
* feat: some more useful functions added for more complex implementations
* fix: just some debugging to fix some odd behaviors

2.1.0 (2022-12-31)
------------------

* feat: #1 added a feature to limit how much deep scene manager is allowed to record previous scenes which affects in changing scene to previous scene functionality

2.0.1 (2022-04-02)
------------------

* fix: demo updated based on new updated patterns
* fix: some patterns updated with new ones
* refactor: based on godot documentation for `https://godotengine.org/asset-library` some changes happened

2.0.0 (2022-03-29)
------------------

* fix: create_scene_instance now returns a Node instead of a PackedScene
* feat: your scenes now save in `addons/scene_manager/scenes.gd` and you do not need to have a file near every export of your games
* note: this version does not support .json files of previous versions

1.4.0 (2022-03-25)
------------------

* feat: folders with `.gdignore` file inside them, their scenes will be ignored from tool view
* feat: safe_validate_scene and safe_validate_pattern functions added
* feat: shader transition feature added
* feat: create_scene_instance function added
* feat: transition is so much more customizable

1.3.0 (2022-03-18)
------------------

* feat: arrangeable scene categories
* feat: reserved keys will be informed to developer to avoid using them as a scene key
* feat: change to previous scene
* feat: show_first_scene transition on game start function
* feat: reset_scene_manager function to set current active scene as a starting point

1.2.0 (2022-03-16)
------------------

* feat: categorization added
* feat: ignore folder feature added

1.1.0 (2022-03-14)
------------------

* feat: general use case transition system added

1.0.1 (2022-03-12)
------------------

* perf: now just a single node opens up as singleton autorun

1.0.0 (2022-03-12)
------------------

* feat: demo added
* fix: bug fix on scene_manager.gd script
* feat: scroll added
* feat: change_scene function added
* feat: duplication check and active inactive automation for save button added
* fix: bug on pre-push script fixed
* feat: main menu style with refresh and save buttons and functionalities added
