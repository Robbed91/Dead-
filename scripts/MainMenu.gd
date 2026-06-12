extends Control

const BG := Color("#07090c")
const PANEL := Color("#14191f")
const ORANGE := Color("#f28c28")
const RED := Color("#b9382f")
const GREEN := Color("#70b86b")
const TEXT := Color("#e8e0d2")
const MUTED := Color("#9aa4aa")
const MENU_BACKGROUND := preload("res://assets/backgrounds/main_menu.png")

var continue_button: Button
var backdrop_layer: Control
var modal_overlay: Control
var root_container: HBoxContainer
var menu_time := 0.0

func _ready() -> void:
	_build_theme()
	_build_menu()

func _process(delta: float) -> void:
	menu_time += delta
	if backdrop_layer != null:
		backdrop_layer.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_safe_area_layout()

func _build_theme() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 16
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
	ui_theme.set_stylebox("normal", "Button", button_style)
	ui_theme.set_stylebox("hover", "Button", button_style)
	ui_theme.set_stylebox("pressed", "Button", pressed)
	ui_theme.set_color("font_color", "Button", TEXT)
	ui_theme.set_color("font_color", "Label", TEXT)
	set_theme(ui_theme)

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
	root_container = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	_apply_safe_area_layout()

func _apply_safe_area_layout() -> void:
	if root_container == null:
		return
	var margins := _safe_area_margins()
	root_container.offset_left = 54.0 + margins.x
	root_container.offset_top = 36.0 + margins.y
	root_container.offset_right = -54.0 - margins.z
	root_container.offset_bottom = -30.0 - margins.w

func _safe_area_margins() -> Vector4:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector4.ZERO
	var safe_rect := DisplayServer.get_display_safe_area()
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var safe_pos := Vector2(float(safe_rect.position.x), float(safe_rect.position.y))
	var safe_size := Vector2(float(safe_rect.size.x), float(safe_rect.size.y))
	if safe_size.x >= viewport_size.x and safe_size.y >= viewport_size.y and safe_pos == Vector2.ZERO:
		return Vector4.ZERO
	return Vector4(
		clampf(safe_pos.x, 0.0, viewport_size.x * 0.18),
		clampf(safe_pos.y, 0.0, viewport_size.y * 0.18),
		clampf(viewport_size.x - safe_pos.x - safe_size.x, 0.0, viewport_size.x * 0.18),
		clampf(viewport_size.y - safe_pos.y - safe_size.y, 0.0, viewport_size.y * 0.18)
	)

func _draw_backdrop(node: Control) -> void:
	var view_size := node.size
	node.draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.0, 0.0, 0.0, 0.22), true)
	node.draw_rect(Rect2(Vector2.ZERO, Vector2(view_size.x, view_size.y * 0.36)), Color(0.0, 0.0, 0.0, 0.34), true)
	for i in range(8):
		var drift := fmod(menu_time * (8.0 + float(i)) + float(i) * 97.0, view_size.x + 220.0) - 110.0
		var y := view_size.y * (0.2 + float(i % 4) * 0.12)
		var fog := Color(0.45, 0.52, 0.56, 0.045)
		node.draw_rect(Rect2(Vector2(drift, y + 12.0), Vector2(220, 14)), fog, true)
		node.draw_circle(Vector2(drift, y + 19.0), 19.0, fog)
		node.draw_circle(Vector2(drift + 220.0, y + 19.0), 19.0, fog)
	for i in range(9):
		var p := Vector2(view_size.x * (0.18 + fmod(float(i) * 0.083 + menu_time * 0.01, 0.56)), view_size.y * (0.62 + fmod(float(i) * 0.067, 0.2)))
		_draw_menu_zombie(node, p + Vector2(0, sin(menu_time * 3.0 + float(i)) * 2.0), 0.82 + float(i % 3) * 0.12, float(i))
	for i in range(3):
		var guard_pos := Vector2(view_size.x * (0.68 + float(i) * 0.055), view_size.y * (0.58 + float(i % 2) * 0.055))
		_draw_menu_survivor(node, guard_pos, 1.0 - float(i) * 0.08, float(i))
	_draw_menu_barricade(node, view_size)
	var glow := 0.15 + (sin(menu_time * 4.0) + 1.0) * 0.04
	node.draw_circle(view_size * Vector2(0.74, 0.31), 38, Color(RED.r, RED.g, RED.b, glow))

func _draw_menu_zombie(node: Control, pos: Vector2, draw_scale: float, seed: float) -> void:
	var unit: float = maxf(2.0, 3.0 * draw_scale)
	var sway: float = roundf(sin(menu_time * 2.1 + seed) * unit)
	var origin := pos + Vector2(-8.0 * unit + sway, -20.0 * unit)
	var body := Color("#111416")
	var wound := RED.lightened(0.12)
	var eye := Color("#e8e0d2")
	_pixel_rect(node, origin, 1, 19, 7, 2, unit, Color(0, 0, 0, 0.36))
	_pixel_rect(node, origin, 8, 19, 6, 2, unit, Color(0, 0, 0, 0.36))
	_pixel_rect(node, origin, 5, 0, 7, 1, unit, body)
	_pixel_rect(node, origin, 3, 1, 10, 2, unit, body)
	_pixel_rect(node, origin, 2, 3, 12, 4, unit, body)
	_pixel_rect(node, origin, 3, 7, 9, 2, unit, body)
	_pixel_rect(node, origin, 0, 3, 2, 1, unit, body)
	_pixel_rect(node, origin, 0, 5, 2, 1, unit, body)
	_pixel_rect(node, origin, 6, 4, 2, 2, unit, eye)
	_pixel_rect(node, origin, 11, 4, 2, 2, unit, eye)
	_pixel_rect(node, origin, 7, 8, 1, 1, unit, eye)
	_pixel_rect(node, origin, 10, 8, 1, 1, unit, eye)
	_pixel_rect(node, origin, 12, 8, 1, 1, unit, eye)
	_pixel_rect(node, origin, 4, 10, 8, 7, unit, body)
	_pixel_rect(node, origin, 0, 11, 3, 2, unit, body)
	_pixel_rect(node, origin, -1, 13, 2, 4, unit, body)
	_pixel_rect(node, origin, 12, 11, 5, 2, unit, body)
	_pixel_rect(node, origin, 16, 13, 2, 2, unit, body)
	_pixel_rect(node, origin, 17, 15, 1, 2, unit, body)
	_pixel_rect(node, origin, 7, 11, 1, 1, unit, wound)
	_pixel_rect(node, origin, 9, 12, 1, 1, unit, wound)
	_pixel_rect(node, origin, 11, 14, 1, 1, unit, wound)
	_pixel_rect(node, origin, 5, 17, 3, 6, unit, body)
	_pixel_rect(node, origin, 10, 17, 3, 6, unit, body)
	_pixel_rect(node, origin, 4, 22, 5, 2, unit, body)
	_pixel_rect(node, origin, 10, 22, 5, 2, unit, body)

func _draw_menu_survivor(node: Control, pos: Vector2, draw_scale: float, seed: float) -> void:
	var unit: float = maxf(2.0, 3.1 * draw_scale)
	var bob: float = roundf(sin(menu_time * 2.8 + seed) * 1.3)
	var origin := pos + Vector2(-7.5 * unit, -20.0 * unit + bob)
	var skin := Color("#b9825c")
	var hair := Color("#1b1511")
	var jacket := Color("#151b20")
	var vest := ORANGE.darkened(0.18)
	var trouser := Color("#1b2529")
	var boot := Color("#050607")
	_pixel_rect(node, origin, 3, 19, 5, 2, unit, Color(0, 0, 0, 0.34))
	_pixel_rect(node, origin, 8, 19, 5, 2, unit, Color(0, 0, 0, 0.34))
	_pixel_rect(node, origin, 4, 0, 7, 1, unit, hair.darkened(0.1))
	_pixel_rect(node, origin, 3, 1, 9, 2, unit, hair)
	_pixel_rect(node, origin, 5, 3, 6, 4, unit, skin)
	_pixel_rect(node, origin, 5, 5, 1, 1, unit, RED.lightened(0.15))
	_pixel_rect(node, origin, 10, 5, 1, 1, unit, RED.lightened(0.15))
	_pixel_rect(node, origin, 7, 7, 3, 1, unit, skin.darkened(0.25))
	_pixel_rect(node, origin, 3, 9, 9, 6, unit, jacket)
	_pixel_rect(node, origin, 5, 9, 5, 5, unit, vest)
	_pixel_rect(node, origin, 2, 10, 2, 5, unit, skin.darkened(0.05))
	_pixel_rect(node, origin, 12, 10, 2, 5, unit, skin.darkened(0.05))
	_pixel_rect(node, origin, 12, 8, 1, 8, unit, RED.darkened(0.2))
	_pixel_rect(node, origin, 13, 7, 1, 2, unit, RED)
	_pixel_rect(node, origin, 4, 15, 4, 5, unit, trouser)
	_pixel_rect(node, origin, 9, 15, 4, 5, unit, trouser)
	_pixel_rect(node, origin, 3, 19, 5, 2, unit, boot)
	_pixel_rect(node, origin, 9, 19, 5, 2, unit, boot)

func _pixel_rect(node: Control, origin: Vector2, x: float, y: float, w: float, h: float, unit: float, color: Color) -> void:
	node.draw_rect(Rect2(origin + Vector2(x, y) * unit, Vector2(w, h) * unit), color, true)

func _draw_menu_barricade(node: Control, view_size: Vector2) -> void:
	var base_y: float = view_size.y * 0.82
	var start_x: float = view_size.x * 0.54
	for plank in range(5):
		var offset := Vector2(float(plank) * 54.0, sin(menu_time * 0.5 + float(plank)) * 1.5)
		var p0 := Vector2(start_x, base_y) + offset
		var p1 := p0 + Vector2(94.0, -34.0 + float(plank % 2) * 20.0)
		node.draw_line(p0 + Vector2(2, 3), p1 + Vector2(2, 3), Color(0, 0, 0, 0.4), 12)
		node.draw_line(p0, p1, Color("#3f2a1d"), 10)
		node.draw_line(p0, p1, Color("#7b4b2a"), 2)
	for post in range(4):
		var x: float = start_x + float(post) * 96.0
		node.draw_line(Vector2(x, base_y + 30.0), Vector2(x + 12.0, base_y - 62.0), Color("#17100b"), 12)
		node.draw_line(Vector2(x, base_y + 30.0), Vector2(x + 12.0, base_y - 62.0), Color("#4a2f1e"), 8)

func _add_button(parent: VBoxContainer, text: String, callback: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", accent.lightened(0.15))
	button.pressed.connect(FeedbackManager.ui_tap)
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
	_dismiss_modal()
	modal_overlay = ColorRect.new()
	modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_overlay.color = Color(0, 0, 0, 0.72)
	add_child(modal_overlay)
	modal_overlay.move_to_front()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24
	center.offset_top = 24
	center.offset_right = -24
	center.offset_bottom = -24
	modal_overlay.add_child(center)
	var panel := _panel(center)
	panel.add_child(_label("DEAD SHIFT", 22, ORANGE))
	var body := _label(message, 16, TEXT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(body)
	var ok := _add_button(panel, "OK", _dismiss_modal, GREEN)
	ok.custom_minimum_size = Vector2(0, 46)

func _dismiss_modal() -> void:
	if modal_overlay != null and is_instance_valid(modal_overlay):
		modal_overlay.queue_free()
	modal_overlay = null
