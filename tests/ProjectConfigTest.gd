extends SceneTree

var failures: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	_assert_eq(String(ProjectSettings.get_setting("application/run/main_scene", "")), "res://scenes/MainMenu.tscn", "main scene is MainMenu")
	_assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)), 1280, "landscape viewport width is 1280")
	_assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)), 720, "landscape viewport height is 720")
	_assert_eq(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)), 0, "Android orientation is landscape")
	_assert_eq(String(ProjectSettings.get_setting("application/config/icon", "")), "res://assets/icons/dead_shift_icon_192.png", "project uses generated Dead Shift icon")

	var preset_text := _read_text("res://export_presets.cfg")
	var project_text := _read_text("res://project.godot")
	_assert_true(project_text.contains('FeedbackManager="*res://scripts/FeedbackManager.gd"'), "feedback autoload is registered")
	_assert_true(preset_text.contains('name="Android Debug"'), "Android Debug export preset exists")
	_assert_true(preset_text.contains('architectures/arm64-v8a=true'), "Android export targets arm64 phones")
	_assert_true(preset_text.contains('package/unique_name="com.prototype.deadshift"'), "Android package id is set")
	_assert_true(preset_text.contains('package/show_as_launcher_app=true'), "Android export creates launcher app")
	_assert_true(preset_text.contains('screen/immersive_mode=true'), "Android export uses immersive mode")
	_assert_true(preset_text.contains('launcher_icons/main_192x192="res://assets/icons/dead_shift_icon_192.png"'), "Android export uses generated launcher icon")

	if failures.is_empty():
		print("Dead Shift project config test passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not read %s" % path)
		return ""
	return file.get_as_text()

func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
