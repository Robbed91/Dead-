extends Control

const BG := Color("#07090c")
const PANEL := Color("#14191f")
const ORANGE := Color("#f28c28")
const RED := Color("#c23b33")
const GREEN := Color("#70b86b")
const TEXT := Color("#e8e0d2")
const MUTED := Color("#91a0a6")

var sound_toggle: CheckButton
var save_summary: Label

func _ready() -> void:
	_build_theme()
	_build_layout()
	_refresh()

func _build_theme() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 16
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("#242c33")
	button_style.border_color = Color("#46515c")
	button_style.border_width_left = 1
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.corner_radius_top_left = 4
	button_style.corner_radius_top_right = 4
	button_style.corner_radius_bottom_left = 4
	button_style.corner_radius_bottom_right = 4
	var pressed := button_style.duplicate()
	pressed.bg_color = Color("#3a2410")
	pressed.border_color = ORANGE
	ui_theme.set_stylebox("normal", "Button", button_style)
	ui_theme.set_stylebox("hover", "Button", button_style)
	ui_theme.set_stylebox("pressed", "Button", pressed)
	ui_theme.set_color("font_color", "Button", TEXT)
	ui_theme.set_color("font_color", "Label", TEXT)
	set_theme(ui_theme)

func _build_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 54
	root.offset_top = 38
	root.offset_right = -54
	root.offset_bottom = -38
	root.add_theme_constant_override("separation", 24)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	root.add_child(left)
	left.add_child(_label("SETTINGS", 44, ORANGE))
	left.add_child(_label("Configure local test options and save data.", 16, MUTED))
	var note := _panel(left, Vector2(0, 0))
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note.add_child(_label("ANDROID TESTING", 18, GREEN))
	var body := _label("Dead Shift stores saves and settings in Godot's user:// path on each device. Reset Save only clears the current local test save.", 16, TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_child(body)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(430, 0)
	right.add_theme_constant_override("separation", 12)
	root.add_child(right)

	var options := _panel(right, Vector2(0, 170))
	options.add_child(_label("OPTIONS", 18, ORANGE))
	sound_toggle = CheckButton.new()
	sound_toggle.text = "Sound Enabled"
	sound_toggle.custom_minimum_size = Vector2(0, 56)
	sound_toggle.toggled.connect(_on_sound_toggled)
	options.add_child(sound_toggle)

	var save_box := _panel(right, Vector2(0, 180))
	save_box.add_child(_label("SAVE DATA", 18, ORANGE))
	save_summary = _label("", 15, TEXT)
	save_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_box.add_child(save_summary)
	_add_button(save_box, "RESET SAVE", _confirm_reset, RED)

	var actions := _panel(right, Vector2(0, 0))
	actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions.add_child(_label("PROJECT", 18, ORANGE))
	_add_button(actions, "CREDITS", func(): _message("Dead Shift v0.1 Prototype\nBuilt with Godot 4, generated placeholder art, and original prototype systems."), MUTED)
	_add_button(actions, "BACK", func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"), GREEN)

func _refresh() -> void:
	var settings := SaveManager.load_settings()
	sound_toggle.set_pressed_no_signal(bool(settings.get("sound_enabled", true)))
	var summary := SaveManager.get_save_summary()
	if summary.is_empty():
		save_summary.text = "No local save found."
	else:
		save_summary.text = "Day %d | Population %d | Morale %d%% | Security %d%%" % [summary["day_number"], summary["population"], summary["morale"], summary["security"]]

func _on_sound_toggled(enabled: bool) -> void:
	SaveManager.save_settings({"sound_enabled": enabled})

func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reset Save"
	dialog.dialog_text = "Delete the local Dead Shift save on this device?"
	add_child(dialog)
	dialog.confirmed.connect(func():
		GameManager.reset_save_and_game()
		_refresh()
		dialog.queue_free()
		_message("Save reset.")
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2(430, 220))

func _message(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Dead Shift"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2(460, 240))

func _add_button(parent: VBoxContainer, text: String, callback: Callable, color: Color) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 56)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", color.lightened(0.12))
	button.pressed.connect(callback)
	parent.add_child(button)

func _panel(parent: Container, min_size: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color("#3e4852")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
