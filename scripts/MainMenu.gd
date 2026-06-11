extends Control

const BG := Color("#07090c")
const PANEL := Color("#14191f")
const ORANGE := Color("#f28c28")
const RED := Color("#b9382f")
const GREEN := Color("#70b86b")
const TEXT := Color("#e8e0d2")
const MUTED := Color("#9aa4aa")
const MENU_BACKGROUND := preload("res://assets/placeholders/menu_background.png")

var continue_button: Button
var backdrop_layer: Control
var menu_time := 0.0

func _ready() -> void:
	_build_theme()
	_build_menu()

func _process(delta: float) -> void:
	menu_time += delta
	if backdrop_layer != null:
		backdrop_layer.queue_redraw()

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
	backdrop_layer = backdrop
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
	continue_button = _add_button(center, "CONTINUE", _continue_game, GREEN)
	_add_button(center, "COLONY MODE", _new_game, MUTED)
	_add_button(center, "SETTINGS", _settings, MUTED)
	_add_button(center, "EXIT", _quit, RED)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(right)

	var signal_panel := _panel(right)
	signal_panel.add_child(_label("STAY ALERT.", 18, TEXT))
	signal_panel.add_child(_label("STAY TOGETHER.", 18, TEXT))
	signal_panel.add_child(_label("STAY ALIVE.", 18, GREEN))
	var summary := SaveManager.get_save_summary()
	var save_text := "No local save found."
	if not summary.is_empty():
		save_text = "Continue: Day %d\nPopulation %d | Morale %d%% | Security %d%%" % [summary["day_number"], summary["population"], summary["morale"], summary["security"]]
	signal_panel.add_child(_label("Willowgate Industrial Estate\nUnit 7B lockdown active\n%s" % save_text, 12, MUTED))
	if continue_button != null:
		continue_button.disabled = summary.is_empty()

func _draw_backdrop(node: Control) -> void:
	var size := node.size
	node.draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.22), true)
	node.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.36)), Color(0.0, 0.0, 0.0, 0.34), true)
	for i in range(8):
		var drift := fmod(menu_time * (8.0 + float(i)) + float(i) * 97.0, size.x + 220.0) - 110.0
		var y := size.y * (0.2 + float(i % 4) * 0.12)
		var fog := Color(0.45, 0.52, 0.56, 0.045)
		node.draw_rect(Rect2(Vector2(drift, y + 12.0), Vector2(220, 14)), fog, true)
		node.draw_circle(Vector2(drift, y + 19.0), 19.0, fog)
		node.draw_circle(Vector2(drift + 220.0, y + 19.0), 19.0, fog)
	for i in range(9):
		var p := Vector2(size.x * (0.18 + fmod(float(i) * 0.083 + menu_time * 0.01, 0.56)), size.y * (0.62 + fmod(float(i) * 0.067, 0.2)))
		_draw_menu_zombie(node, p + Vector2(0, sin(menu_time * 3.0 + float(i)) * 2.0), 0.7 + float(i % 3) * 0.1)
	var glow := 0.15 + (sin(menu_time * 4.0) + 1.0) * 0.04
	node.draw_circle(size * Vector2(0.74, 0.31), 38, Color(RED.r, RED.g, RED.b, glow))

func _draw_menu_zombie(node: Control, pos: Vector2, scale: float) -> void:
	var color := Color("#10161a")
	node.draw_circle(pos + Vector2(0, -17) * scale, 5.0 * scale, color)
	node.draw_line(pos + Vector2(0, -12) * scale, pos + Vector2(-2, 10) * scale, color, 4.0 * scale)
	node.draw_line(pos + Vector2(-2, -6) * scale, pos + Vector2(-12, 2) * scale, color, 3.0 * scale)
	node.draw_line(pos + Vector2(0, -5) * scale, pos + Vector2(10, 4) * scale, color, 3.0 * scale)
	node.draw_line(pos + Vector2(-2, 10) * scale, pos + Vector2(-9, 24) * scale, color, 3.0 * scale)
	node.draw_line(pos + Vector2(-1, 10) * scale, pos + Vector2(7, 23) * scale, color, 3.0 * scale)

func _add_button(parent: VBoxContainer, text: String, callback: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", accent.lightened(0.15))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

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
