extends Control

func _ready() -> void:
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
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#f28c28"))
	box.add_child(title)

	var sound := CheckButton.new()
	sound.text = "Sound"
	sound.button_pressed = true
	sound.custom_minimum_size = Vector2(0, 56)
	box.add_child(sound)

	_add_button(box, "Reset Save", _reset_save)
	_add_button(box, "Credits", func(): _message("Dead Shift prototype. Built with Godot 4 and placeholder assets."))
	_add_button(box, "Back", func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 56)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)

func _message(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Dead Shift"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()

func _reset_save() -> void:
	GameManager.reset_save_and_game()
	_message("Save reset.")
