extends Control

func _ready() -> void:
	_build_menu()

func _build_menu() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#111317")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.offset_left = 24
	box.offset_right = -24
	add_child(box)

	var title := Label.new()
	title.text = "DEAD SHIFT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#f28c28"))
	box.add_child(title)

	var tagline := Label.new()
	tagline.text = "Survive. Build. Defend."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 21)
	tagline.add_theme_color_override("font_color", Color("#e8e0d2"))
	box.add_child(tagline)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 22)
	box.add_child(spacer)

	_add_button(box, "New Game", _new_game)
	_add_button(box, "Continue", _continue_game)
	_add_button(box, "Settings", _settings)
	_add_button(box, "Quit", _quit)

	var version := Label.new()
	version.text = "v0.1 Prototype"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 16)
	version.add_theme_color_override("font_color", Color("#8f9aa3"))
	box.add_child(version)

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)

func _new_game() -> void:
	GameManager.new_game()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _continue_game() -> void:
	if GameManager.continue_game():
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	else:
		_show_message("No save found. Start a new game.")

func _settings() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/SettingsScreen.tscn")

func _quit() -> void:
	get_tree().quit()

func _show_message(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Dead Shift"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()

