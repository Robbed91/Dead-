extends Control

const BG := Color("#07090c")
const PANEL := Color("#14191f")
const ORANGE := Color("#f28c28")
const RED := Color("#b9382f")
const GREEN := Color("#70b86b")
const TEXT := Color("#e8e0d2")
const MUTED := Color("#9aa4aa")
const MENU_BACKGROUND := preload("res://assets/placeholders/menu_background.png")

func _ready() -> void:
	_build_theme()
	_build_menu()

func _build_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = 16
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0.082, 0.102, 0.125, 0.9)
	button_style.border_color = Color("#47515a")
	button_style.border_width_left = 1
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.corner_radius_top_left = 3
	button_style.corner_radius_top_right = 3
	button_style.corner_radius_bottom_left = 3
	button_style.corner_radius_bottom_right = 3
	var pressed := button_style.duplicate()
	pressed.bg_color = Color("#30200f")
	pressed.border_color = ORANGE
	theme.set_stylebox("normal", "Button", button_style)
	theme.set_stylebox("hover", "Button", button_style)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_color", "Label", TEXT)
	set_theme(theme)

func _build_menu() -> void:
	var image := TextureRect.new()
	image.texture = MENU_BACKGROUND
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(image)

	var backdrop := Control.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.draw.connect(_draw_backdrop.bind(backdrop))
	add_child(backdrop)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 54
	root.offset_top = 36
	root.offset_right = -54
	root.offset_bottom = -30
	root.add_theme_constant_override("separation", 36)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 16)
	root.add_child(left)

	var title := Label.new()
	title.text = "DEAD\nSHIFT"
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", TEXT)
	left.add_child(title)

	var tag := Label.new()
	tag.text = "SURVIVE.  BUILD.  DEFEND."
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", ORANGE)
	left.add_child(tag)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)

	var version := Label.new()
	version.text = "v0.1 PROTOTYPE"
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", MUTED)
	left.add_child(version)

	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(360, 0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 10)
	root.add_child(center)

	_add_button(center, "NEW GAME", _new_game, ORANGE)
	_add_button(center, "CONTINUE", _continue_game, GREEN)
	_add_button(center, "COLONY MODE", _new_game, MUTED)
	_add_button(center, "SETTINGS", _settings, MUTED)
	_add_button(center, "EXIT", _quit, RED)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(right)

	var signal := _panel(right)
	signal.add_child(_label("STAY ALERT.", 18, TEXT))
	signal.add_child(_label("STAY TOGETHER.", 18, TEXT))
	signal.add_child(_label("STAY ALIVE.", 18, GREEN))
	signal.add_child(_label("Willowgate Industrial Estate\nUnit 7B lockdown active", 12, MUTED))

func _draw_backdrop(node: Control) -> void:
	var size := node.size
	node.draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.28), true)
	node.draw_rect(Rect2(Vector2(0, size.y * 0.62), Vector2(size.x, size.y * 0.38)), Color(0.067, 0.082, 0.102, 0.42), true)
	for i in range(9):
		var x := size.x * (float(i) / 8.0)
		node.draw_rect(Rect2(Vector2(x - 18, size.y * 0.28 + sin(i) * 18), Vector2(80, size.y * 0.35)), Color("#151b21"), true)
		node.draw_rect(Rect2(Vector2(x - 18, size.y * 0.28 + sin(i) * 18), Vector2(80, size.y * 0.35)), Color("#2b353d"), false, 1)
	for i in range(6):
		var lamp := Vector2(size.x * (0.12 + i * 0.16), size.y * 0.53)
		node.draw_line(lamp, lamp + Vector2(0, -120), Color("#252c32"), 4)
		node.draw_circle(lamp + Vector2(0, -120), 7, ORANGE)
		node.draw_circle(lamp + Vector2(0, -120), 24, Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.12))
	for i in range(14):
		var p := Vector2(size.x * (0.04 + fmod(i * 0.073, 0.9)), size.y * (0.72 + fmod(i * 0.041, 0.2)))
		node.draw_circle(p, 5, Color("#20262c"))
		node.draw_line(p, p + Vector2(0, -20), Color("#20262c"), 3)
	node.draw_rect(Rect2(Vector2(size.x * 0.73, size.y * 0.34), Vector2(size.x * 0.2, size.y * 0.23)), Color("#1b2026"), true)
	node.draw_rect(Rect2(Vector2(size.x * 0.73, size.y * 0.34), Vector2(size.x * 0.2, size.y * 0.23)), RED.darkened(0.25), false, 2)

func _add_button(parent: VBoxContainer, text: String, callback: Callable, accent: Color) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", accent.lightened(0.15))
	button.pressed.connect(callback)
	parent.add_child(button)

func _panel(parent: Container) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 116)
	parent.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL.r, PANEL.g, PANEL.b, 0.9)
	style.border_color = Color("#4b565f")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	return box

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

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
