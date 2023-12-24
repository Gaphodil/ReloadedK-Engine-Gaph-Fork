# ReloadedK's Godot Fangame Engine

A Godot 4.x fangame engine, created by ReloadedK.

Project started with Godot v4.0.2, which can be adquired at https://godotengine.org/

You can check the [engine's documentation](https://github.com/ReloadedK-git/ReloadedKs-Godot-Fangame-Engine-Docs/blob/main/00_start.md).

---

# Change-log

### v1.0 (09-07-23)

* Initial release.

### v1.1 (10-07-23)

* Updated to work with Godot 4.1.
* Changed default renderer to ***Compatibility***.
* Changed ***objMovingPlatform*** and ***objMovingBlock***.
* Minor change to ***objHUD***.

### v1.2 (09-09-23)

* Window position is kept when switching from windowed to fullscreen mode.

### v1.3 (30-09-23)

* Changed ***objInvisibleBlock***.
* Slightly reduced volume for ***sndBlockChange***.

### v1.4 (23-10-23)

* Numpad arrows and controller stick can be used to control the player or interact with different objects, if the setting is toggled on.
* Added an "extra keys" option in the settings menu.
* Added extra functionality to the player (movement, walljumping) and dialog sign (interaction).
* Added extra actions in the input map.

### v1.5 (24-10-23)

* Small fix for the player script. The input for the controller stick doesn't need to go all the way to get detected.

### v1.6 (07-12-23)

* Engine ported to Godot v4.2 while maintaining compatibility with older versions.
* Modified ***objPlayer***. The xscale variable is now a boolean instead of a float. The function ***set_first_time_saving()*** is called from ***_physics_process()*** due to v4.2's changes.
* Jump particles generated from the player now use a timer to free themselves.
* Save points don't autostart their timers by default.
* Renamed some variables for ***objInvisibleBlock*** so they don't conflict with engine variable names.
* Modified ***objWarp***'s script to be compatible with v4.2.
* ***objHUD***'s debug mode mouse pointer now follows ***objPlayer***'s xscale, and is compatible with v4.2.
* Modified ***scrGlobalGame*** to work with v4.2.
* ***scrSettingsMenu*** now shows "Reset to Defaults" instead of "Reset".
* FileSystem folders are now colored.

### v1.7 (24-12-23)

* Added multi-trigger system.
* Added a simpler, collision activated text sign.
* Modified ***objHUD*** and added a notification popup when finding items or collectables.
* Cameras and HUD can be scaled now.
* Added raycast-based lasers (static and dynamic).
* Very minor edits to ***objPlayer***
* Fixed a major bug with ***objCollectableItem***, and slightly changed the way it works due to ***objHUD***'s updates.
* ***objBackgroundMenus*** now uses a scroll shader.
* Both ***objCameraDynamic*** and ***objCameraFixed*** have been updated to work with the new camera zoom scaling.
* Changed the font for the triggers and made the text easier to read.
* Added extra settings to the settings menu (Camera Zoom and HUD Scaling).
* Updated the settings and controls menu to allow for infinite options, alongside visual improvements.
* Camera zoom is now 1x by default.
* Added new rooms (***rRoomSelection***, ***rTestRoom03***).
* Minor updates to several objects.
