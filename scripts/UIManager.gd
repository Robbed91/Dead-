extends Control

@export var initial_tab := "Buildings"

const TABS := ["Buildings", "Survivors", "Scavenge", "Crafting", "Defence", "Radio"]
const BG := Color("#080b0d")
const PANEL := Color("#13181d")
const PANEL_DARK := Color("#0d1115")
const PANEL_LIGHT := Color("#242c33")
const ORANGE := Color("#f28c28")
const RED := Color("#c23b33")
const GREEN := Color("#70b86b")
const BLUE := Color("#4aa3df")
const YELLOW := Color("#d9aa38")
const TEXT := Color("#e8e0d2")
const MUTED := Color("#91a0a6")
const HIDEOUT_BACKGROUND := preload("res://assets/backgrounds/hideout.png")
const CAMP_BACKGROUND := preload("res://assets/backgrounds/camp.png")
const COMMUNITY_BACKGROUND := preload("res://assets/backgrounds/community.png")
const SETTLEMENT_BACKGROUND := preload("res://assets/backgrounds/settlement.png")
const DISTRICT_BACKGROUND := preload("res://assets/backgrounds/district.png")
const CITY_BACKGROUND := preload("res://assets/backgrounds/city.png")

const BUILDING_LAYOUT := {
	"Main Warehouse": Rect2(0.36, 0.34, 0.25, 0.24),
	"Signage Workshop": Rect2(0.18, 0.23, 0.18, 0.18),
	"Builder's Merchant": Rect2(0.08, 0.48, 0.18, 0.19),
	"Pharmacy": Rect2(0.64, 0.27, 0.15, 0.17),
	"Garage": Rect2(0.08, 0.18, 0.15, 0.16),
	"Security Office": Rect2(0.51, 0.12, 0.16, 0.16),
	"Food Distribution Unit": Rect2(0.69, 0.52, 0.19, 0.19),
	"Self-Storage Units": Rect2(0.29, 0.62, 0.21, 0.18),
	"Office Block": Rect2(0.55, 0.63, 0.17, 0.2),
}

const HIDEOUT_LAYOUT := {
	"Main Warehouse": Rect2(0.24, 0.34, 0.25, 0.24),
	"Signage Workshop": Rect2(0.55, 0.25, 0.07, 0.08),
	"Builder's Merchant": Rect2(0.16, 0.68, 0.07, 0.08),
	"Pharmacy": Rect2(0.71, 0.38, 0.07, 0.08),
	"Garage": Rect2(0.12, 0.28, 0.07, 0.08),
	"Security Office": Rect2(0.52, 0.12, 0.07, 0.08),
	"Food Distribution Unit": Rect2(0.79, 0.61, 0.07, 0.08),
	"Self-Storage Units": Rect2(0.43, 0.74, 0.07, 0.08),
	"Office Block": Rect2(0.66, 0.73, 0.07, 0.08),
}

var active_tab := "Buildings"
var selected_building_id := 1
var selected_scavenger_id := 1
var selected_building_use: Dictionary = {}
var selected_building_survivor: Dictionary = {}
var tab_buttons: Dictionary = {}
var building_buttons: Dictionary = {}
var survivor_tokens: Dictionary = {}
var zombie_tokens: Array = []

var resource_row: HBoxContainer
var colony_strip: HBoxContainer
var phase_label: Label
var objective_body: Label
var alerts_box: VBoxContainer
var event_log_box: VBoxContainer
var estate_board: Control
var survivors_box: VBoxContainer
var command_title: Label
var command_body: HBoxContainer
var selected_building_label: Label
var night_preview_label: Label
var end_day_button: Button
var quick_bar: HBoxContainer
var modal_overlay: Control
var ambient_time := 0.0

func _ready() -> void:
	active_tab = initial_tab if TABS.has(initial_tab) else "Buildings"
	_build_theme()
	_build_layout()
	_connect_signals()
	_refresh()

func _process(delta: float) -> void:
	ambient_time += delta
	if estate_board == null:
		return
	var map := estate_board.get_child(0) as Control
	if map != null:
		map.queue_redraw()

func _build_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = 13
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = PANEL_LIGHT
	button_style.border_color = Color("#46515c")
	button_style.border_width_left = 1
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.corner_radius_top_left = 4
	button_style.corner_radius_top_right = 4
	button_style.corner_radius_bottom_left = 4
	button_style.corner_radius_bottom_right = 4
	var pressed_style := button_style.duplicate()
	pressed_style.bg_color = Color("#3a2410")
	pressed_style.border_color = ORANGE
	theme.set_stylebox("normal", "Button", button_style)
	theme.set_stylebox("hover", "Button", button_style)
	theme.set_stylebox("pressed", "Button", pressed_style)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_color", "Label", TEXT)
	set_theme(theme)

func _build_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 6
	root.offset_top = 5
	root.offset_right = -6
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 5)
	add_child(root)

	_build_top_bar(root)
	_build_middle(root)
	_build_command_bar(root)
	_build_quick_bar()

func _build_top_bar(root: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 70)
	top.add_theme_constant_override("separation", 6)
	root.add_child(top)

	var logo := _add_panel(top, Vector2(200, 0))
	logo.add_child(_label("DEAD SHIFT", 32, ORANGE, HORIZONTAL_ALIGNMENT_CENTER))
	logo.add_child(_label("COLONY SURVIVAL", 12, RED, HORIZONTAL_ALIGNMENT_CENTER))

	var day_panel := _add_panel(top, Vector2(90, 0))
	day_panel.add_child(_label("DAY", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	day_panel.add_child(_label("1", 28, TEXT, HORIZONTAL_ALIGNMENT_CENTER, "day_value"))
	phase_label = _label("MORNING", 9, ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	day_panel.add_child(phase_label)

	resource_row = HBoxContainer.new()
	resource_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.add_theme_constant_override("separation", 4)
	top.add_child(resource_row)

	colony_strip = HBoxContainer.new()
	colony_strip.custom_minimum_size = Vector2(320, 0)
	colony_strip.add_theme_constant_override("separation", 4)
	top.add_child(colony_strip)

func _build_middle(root: VBoxContainer) -> void:
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 5)
	root.add_child(middle)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(230, 0)
	left.add_theme_constant_override("separation", 5)
	middle.add_child(left)
	_build_left_panel(left)

	estate_board = _estate_board()
	estate_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	estate_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(estate_board)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(250, 0)
	right.add_theme_constant_override("separation", 5)
	middle.add_child(right)
	_build_right_panel(right)

func _build_left_panel(left: VBoxContainer) -> void:
	var objective := _add_panel(left, Vector2(0, 118))
	objective.add_child(_label("CURRENT OBJECTIVE", 13, GREEN))
	objective_body = _label("", 13, TEXT)
	objective_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_child(objective_body)

	var alerts := _add_panel(left, Vector2(0, 126))
	alerts.add_child(_label("ALERTS", 13, RED))
	alerts_box = VBoxContainer.new()
	alerts_box.add_theme_constant_override("separation", 3)
	alerts.add_child(alerts_box)

	var map := _add_panel(left, Vector2(0, 140))
	map.add_child(_label("ESTATE MAP", 13, TEXT))
	var grid := Control.new()
	grid.custom_minimum_size = Vector2(0, 82)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.draw.connect(_draw_estate_minimap.bind(grid))
	map.add_child(grid)
	var scout := _small_button("SCOUT LOCATION")
	scout.pressed.connect(_show_scavenge_popup)
	map.add_child(scout)

	var log := _add_panel(left, Vector2(0, 0))
	log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log.add_child(_label("EVENT LOG", 13, ORANGE))
	event_log_box = VBoxContainer.new()
	event_log_box.add_theme_constant_override("separation", 2)
	log.add_child(event_log_box)

func _build_right_panel(right: VBoxContainer) -> void:
	var current := _add_panel(right, Vector2(0, 96))
	current.add_child(_label("CURRENT BUILDING", 13, TEXT))
	selected_building_label = _label("", 12, TEXT)
	selected_building_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current.add_child(selected_building_label)

	var survivors := _add_panel(right, Vector2(0, 0))
	survivors.size_flags_vertical = Control.SIZE_EXPAND_FILL
	survivors.add_child(_label("SURVIVORS", 13, GREEN))
	var survivor_scroll := ScrollContainer.new()
	survivor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	survivor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	survivors.add_child(survivor_scroll)
	survivors_box = VBoxContainer.new()
	survivors_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	survivors_box.add_theme_constant_override("separation", 4)
	survivor_scroll.add_child(survivors_box)

	var defence := _add_panel(right, Vector2(0, 118))
	defence.add_child(_label("NIGHT DEFENCE", 13, RED))
	night_preview_label = _label("", 11, TEXT)
	night_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	defence.add_child(night_preview_label)
	var prep := _small_button("PREPARE DEFENCES")
	prep.add_theme_color_override("font_color", RED.lightened(0.25))
	prep.pressed.connect(_show_defence_popup)
	defence.add_child(prep)

func _build_command_bar(root: VBoxContainer) -> void:
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size = Vector2(0, 104)
	bottom.add_theme_constant_override("separation", 4)
	root.add_child(bottom)

	var tabs := _add_panel(bottom, Vector2(332, 0))
	tabs.add_child(_label("BUILD & MANAGE", 13, TEXT))
	var tab_grid := GridContainer.new()
	tab_grid.columns = 3
	tab_grid.add_theme_constant_override("h_separation", 4)
	tab_grid.add_theme_constant_override("v_separation", 4)
	tabs.add_child(tab_grid)
	for tab in TABS:
		var button := _small_button(tab)
		button.custom_minimum_size = Vector2(100, 32)
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_switch_tab.bind(tab))
		tab_grid.add_child(button)
		tab_buttons[tab] = button

	var commands := _add_panel(bottom, Vector2(0, 0))
	commands.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_title = _label("BUILDINGS", 13, ORANGE)
	commands.add_child(command_title)
	var command_scroll := ScrollContainer.new()
	command_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	command_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	command_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	commands.add_child(command_scroll)
	command_body = HBoxContainer.new()
	command_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_body.add_theme_constant_override("separation", 5)
	command_scroll.add_child(command_body)

	var end := _add_panel(bottom, Vector2(170, 0))
	end.add_child(_label("NEXT PHASE: NIGHT", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	end_day_button = _small_button("END DAY")
	end_day_button.custom_minimum_size = Vector2(0, 46)
	end_day_button.add_theme_font_size_override("font_size", 20)
	end_day_button.add_theme_color_override("font_color", RED.lightened(0.25))
	end_day_button.pressed.connect(func(): _show_result(GameManager.end_day()["message"]))
	end.add_child(end_day_button)

func _build_quick_bar() -> void:
	quick_bar = HBoxContainer.new()
	quick_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quick_bar.offset_left = -466
	quick_bar.offset_top = 82
	quick_bar.offset_right = -10
	quick_bar.offset_bottom = 132
	quick_bar.add_theme_constant_override("separation", 6)
	add_child(quick_bar)
	var build := _small_button("BUILD")
	build.custom_minimum_size = Vector2(78, 44)
	build.pressed.connect(_show_build_popup)
	quick_bar.add_child(build)
	var scout := _small_button("SCOUT")
	scout.custom_minimum_size = Vector2(84, 44)
	scout.pressed.connect(_show_scavenge_popup)
	quick_bar.add_child(scout)
	var defence := _small_button("DEFEND")
	defence.custom_minimum_size = Vector2(86, 44)
	defence.pressed.connect(_show_defence_popup)
	quick_bar.add_child(defence)
	var save := _small_button("SAVE")
	save.custom_minimum_size = Vector2(76, 44)
	save.pressed.connect(func(): _show_result("Saved." if GameManager.manual_save() else "Save failed."))
	quick_bar.add_child(save)
	var menu := _small_button("MENU")
	menu.custom_minimum_size = Vector2(82, 44)
	menu.pressed.connect(_show_game_menu)
	quick_bar.add_child(menu)

func _estate_board() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1417")
	style.border_color = Color("#33404a")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)

	var map := Control.new()
	map.name = "EstateMap"
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(map)
	map.draw.connect(_draw_estate_map.bind(map))
	map.resized.connect(func(): _position_building_buttons(map))

	for building in BuildingManager.buildings:
		var button := Button.new()
		button.text = _building_button_text(building)
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_stylebox_override("normal", _map_button_style(Color(0.04, 0.05, 0.06, 0.34), Color(0.85, 0.9, 0.92, 0.65)))
		button.add_theme_stylebox_override("hover", _map_button_style(Color(0.14, 0.09, 0.04, 0.48), ORANGE))
		button.add_theme_stylebox_override("pressed", _map_button_style(Color(0.2, 0.11, 0.03, 0.56), ORANGE))
		button.pressed.connect(_select_building.bind(int(building["id"])))
		map.add_child(button)
		building_buttons[int(building["id"])] = button
	for survivor in SurvivorManager.survivors:
		var token := _survivor_map_token(survivor)
		token.custom_minimum_size = Vector2(22, 22)
		token.size = Vector2(22, 22)
		token.tooltip_text = "%s - %s" % [survivor["name"], survivor["assigned_task"]]
		token.pressed.connect(_show_task_popup.bind(int(survivor["id"])))
		map.add_child(token)
		survivor_tokens[int(survivor["id"])] = token
	return panel

func _draw_estate_map(map: Control) -> void:
	var size := map.size
	map.draw_rect(Rect2(Vector2.ZERO, size), Color("#101519"), true)
	var background := _stage_background()
	map.draw_texture_rect(background, Rect2(Vector2.ZERO, size), false, Color(0.96, 0.96, 0.96, 0.94))
	map.draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.12), true)
	_draw_growth_perimeter(map)
	var fire_pulse := 0.72 + (sin(ambient_time * 6.0) + 1.0) * 0.12
	map.draw_circle(size * Vector2(0.48, 0.5), 34, Color(0.843, 0.467, 0.145, 0.16 * fire_pulse))
	map.draw_circle(size * Vector2(0.48, 0.5), 18, Color(0.843, 0.467, 0.145, 0.62 * fire_pulse))
	map.draw_circle(size * Vector2(0.48, 0.5), 9, Color(0.3, 0.12, 0.035, 0.8))
	for i in range(18):
		var pos := Vector2(fmod(float(i * 73), size.x), fmod(float(i * 47 + 31), size.y))
		_draw_map_light(map, pos, 2.0 + sin(ambient_time * 2.4 + float(i)) * 0.6, ORANGE)
	var threat_count: int = clampi(int(ResourceManager.get_value("horde_threat") / 6), 2, 13)
	for i in range(threat_count):
		var wave: float = sin(ambient_time * 1.4 + i)
		var pos: Vector2 = Vector2(size.x * (0.05 + float(i) / maxf(1.0, float(threat_count)) * 0.9), size.y * 0.94 + wave * 4.0)
		_draw_zombie_silhouette(map, pos, 0.75, RED.darkened(0.15))
	for building in BuildingManager.buildings:
		var rect := _building_rect(map, building)
		if _is_expansion_marker(building):
			_draw_expansion_marker(map, building, rect)
			continue
		var color := _building_color(building).darkened(0.15)
		map.draw_rect(rect.grow(3), Color(0.02, 0.024, 0.027, 0.32), true)
		map.draw_rect(rect, Color(color.r, color.g, color.b, 0.28), true)
		map.draw_rect(rect, Color(0.82, 0.88, 0.91, 0.78), false, 2)
		_draw_building_detail(map, building, rect)

func _draw_building_detail(map: Control, building: Dictionary, rect: Rect2) -> void:
	var roof := Rect2(rect.position + Vector2(0, 3), Vector2(rect.size.x, max(6.0, rect.size.y * 0.16)))
	map.draw_rect(roof, Color("#050607").lightened(0.08), true)
	var use_icon_pos := rect.position + rect.size * Vector2(0.16, 0.31)
	_draw_building_use_icon(map, String(building.get("current_use", "")), use_icon_pos, minf(rect.size.x, rect.size.y) * 0.12)
	var condition: float = clampf(float(building.get("condition", 0)) / 100.0, 0.0, 1.0)
	var security: float = clampf(float(building.get("security", 0)) / 100.0, 0.0, 1.0)
	var infestation: float = clampf(float(building.get("infestation", 0)) / 100.0, 0.0, 1.0)
	var bar_w: float = maxf(18.0, rect.size.x - 10.0)
	_draw_map_bar(map, rect.position + Vector2(5, rect.size.y - 18), bar_w, condition, GREEN)
	_draw_map_bar(map, rect.position + Vector2(5, rect.size.y - 12), bar_w, security, BLUE)
	if infestation > 0.0:
		_draw_map_bar(map, rect.position + Vector2(5, rect.size.y - 6), bar_w, infestation, RED)
	var pulse := (sin(ambient_time * 3.0 + rect.position.x * 0.03) + 1.0) * 0.5
	if ["Claimed", "Operational", "Fortified"].has(String(building.get("status", ""))):
		var lamp := rect.position + rect.size * Vector2(0.82, 0.28)
		_draw_map_light(map, lamp, 5.0 + pulse * 3.0, ORANGE)
	if String(building.get("status", "")) == "Infested":
		_draw_zombie_silhouette(map, rect.position + rect.size * Vector2(0.78, 0.68), 0.75, RED)

func _draw_expansion_marker(map: Control, building: Dictionary, rect: Rect2) -> void:
	var pulse := 0.55 + (sin(ambient_time * 2.8 + float(building.get("id", 0))) + 1.0) * 0.15
	var center := rect.position + rect.size * 0.5
	var color := BLUE if String(building.get("status", "")) == "Scouted" else MUTED
	map.draw_circle(center, 18.0, Color(0.0, 0.0, 0.0, 0.52))
	map.draw_circle(center, 13.0 + pulse * 2.0, Color(color.r, color.g, color.b, 0.32))
	map.draw_circle(center, 4.0, color)

func _draw_growth_perimeter(map: Control) -> void:
	var size := map.size
	var tier_index := GameManager.colony_tier_index
	var color := GREEN if tier_index >= 2 else ORANGE
	for i in range(tier_index + 1):
		var inset := 10.0 + float(i) * 10.0
		map.draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0)), Color(color.r, color.g, color.b, 0.08), false, 2)

func _draw_map_light(map: Control, pos: Vector2, radius: float, color: Color) -> void:
	map.draw_circle(pos, radius * 4.0, Color(color.r, color.g, color.b, 0.08))
	map.draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.72))

func _draw_zombie_silhouette(map: Control, pos: Vector2, scale: float, color: Color) -> void:
	var sway := sin(ambient_time * 2.2 + pos.x * 0.01) * 2.0
	map.draw_circle(pos + Vector2(sway, -10) * scale, 4.5 * scale, color)
	map.draw_line(pos + Vector2(sway, -6) * scale, pos + Vector2(-1, 7) * scale, color, 3.0 * scale)
	map.draw_line(pos + Vector2(-1, -2) * scale, pos + Vector2(-9, 5) * scale, color, 2.0 * scale)
	map.draw_line(pos + Vector2(0, -2) * scale, pos + Vector2(8, 4) * scale, color, 2.0 * scale)
	map.draw_line(pos + Vector2(-1, 7) * scale, pos + Vector2(-6, 15) * scale, color, 2.0 * scale)
	map.draw_line(pos + Vector2(0, 7) * scale, pos + Vector2(7, 15) * scale, color, 2.0 * scale)

func _draw_building_use_icon(map: Control, use_name: String, pos: Vector2, scale: float) -> void:
	var icon_color := _use_icon_color(use_name)
	map.draw_circle(pos, maxf(4.0, scale * 1.6), Color(0.0, 0.0, 0.0, 0.48))
	match use_name:
		"Medical Bay":
			map.draw_line(pos + Vector2(-scale, 0), pos + Vector2(scale, 0), icon_color, 2)
			map.draw_line(pos + Vector2(0, -scale), pos + Vector2(0, scale), icon_color, 2)
		"Watch Post":
			map.draw_arc(pos, scale, PI, TAU, 8, icon_color, 2)
			map.draw_line(pos, pos + Vector2(0, scale), icon_color, 2)
		"Workshop":
			map.draw_line(pos + Vector2(-scale, scale), pos + Vector2(scale, -scale), icon_color, 2)
		"Food Prep":
			map.draw_circle(pos, maxf(2.0, scale * 0.55), icon_color)
			map.draw_line(pos + Vector2(scale * 0.6, -scale * 0.7), pos + Vector2(scale * 1.2, -scale * 1.2), icon_color, 2)
		"Sleeping Quarters":
			map.draw_rect(Rect2(pos - Vector2(scale, scale * 0.35), Vector2(scale * 2.0, scale * 0.7)), icon_color, false, 2)
		"Vehicle Bay":
			map.draw_rect(Rect2(pos - Vector2(scale, scale * 0.55), Vector2(scale * 2.0, scale * 1.1)), icon_color, false, 2)
		_:
			map.draw_circle(pos, maxf(2.0, scale * 0.45), icon_color)

func _use_icon_color(use_name: String) -> Color:
	match use_name:
		"Medical Bay":
			return GREEN
		"Watch Post":
			return RED
		"Workshop":
			return ORANGE
		"Food Prep":
			return YELLOW
		"Sleeping Quarters":
			return BLUE
		"Vehicle Bay":
			return TEXT
	return MUTED

func _draw_estate_minimap(node: Control) -> void:
	var size := node.size
	node.draw_rect(Rect2(Vector2.ZERO, size), Color("#0a0f13"), true)
	node.draw_rect(Rect2(Vector2.ZERO, size), Color("#34404a"), false, 1)
	var points := [
		Vector2(0.18, 0.45), Vector2(0.35, 0.3), Vector2(0.55, 0.36),
		Vector2(0.74, 0.25), Vector2(0.25, 0.7), Vector2(0.48, 0.66),
		Vector2(0.68, 0.72), Vector2(0.84, 0.56), Vector2(0.1, 0.18)
	]
	for i in range(points.size()):
		var building: Dictionary = BuildingManager.buildings[i]
		var pos := Vector2(points[i].x * size.x, points[i].y * size.y)
		var color := _building_color(building)
		var radius := 5.0 if String(building.get("status", "")) == "Unknown" else 7.0
		node.draw_circle(pos, radius + 4.0, Color(0, 0, 0, 0.45))
		node.draw_circle(pos, radius, color)
		if i > 0:
			var prev := Vector2(points[i - 1].x * size.x, points[i - 1].y * size.y)
			node.draw_line(prev, pos, Color("#3b454e"), 1)

func _draw_map_bar(map: Control, pos: Vector2, width: float, value: float, color: Color) -> void:
	map.draw_rect(Rect2(pos, Vector2(width, 3)), Color("#060809"), true)
	map.draw_rect(Rect2(pos, Vector2(width * value, 3)), color, true)

func _position_building_buttons(map: Control) -> void:
	for building in BuildingManager.buildings:
		var id := int(building["id"])
		if not building_buttons.has(id):
			continue
		var button: Button = building_buttons[id]
		button.text = _building_button_text(building)
		button.add_theme_font_size_override("font_size", 12 if not _is_expansion_marker(building) else 18)
		var rect := _building_rect(map, building).grow(-4)
		button.position = rect.position
		button.size = rect.size

func _building_rect(map: Control, building: Dictionary) -> Rect2:
	var layouts := HIDEOUT_LAYOUT if GameManager.colony_tier_index == 0 else BUILDING_LAYOUT
	var layout: Rect2 = layouts.get(String(building["name"]), Rect2(0.4, 0.4, 0.16, 0.16))
	return Rect2(Vector2(layout.position.x * map.size.x, layout.position.y * map.size.y), Vector2(layout.size.x * map.size.x, layout.size.y * map.size.y))

func _stage_background() -> Texture2D:
	match GameManager.colony_tier_index:
		0:
			return HIDEOUT_BACKGROUND
		1:
			return CAMP_BACKGROUND
		2:
			return COMMUNITY_BACKGROUND
		3:
			return SETTLEMENT_BACKGROUND
		4:
			return DISTRICT_BACKGROUND
		_:
			return CITY_BACKGROUND

func _is_expansion_marker(building: Dictionary) -> bool:
	if GameManager.colony_tier_index >= 2:
		return false
	if String(building.get("status", "")) in ["Claimed", "Operational", "Fortified"]:
		return false
	return String(building.get("status", "")) in ["Unknown", "Scouted", "Infested", "Cleared"]

func _connect_signals() -> void:
	GameManager.state_changed.connect(_refresh)
	GameManager.log_changed.connect(_refresh_log)
	ResourceManager.resources_changed.connect(_refresh)
	SurvivorManager.survivors_changed.connect(_refresh)
	BuildingManager.buildings_changed.connect(_refresh)
	ActivityManager.activity_changed.connect(_refresh_activity)
	NightDefenseManager.night_resolved.connect(_show_night_wave)
	GameManager.recruit_found.connect(_show_recruit_popup)
	GameManager.game_over.connect(_show_game_over)

func _switch_tab(tab: String) -> void:
	active_tab = tab
	_refresh()

func _select_building(id: int) -> void:
	selected_building_id = id
	active_tab = "Buildings"
	_refresh()

func _refresh() -> void:
	if resource_row == null:
		return
	_refresh_top_bar()
	_refresh_alerts()
	_refresh_log()
	_refresh_survivors()
	_refresh_estate()
	_refresh_selected_building()
	_refresh_night_preview()
	_refresh_commands()

func _refresh_top_bar() -> void:
	_clear(resource_row)
	_clear(colony_strip)
	var r := ResourceManager.resources
	var top_resources := [
		["FOOD", r["food"], GREEN],
		["WATER", r["water"], BLUE],
		["FUEL", r["fuel"], ORANGE],
		["POWER", str(r["power"]) + "%", YELLOW],
		["MATERIALS", r["materials"], ORANGE],
		["MEDICINE", r["medicine"], GREEN],
		["AMMO", r["ammo"], RED],
		["TOOLS", r["tools"], TEXT],
	]
	for item in top_resources:
		resource_row.add_child(_stat_chip(String(item[0]), str(item[1]), item[2]))
	colony_strip.add_child(_stat_chip("MORALE", str(r["morale"]) + "%", GREEN))
	colony_strip.add_child(_stat_chip("SECURITY", str(r["security"]) + "%", BLUE))
	colony_strip.add_child(_stat_chip("NOISE", str(r["noise"]) + "%", ORANGE))
	colony_strip.add_child(_stat_chip("THREAT", _threat_label(), RED))
	colony_strip.add_child(_stat_chip("STAGE", String(GameManager.get_colony_tier()["name"]).to_upper(), ORANGE))
	colony_strip.add_child(_stat_chip("CREW", "%d/%d" % [SurvivorManager.get_crew_count(), SurvivorManager.get_direct_control_limit()], BLUE))
	var day_label := find_child("day_value", true, false)
	if day_label != null:
		day_label.text = str(r["day_number"])
	if phase_label != null:
		phase_label.text = GameManager.phase.to_upper()

func _refresh_alerts() -> void:
	objective_body.text = "%s\n%s" % [GameManager.current_objective, GameManager.get_colony_growth_summary()]
	_clear(alerts_box)
	var r := ResourceManager.resources
	var alerts: Array = []
	if int(r["horde_threat"]) >= 40:
		alerts.append(["ZOMBIE HORDE APPROACHING", RED])
	if int(r["food"]) < 25:
		alerts.append(["LOW FOOD SUPPLIES", YELLOW])
	if int(r["fuel"]) < 15:
		alerts.append(["GENERATOR LOW FUEL", ORANGE])
	if int(r["infection_risk"]) >= 20:
		alerts.append(["INFECTION RISK RISING", GREEN])
	if alerts.is_empty():
		alerts.append(["PERIMETER QUIET", GREEN])
	for alert in alerts:
		alerts_box.add_child(_label(String(alert[0]), 11, alert[1]))

func _refresh_log() -> void:
	if event_log_box == null:
		return
	_clear(event_log_box)
	for entry in GameManager.event_log.slice(0, 7):
		var label := _label(entry, 10, TEXT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		event_log_box.add_child(label)

func _refresh_survivors() -> void:
	_clear(survivors_box)
	for survivor in SurvivorManager.survivors:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		survivors_box.add_child(row)
		var portrait := _survivor_portrait(survivor, Vector2(34, 34))
		row.add_child(portrait)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var job := ActivityManager.get_job(int(survivor["id"]))
		var job_suffix := ""
		if String(job.get("location", "")) != "":
			job_suffix = " @ %s" % String(job["location"])
		var mode := String(survivor.get("control_mode", "NPC"))
		var mode_color := BLUE if mode == "Crew" else MUTED
		details.add_child(_label("%s  %s  HP %s%%  INF %s%%" % [survivor["name"], mode.to_upper(), survivor["health"], survivor["infection_risk"]], 12, mode_color))
		details.add_child(_label("%s - %s - %s%s" % [survivor["role"], survivor["status"], survivor["assigned_task"], job_suffix], 9, MUTED))
		var progress := ProgressBar.new()
		progress.custom_minimum_size = Vector2(0, 8)
		progress.max_value = 1.0
		progress.value = ActivityManager.get_progress(int(survivor["id"]))
		progress.show_percentage = false
		details.add_child(progress)
		var task := _small_button("Assign" if mode == "Crew" else "NPC")
		task.custom_minimum_size = Vector2(58, 34)
		task.pressed.connect(_show_task_popup.bind(int(survivor["id"])))
		row.add_child(task)

func _refresh_estate() -> void:
	if estate_board == null:
		return
	var map := estate_board.get_child(0) as Control
	if map == null:
		return
	for building in BuildingManager.buildings:
		var id := int(building["id"])
		if building_buttons.has(id):
			var button: Button = building_buttons[id]
			button.text = _building_button_text(building)
			button.modulate = ORANGE if id == selected_building_id else Color.WHITE
	_position_building_buttons(map)
	_position_survivor_tokens(map)
	map.queue_redraw()

func _refresh_activity() -> void:
	if resource_row == null:
		return
	_refresh_log()
	_refresh_survivors()
	_refresh_estate()
	_refresh_night_preview()

func _show_night_wave(result: Dictionary) -> void:
	if estate_board == null:
		return
	var map := estate_board.get_child(0) as Control
	if map == null:
		return
	var count := 10 if bool(result.get("success", false)) else 18
	for i in range(count):
		var token := _zombie_wave_token(not bool(result.get("success", false)))
		token.custom_minimum_size = Vector2(10, 10)
		token.size = Vector2(18, 26)
		var side := i % 4
		var start := Vector2.ZERO
		match side:
			0:
				start = Vector2(randf_range(0, map.size.x), -12)
			1:
				start = Vector2(map.size.x + 12, randf_range(0, map.size.y))
			2:
				start = Vector2(randf_range(0, map.size.x), map.size.y + 12)
			3:
				start = Vector2(-12, randf_range(0, map.size.y))
		token.position = start
		map.add_child(token)
		zombie_tokens.append(token)
		var target := map.size * Vector2(randf_range(0.38, 0.62), randf_range(0.38, 0.62))
		var tween := create_tween()
		tween.tween_property(token, "position", target, randf_range(0.7, 1.2))
		tween.tween_property(token, "modulate:a", 0.0, 0.45)
		tween.tween_callback(token.queue_free)

func _zombie_wave_token(danger: bool) -> Control:
	var token := Control.new()
	var color := RED if danger else ORANGE
	token.draw.connect(func(): _draw_zombie_token(token, color))
	return token

func _draw_zombie_token(token: Control, color: Color) -> void:
	var center := token.size * Vector2(0.5, 0.55)
	_draw_zombie_silhouette(token, center, 1.0, color)

func _position_survivor_tokens(map: Control) -> void:
	for survivor in SurvivorManager.survivors:
		var id := int(survivor["id"])
		if not survivor_tokens.has(id):
			var token := _survivor_map_token(survivor)
			token.custom_minimum_size = Vector2(22, 22)
			token.size = Vector2(22, 22)
			token.pressed.connect(_show_task_popup.bind(id))
			map.add_child(token)
			survivor_tokens[id] = token
		var token: Button = survivor_tokens[id]
		token.tooltip_text = "%s - %s" % [survivor["name"], survivor["assigned_task"]]
		token.modulate = Color.WHITE
		var destination := _survivor_destination(map, survivor, id)
		var progress := int(ActivityManager.get_progress(id) * 100.0)
		token.text = str(progress)
		token.queue_redraw()
		var tween := create_tween()
		tween.tween_property(token, "position", destination - token.size * 0.5, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _survivor_destination(map: Control, survivor: Dictionary, id: int) -> Vector2:
	var building := _building_for_survivor(survivor)
	var rect := _building_rect(map, building) if not building.is_empty() else Rect2(map.size * Vector2(0.45, 0.48), Vector2(80, 60))
	var offset := Vector2(float((id * 23) % 46) - 23.0, float((id * 37) % 34) - 17.0)
	match String(survivor.get("assigned_task", "Rest")):
		"Guard":
			offset += Vector2(32, -28)
		"Scavenge", "Scout":
			offset += Vector2(-40, 30)
		"Build", "Repair":
			offset += Vector2(28, 22)
		"Medical":
			offset += Vector2(-8, -18)
		"Cook":
			offset += Vector2(0, 24)
	offset += Vector2(sin(ambient_time * 2.0 + float(id)) * 4.0, cos(ambient_time * 1.7 + float(id)) * 3.0)
	return rect.position + rect.size * 0.5 + offset

func _building_for_survivor(survivor: Dictionary) -> Dictionary:
	var activity_target := ActivityManager.get_target(int(survivor["id"]))
	if activity_target != "":
		for building in BuildingManager.buildings:
			if String(building["name"]) == activity_target:
				return building
	var assigned_building := String(survivor.get("assigned_building", ""))
	for building in BuildingManager.buildings:
		if String(building["name"]) == assigned_building:
			return building
	match String(survivor.get("assigned_task", "Rest")):
		"Guard":
			return _building_by_use_or_name("Watch Post", "Security Office")
		"Build", "Repair":
			return _building_by_use_or_name("Workshop", "Signage Workshop")
		"Medical":
			return _building_by_use_or_name("Medical Bay", "Pharmacy")
		"Cook":
			return _building_by_use_or_name("Food Prep", "Food Distribution Unit")
		"Scavenge", "Scout":
			return _building_by_use_or_name("Vehicle Bay", "Garage")
	return _building_by_use_or_name("Sleeping Quarters", "Main Warehouse")

func _building_by_use_or_name(use_name: String, fallback_name: String) -> Dictionary:
	for building in BuildingManager.buildings:
		if String(building.get("current_use", "")) == use_name:
			return building
	for building in BuildingManager.buildings:
		if String(building.get("name", "")) == fallback_name:
			return building
	return _selected_building()

func _refresh_selected_building() -> void:
	var building := _selected_building()
	if building.is_empty():
		selected_building_label.text = "Select a building."
		return
	var upgrades := Array(building.get("upgrades", []))
	var upgrade_names: Array = []
	for upgrade_id in upgrades:
		upgrade_names.append(BuildingManager.get_upgrade_name(String(upgrade_id)))
	var upgrade_text := "None" if upgrade_names.is_empty() else ", ".join(upgrade_names)
	selected_building_label.text = "%s\n%s | %s\nCond %d  Sec %d  Inf %d\nUpgrades: %s" % [_building_display_name(building), building["status"], building["current_use"], building["condition"], building["security"], building["infestation"], upgrade_text]

func _refresh_night_preview() -> void:
	if night_preview_label == null:
		return
	var preview := NightDefenseManager.get_preview()
	var attack := int(preview["attack_strength"])
	var defence := int(preview["defence_strength"])
	var state := "HOLDING" if defence >= attack else "AT RISK"
	night_preview_label.text = "Attack %d  Defence %d\nGuards %d  Fort %d  Upgrades %d\n%s" % [attack, defence, int(preview["guards"]), int(preview["fortified_bonus"]), int(preview.get("upgrade_bonus", 0)), state]

func _refresh_commands() -> void:
	for tab in TABS:
		tab_buttons[tab].modulate = ORANGE if tab == active_tab else Color.WHITE
		tab_buttons[tab].disabled = GameManager.is_game_over()
	end_day_button.disabled = GameManager.is_game_over()
	_clear(command_body)
	command_title.text = active_tab.to_upper()
	if GameManager.is_game_over():
		command_body.add_child(_label(GameManager.game_over_message, 14, RED))
		return
	match active_tab:
		"Buildings":
			_build_building_commands()
		"Survivors":
			_build_survivor_commands()
		"Scavenge":
			_build_scavenge_commands()
		"Crafting":
			_build_crafting_commands()
		"Defence":
			_build_defence_commands()
		"Radio":
			_build_radio_commands()

func _build_building_commands() -> void:
	var building := _selected_building()
	if building.is_empty():
		command_body.add_child(_label("Tap a building in the estate.", 13, TEXT))
		return
	for action in ["Scout", "Clear", "Claim", "Repair", "Fortify"]:
		var button := _small_button(action)
		button.custom_minimum_size = Vector2(94, 54)
		button.disabled = not _can_building_action(building, action)
		button.pressed.connect(_on_building_action.bind(int(building["id"]), action))
		command_body.add_child(button)
	var use_select := OptionButton.new()
	use_select.custom_minimum_size = Vector2(160, 54)
	for use_name in BuildingManager.USES:
		use_select.add_item(use_name)
		if String(building.get("current_use", "")) == use_name:
			use_select.select(use_select.get_item_count() - 1)
	var id := int(building["id"])
	selected_building_use[id] = String(building.get("current_use", BuildingManager.USES[0])) if not selected_building_use.has(id) else selected_building_use[id]
	use_select.item_selected.connect(_on_building_use_selected.bind(use_select, id))
	command_body.add_child(use_select)
	var set_use := _small_button("SET USE")
	set_use.custom_minimum_size = Vector2(90, 54)
	set_use.pressed.connect(_on_assign_building_use.bind(id))
	command_body.add_child(set_use)
	var survivor_select := OptionButton.new()
	survivor_select.custom_minimum_size = Vector2(140, 54)
	var crew_survivors := SurvivorManager.get_crew_survivors()
	for survivor in crew_survivors:
		survivor_select.add_item(String(survivor["name"]), int(survivor["id"]))
		if int(survivor["id"]) == int(selected_building_survivor.get(id, -1)):
			survivor_select.select(survivor_select.get_item_count() - 1)
	if not crew_survivors.is_empty() and not selected_building_survivor.has(id):
		selected_building_survivor[id] = int(crew_survivors[0]["id"])
	survivor_select.item_selected.connect(_on_building_survivor_selected.bind(survivor_select, id))
	command_body.add_child(survivor_select)
	var assign := _small_button("ASSIGN")
	assign.custom_minimum_size = Vector2(90, 54)
	assign.pressed.connect(_on_assign_survivor_to_building.bind(id))
	command_body.add_child(assign)

func _build_survivor_commands() -> void:
	for survivor in SurvivorManager.survivors:
		var job_progress := int(ActivityManager.get_progress(int(survivor["id"])) * 100.0)
		var button := _small_button("%s\n%s %d%%" % [survivor["name"], survivor["assigned_task"], job_progress])
		button.custom_minimum_size = Vector2(112, 54)
		button.pressed.connect(_show_task_popup.bind(int(survivor["id"])))
		command_body.add_child(button)

func _build_scavenge_commands() -> void:
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(150, 54)
	var crew_survivors := SurvivorManager.get_crew_survivors()
	if not crew_survivors.is_empty() and not _is_selected_scavenger_crew():
		selected_scavenger_id = int(crew_survivors[0]["id"])
	for survivor in crew_survivors:
		selector.add_item(String(survivor["name"]), int(survivor["id"]))
		if int(survivor["id"]) == selected_scavenger_id:
			selector.select(selector.get_item_count() - 1)
	selector.item_selected.connect(_on_scavenger_selected.bind(selector))
	command_body.add_child(selector)
	for location in ScavengeManager.locations:
		var loot_text := ", ".join(Array(location.get("loot", [])))
		var state := _location_state_text(location)
		var button := _small_button("%s\n%s | %s | %s" % [location["name"], String(location["danger"]).to_upper(), state, loot_text])
		button.custom_minimum_size = Vector2(162, 54)
		button.disabled = not bool(ScavengeManager.can_scavenge(String(location["name"])).get("ok", false))
		button.pressed.connect(_on_scavenge.bind(String(location["name"])))
		command_body.add_child(button)

func _build_crafting_commands() -> void:
	var ammo := _small_button("CRAFT AMMO\n-12 mat +6")
	ammo.custom_minimum_size = Vector2(130, 54)
	ammo.pressed.connect(func(): _craft("materials", 12, "ammo", 6))
	command_body.add_child(ammo)
	var med := _small_button("MED KITS\n-8 mat +3")
	med.custom_minimum_size = Vector2(130, 54)
	med.pressed.connect(func(): _craft("materials", 8, "medicine", 3))
	command_body.add_child(med)
	var building := _selected_building()
	if building.is_empty():
		command_body.add_child(_label("Select a building before installing upgrades.", 13, MUTED))
		return
	for upgrade_id in BuildingManager.UPGRADES.keys():
		var upgrade: Dictionary = BuildingManager.UPGRADES[upgrade_id]
		var cost := _cost_text(Dictionary(upgrade["cost"]))
		var button := _small_button("%s\n%s" % [upgrade["name"], cost])
		button.custom_minimum_size = Vector2(156, 54)
		button.disabled = not _can_install_upgrade(building, String(upgrade_id))
		button.tooltip_text = String(upgrade["description"])
		button.pressed.connect(_on_install_upgrade.bind(int(building["id"]), String(upgrade_id)))
		command_body.add_child(button)

func _build_defence_commands() -> void:
	var preview := NightDefenseManager.get_preview()
	command_body.add_child(_label("Attack %d  Defence %d" % [int(preview["attack_strength"]), int(preview["defence_strength"])], 13, TEXT))
	for tactic_id in NightDefenseManager.DEFENCE_TACTICS.keys():
		var tactic: Dictionary = NightDefenseManager.DEFENCE_TACTICS[tactic_id]
		var button := _small_button("%s\n%s" % [tactic["name"], _cost_text(Dictionary(tactic["cost"]))])
		button.custom_minimum_size = Vector2(150, 54)
		button.disabled = not _can_afford(Dictionary(tactic["cost"]))
		button.tooltip_text = String(tactic["message"])
		button.pressed.connect(_on_prepare_defence.bind(String(tactic_id)))
		command_body.add_child(button)

func _build_radio_commands() -> void:
	var radio := _small_button("CALL RADIO\n-2 power")
	radio.custom_minimum_size = Vector2(130, 54)
	radio.pressed.connect(func():
		ResourceManager.add_resource("power", -2)
		ResourceManager.add_resource("horde_threat", -2)
		GameManager.add_log("Radio scan reduced horde uncertainty.")
		_show_result("Radio scan complete. Horde threat reduced.")
	)
	command_body.add_child(radio)
	var save := _small_button("SAVE")
	save.custom_minimum_size = Vector2(90, 54)
	save.pressed.connect(func(): _show_result("Saved." if GameManager.manual_save() else "Save failed."))
	command_body.add_child(save)

func _on_building_action(id: int, action: String) -> void:
	_show_result(GameManager.building_action(id, action)["message"])

func _on_scavenge(location_name: String) -> void:
	_show_result(GameManager.scavenge(location_name, selected_scavenger_id)["message"])

func _on_scavenger_selected(index: int, selector: OptionButton) -> void:
	selected_scavenger_id = selector.get_item_id(index)

func _on_prepare_defence(tactic_id: String) -> void:
	_show_result(GameManager.prepare_defences(tactic_id)["message"])

func _on_building_use_selected(index: int, selector: OptionButton, building_id: int) -> void:
	selected_building_use[building_id] = selector.get_item_text(index)

func _on_assign_building_use(building_id: int) -> void:
	_show_result(GameManager.assign_building_use(building_id, String(selected_building_use.get(building_id, BuildingManager.USES[0])))["message"])

func _on_building_survivor_selected(index: int, selector: OptionButton, building_id: int) -> void:
	selected_building_survivor[building_id] = selector.get_item_id(index)

func _on_assign_survivor_to_building(building_id: int) -> void:
	var survivors := SurvivorManager.get_crew_survivors()
	if survivors.is_empty():
		_show_result("No crew survivors available.")
		return
	var survivor_id := int(selected_building_survivor.get(building_id, int(survivors[0]["id"])))
	_show_result(GameManager.assign_survivor_to_building(building_id, survivor_id)["message"])

func _craft(cost_key: String, cost: int, gain_key: String, gain: int) -> void:
	if ResourceManager.spend_resource(cost_key, cost):
		ResourceManager.add_resource(gain_key, gain)
		GameManager.add_log("Crafted +%d %s." % [gain, gain_key])
		_show_result("Crafting complete.")
	else:
		_show_result("Not enough %s." % cost_key)
	_refresh()

func _on_install_upgrade(building_id: int, upgrade_id: String) -> void:
	_show_result(GameManager.install_building_upgrade(building_id, upgrade_id)["message"])

func _show_build_popup() -> void:
	var building := _selected_building()
	var box := _show_modal("Build & Manage", Vector2(680, 470))
	if building.is_empty():
		box.add_child(_label("Tap a building on the estate map first.", 15, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		var close_empty := _small_button("CLOSE")
		close_empty.custom_minimum_size = Vector2(0, 46)
		close_empty.pressed.connect(_dismiss_modal)
		box.add_child(close_empty)
		return
	var summary := _label("%s\n%s | %s | condition %d | security %d | infestation %d" % [_building_display_name(building), building["status"], building["current_use"], building["condition"], building["security"], building["infestation"]], 14, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)

	var actions := GridContainer.new()
	actions.columns = 3
	actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 7)
	actions.add_theme_constant_override("v_separation", 7)
	box.add_child(actions)
	for action in ["Scout", "Clear", "Claim", "Repair", "Fortify"]:
		var action_button := _small_button(action)
		action_button.custom_minimum_size = Vector2(150, 54)
		action_button.disabled = not _can_building_action(building, action)
		action_button.pressed.connect(_run_building_action_from_modal.bind(int(building["id"]), action))
		actions.add_child(action_button)

	var workshop := _small_button("CRAFT AMMO\n-12 materials +6 ammo")
	workshop.custom_minimum_size = Vector2(190, 54)
	workshop.pressed.connect(func():
		_dismiss_modal()
		_craft("materials", 12, "ammo", 6)
	)
	actions.add_child(workshop)
	var medkit := _small_button("CRAFT MEDS\n-8 materials +3 medicine")
	medkit.custom_minimum_size = Vector2(190, 54)
	medkit.pressed.connect(func():
		_dismiss_modal()
		_craft("materials", 8, "medicine", 3)
	)
	actions.add_child(medkit)
	for upgrade_id in BuildingManager.UPGRADES.keys():
		var upgrade: Dictionary = BuildingManager.UPGRADES[upgrade_id]
		var upgrade_button := _small_button("%s\n%s" % [upgrade["name"], _cost_text(Dictionary(upgrade["cost"]))])
		upgrade_button.custom_minimum_size = Vector2(190, 54)
		upgrade_button.disabled = not _can_install_upgrade(building, String(upgrade_id))
		upgrade_button.pressed.connect(_run_upgrade_from_modal.bind(int(building["id"]), String(upgrade_id)))
		actions.add_child(upgrade_button)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	box.add_child(footer)
	var tab := _small_button("OPEN BUILDINGS TAB")
	tab.custom_minimum_size = Vector2(0, 46)
	tab.pressed.connect(func():
		_dismiss_modal()
		_switch_tab("Buildings")
	)
	footer.add_child(tab)
	var close := _small_button("CLOSE")
	close.custom_minimum_size = Vector2(130, 46)
	close.pressed.connect(_dismiss_modal)
	footer.add_child(close)

func _show_defence_popup() -> void:
	var preview := NightDefenseManager.get_preview()
	var box := _show_modal("Prepare Defences", Vector2(560, 390))
	var summary := _label("Tonight: attack %d / defence %d\nGuards %d | fortified bonus %d | upgrades %d" % [int(preview["attack_strength"]), int(preview["defence_strength"]), int(preview["guards"]), int(preview["fortified_bonus"]), int(preview.get("upgrade_bonus", 0))], 15, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)
	for tactic_id in NightDefenseManager.DEFENCE_TACTICS.keys():
		var tactic: Dictionary = NightDefenseManager.DEFENCE_TACTICS[tactic_id]
		var tactic_button := _small_button("%s\n%s" % [tactic["name"], _cost_text(Dictionary(tactic["cost"]))])
		tactic_button.custom_minimum_size = Vector2(0, 56)
		tactic_button.disabled = not _can_afford(Dictionary(tactic["cost"]))
		tactic_button.pressed.connect(_run_defence_from_modal.bind(String(tactic_id)))
		box.add_child(tactic_button)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	box.add_child(footer)
	var tab := _small_button("OPEN DEFENCE TAB")
	tab.custom_minimum_size = Vector2(0, 46)
	tab.pressed.connect(func():
		_dismiss_modal()
		_switch_tab("Defence")
	)
	footer.add_child(tab)
	var close := _small_button("CLOSE")
	close.custom_minimum_size = Vector2(130, 46)
	close.pressed.connect(_dismiss_modal)
	footer.add_child(close)

func _show_scavenge_popup() -> void:
	var crew_survivors := SurvivorManager.get_crew_survivors()
	if not crew_survivors.is_empty() and not _is_selected_scavenger_crew():
		selected_scavenger_id = int(crew_survivors[0]["id"])
	var box := _show_modal("Scout Locations", Vector2(660, 470))
	var selected_name := SurvivorManager.get_survivor_name(selected_scavenger_id)
	var help := _label("Selected survivor: %s. Pick a location to search now, or open the full Scavenge tab to change survivor." % selected_name, 14, TEXT)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for location in ScavengeManager.locations:
		var location_name := String(location["name"])
		var loot_text := ", ".join(Array(location.get("loot", [])))
		var button := _small_button("%s\nDanger %s  |  Supplies %s  |  %s" % [location_name, String(location["danger"]).to_upper(), loot_text, _location_state_text(location)])
		button.custom_minimum_size = Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 14)
		button.disabled = not bool(ScavengeManager.can_scavenge(location_name).get("ok", false))
		button.pressed.connect(_run_scavenge_from_modal.bind(location_name))
		list.add_child(button)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var tab := _small_button("OPEN SCAVENGE TAB")
	tab.custom_minimum_size = Vector2(0, 46)
	tab.pressed.connect(func():
		_dismiss_modal()
		_switch_tab("Scavenge")
	)
	actions.add_child(tab)
	var close := _small_button("CLOSE")
	close.custom_minimum_size = Vector2(130, 46)
	close.pressed.connect(_dismiss_modal)
	actions.add_child(close)

func _show_game_menu() -> void:
	var box := _show_modal("Game Menu", Vector2(420, 350))
	var title := _label("Dead Shift", 18, ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)

	var save := _small_button("MANUAL SAVE")
	save.custom_minimum_size = Vector2(0, 50)
	save.pressed.connect(func():
		_dismiss_modal()
		_show_result("Saved." if GameManager.manual_save() else "Save failed.")
	)
	box.add_child(save)

	var settings := _small_button("SETTINGS")
	settings.custom_minimum_size = Vector2(0, 50)
	settings.pressed.connect(func():
		_dismiss_modal()
		get_tree().change_scene_to_file("res://scenes/screens/SettingsScreen.tscn")
	)
	box.add_child(settings)

	var main_menu := _small_button("SAVE AND MAIN MENU")
	main_menu.custom_minimum_size = Vector2(0, 50)
	main_menu.pressed.connect(func():
		GameManager.manual_save()
		_dismiss_modal()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	box.add_child(main_menu)

	var reset := _small_button("RESET SAVE")
	reset.custom_minimum_size = Vector2(0, 50)
	reset.add_theme_color_override("font_color", RED.lightened(0.2))
	reset.pressed.connect(func():
		_dismiss_modal()
		_confirm_reset_save()
	)
	box.add_child(reset)

	var close := _small_button("CLOSE")
	close.custom_minimum_size = Vector2(0, 46)
	close.pressed.connect(_dismiss_modal)
	box.add_child(close)

func _show_modal(title_text: String, panel_size: Vector2) -> VBoxContainer:
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

	var framed := _create_panel(panel_size)
	var panel: PanelContainer = framed["panel"]
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)

	var box: VBoxContainer = framed["box"]
	box.add_child(_label(title_text, 22, ORANGE, HORIZONTAL_ALIGNMENT_CENTER))
	return box

func _dismiss_modal() -> void:
	if modal_overlay != null and is_instance_valid(modal_overlay):
		modal_overlay.queue_free()
	modal_overlay = null

func _run_building_action_from_modal(building_id: int, action: String) -> void:
	_dismiss_modal()
	_show_result(String(GameManager.building_action(building_id, action)["message"]))

func _run_upgrade_from_modal(building_id: int, upgrade_id: String) -> void:
	_dismiss_modal()
	_show_result(String(GameManager.install_building_upgrade(building_id, upgrade_id)["message"]))

func _run_defence_from_modal(tactic_id: String) -> void:
	_dismiss_modal()
	_show_result(String(GameManager.prepare_defences(tactic_id)["message"]))

func _run_scavenge_from_modal(location_name: String) -> void:
	_dismiss_modal()
	var result: Dictionary = GameManager.scavenge(location_name, selected_scavenger_id)
	_show_result(String(result["message"]))

func _is_selected_scavenger_crew() -> bool:
	for survivor in SurvivorManager.get_crew_survivors():
		if int(survivor["id"]) == selected_scavenger_id:
			return true
	return false

func _confirm_reset_save() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reset Save"
	dialog.dialog_text = "Delete the local save and start again?"
	add_child(dialog)
	dialog.confirmed.connect(func():
		GameManager.reset_save_and_game()
		dialog.queue_free()
		_show_result("Save reset. New game started.")
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2(420, 220))

func _show_task_popup(survivor_id: int) -> void:
	var dialog := AcceptDialog.new()
	var survivor_name := SurvivorManager.get_survivor_name(survivor_id)
	var is_crew := SurvivorManager.is_crew(survivor_id)
	dialog.title = "Manage Survivor"
	dialog.dialog_text = "%s is %s.\nCrew are directly controlled. NPC residents choose useful colony jobs automatically." % [survivor_name, "in your crew" if is_crew else "an NPC resident"]
	add_child(dialog)
	if is_crew:
		for task in SurvivorManager.TASKS:
			dialog.add_button(task, false, task)
		dialog.add_button("Set As NPC", false, "__npc")
	else:
		dialog.add_button("Add To Crew", false, "__crew")
		dialog.add_button("Keep NPC", false, "__close")
	dialog.custom_action.connect(func(action: StringName):
		var action_text := String(action)
		match action_text:
			"__crew":
				_show_result(String(GameManager.set_survivor_control_mode(survivor_id, "Crew")["message"]))
			"__npc":
				_show_result(String(GameManager.set_survivor_control_mode(survivor_id, "NPC")["message"]))
			"__close":
				pass
			_:
				GameManager.assign_survivor_task(survivor_id, action_text)
		dialog.queue_free()
	)
	dialog.popup_centered(Vector2(460, 320))

func _show_recruit_popup(recruit: Dictionary) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Survivor Found"
	dialog.dialog_text = "%s, %s\nHealth %d  Infection %d%%\nInvited survivors join as NPC residents. Add them to Crew if you want direct control." % [recruit["name"], recruit["role"], recruit["health"], recruit["infection_risk"]]
	add_child(dialog)
	dialog.add_button("Invite", false, "Invite")
	dialog.add_button("Quarantine", false, "Quarantine")
	dialog.add_button("Reject", false, "Reject")
	dialog.custom_action.connect(func(action: StringName):
		GameManager.handle_recruit(String(action))
		dialog.queue_free()
	)
	dialog.confirmed.connect(func(): GameManager.handle_recruit("Invite"))
	dialog.popup_centered()

func _show_result(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Dead Shift"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	var lines := message.count("\n") + 1
	dialog.popup_centered(Vector2(520, 360) if lines > 3 else Vector2(420, 220))
	_refresh()

func _show_game_over(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Colony Lost"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2(460, 240))
	_refresh()

func _selected_building() -> Dictionary:
	for building in BuildingManager.buildings:
		if int(building["id"]) == selected_building_id:
			return building
	return {}

func _building_button_text(building: Dictionary) -> String:
	if _is_expansion_marker(building):
		if String(building.get("status", "")) == "Unknown":
			return "?"
		return "!\n%s" % String(building.get("status", ""))
	var assigned := Array(building.get("assigned_survivors", []))
	return "%s\n%s  %d/%d" % [_building_display_name(building), building["status"], assigned.size(), int(building.get("capacity", 0))]

func _building_display_name(building: Dictionary) -> String:
	if GameManager.colony_tier_index == 0 and String(building.get("name", "")) == "Main Warehouse":
		return "Billy's Workshop"
	return String(building.get("name", "Unknown"))

func _can_building_action(building: Dictionary, action: String) -> bool:
	match action:
		"Scout":
			return String(building.get("status", "")) == "Unknown"
		"Clear":
			return ["Scouted", "Infested"].has(String(building.get("status", ""))) and ResourceManager.get_value("ammo") >= 2
		"Claim":
			return String(building.get("status", "")) == "Cleared"
		"Repair":
			return ["Claimed", "Operational", "Fortified"].has(String(building.get("status", ""))) and ResourceManager.get_value("materials") >= 10 and int(building.get("condition", 0)) < 100
		"Fortify":
			return ["Claimed", "Operational"].has(String(building.get("status", ""))) and ResourceManager.get_value("materials") >= 15
	return false

func _can_install_upgrade(building: Dictionary, upgrade_id: String) -> bool:
	if not BuildingManager.UPGRADES.has(upgrade_id):
		return false
	if not ["Claimed", "Operational", "Fortified"].has(String(building.get("status", ""))):
		return false
	if Array(building.get("upgrades", [])).has(upgrade_id):
		return false
	var cost: Dictionary = BuildingManager.UPGRADES[upgrade_id]["cost"]
	return _can_afford(cost)

func _can_afford(cost: Dictionary) -> bool:
	for key in cost.keys():
		if ResourceManager.get_value(String(key)) < int(cost[key]):
			return false
	return true

func _cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for key in cost.keys():
		parts.append("%s %s" % [cost[key], String(key).substr(0, 3)])
	return "-%s" % ", ".join(parts)

func _location_state_text(location: Dictionary) -> String:
	var remaining := int(location.get("remaining", 100))
	var cooldown := int(location.get("cooldown", 0))
	if cooldown > 0:
		return "HOT %dd" % cooldown
	if remaining <= 0:
		return "EMPTY"
	return "%d%%" % remaining

func _building_color(building: Dictionary) -> Color:
	match String(building.get("status", "")):
		"Unknown":
			return Color("#3b4148")
		"Scouted":
			return BLUE
		"Infested":
			return RED
		"Cleared":
			return YELLOW
		"Claimed", "Operational":
			return GREEN
		"Fortified":
			return ORANGE
		"Lost":
			return Color("#1a1a1a")
	return PANEL_LIGHT

func _role_color(role: String) -> Color:
	match role:
		"Medic":
			return GREEN
		"Guard":
			return RED
		"Cook":
			return YELLOW
		"Builder", "Sign Fitter":
			return ORANGE
	return BLUE

func _status_color(survivor: Dictionary) -> Color:
	match String(survivor.get("status", "Healthy")):
		"Dead":
			return Color("#252525")
		"Infected":
			return RED
		"At Risk":
			return YELLOW
		"Injured":
			return ORANGE
	return _role_color(String(survivor.get("role", "")))

func _survivor_portrait(survivor: Dictionary, min_size: Vector2) -> Control:
	var portrait := Control.new()
	portrait.custom_minimum_size = min_size
	portrait.draw.connect(func(): _draw_survivor_icon(portrait, survivor, false))
	return portrait

func _survivor_map_token(survivor: Dictionary) -> Button:
	var token := Button.new()
	token.text = ""
	token.clip_text = true
	token.add_theme_font_size_override("font_size", 7)
	token.add_theme_color_override("font_color", TEXT)
	token.draw.connect(func(): _draw_survivor_icon(token, survivor, true))
	return token

func _draw_survivor_icon(node: Control, survivor: Dictionary, compact: bool) -> void:
	var size := node.size
	var accent := _status_color(survivor)
	var role_color := _role_color(String(survivor.get("role", "")))
	var skin := _skin_color(int(survivor.get("id", 1)))
	var coat := accent.darkened(0.25)
	var outline := Color("#050607")
	var mode := String(survivor.get("control_mode", "NPC"))
	var task := String(survivor.get("assigned_task", "Rest"))
	var step := sin(ambient_time * (5.0 if task in ["Scavenge", "Scout"] else 2.8) + float(survivor.get("id", 1)))
	node.draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.024, 0.027, 0.66), true)
	node.draw_rect(Rect2(Vector2.ZERO, size), (BLUE if mode == "Crew" else MUTED).darkened(0.2), false, 2 if mode == "Crew" else 1)
	var center := size * Vector2(0.5, 0.4 if compact else 0.34) + Vector2(0, step * (1.0 if compact else 1.5))
	var head_radius := minf(size.x, size.y) * (0.18 if compact else 0.2)
	var torso_start := center + Vector2(0, head_radius * 1.1)
	var leg_base := torso_start + Vector2(0, size.y * (0.24 if compact else 0.3))
	var limb_width := maxf(1.2, head_radius * 0.35)
	node.draw_line(torso_start + Vector2(-head_radius * 0.7, head_radius), leg_base + Vector2(-head_radius * 0.9, head_radius * (1.7 + step * 0.3)), coat, limb_width)
	node.draw_line(torso_start + Vector2(head_radius * 0.7, head_radius), leg_base + Vector2(head_radius * 0.9, head_radius * (1.7 - step * 0.3)), coat, limb_width)
	var arm_swing := Vector2(step * head_radius * 0.6, head_radius * 1.0)
	node.draw_line(torso_start + Vector2(-head_radius * 0.9, 0), torso_start + Vector2(-head_radius * 1.7, head_radius) - arm_swing, role_color, limb_width)
	node.draw_line(torso_start + Vector2(head_radius * 0.9, 0), torso_start + Vector2(head_radius * 1.7, head_radius) + arm_swing, role_color, limb_width)
	node.draw_circle(center, head_radius + 1.0, outline)
	node.draw_circle(center, head_radius, skin)
	if task == "Guard":
		node.draw_rect(Rect2(center + Vector2(head_radius * 0.45, -head_radius * 0.2), Vector2(head_radius * 0.85, head_radius * 0.24)), RED, true)
	var body_top := center + Vector2(-head_radius * 1.2, head_radius * 0.95)
	var body_size := Vector2(head_radius * 2.4, size.y * (0.34 if compact else 0.42))
	node.draw_rect(Rect2(body_top, body_size), coat, true)
	node.draw_rect(Rect2(body_top, body_size), outline, false, 1)
	_draw_role_mark(node, survivor, center + Vector2(0, body_size.y * 0.95), accent, compact)

func _skin_color(id: int) -> Color:
	var tones := [Color("#c79a74"), Color("#8f6045"), Color("#e0b084"), Color("#a87555"), Color("#d0a17a")]
	return tones[id % tones.size()]

func _draw_role_mark(node: Control, survivor: Dictionary, pos: Vector2, color: Color, compact: bool) -> void:
	var role := String(survivor.get("role", ""))
	var scale := 0.7 if compact else 1.0
	match role:
		"Medic":
			node.draw_line(pos + Vector2(-5, 0) * scale, pos + Vector2(5, 0) * scale, GREEN.lightened(0.2), 2)
			node.draw_line(pos + Vector2(0, -5) * scale, pos + Vector2(0, 5) * scale, GREEN.lightened(0.2), 2)
		"Guard":
			node.draw_arc(pos, 6.0 * scale, PI, TAU, 8, RED.lightened(0.15), 2)
			node.draw_line(pos, pos + Vector2(0, 6) * scale, RED.lightened(0.15), 2)
		"Cook":
			node.draw_circle(pos, 4.0 * scale, YELLOW)
			node.draw_line(pos + Vector2(4, -4) * scale, pos + Vector2(7, -8) * scale, YELLOW, 2)
		"Builder", "Sign Fitter":
			node.draw_line(pos + Vector2(-6, 5) * scale, pos + Vector2(5, -6) * scale, ORANGE.lightened(0.1), 3)
			node.draw_circle(pos + Vector2(6, -7) * scale, 2.0 * scale, ORANGE.lightened(0.1))
		_:
			node.draw_circle(pos, 4.0 * scale, color.lightened(0.15))

func _threat_label() -> String:
	var threat := ResourceManager.get_value("horde_threat")
	if threat >= 50:
		return "HIGH"
	if threat >= 25:
		return "MED"
	return "LOW"

func _add_panel(parent: Container, min_size: Vector2) -> VBoxContainer:
	var framed := _create_panel(min_size)
	parent.add_child(framed["panel"])
	var box: VBoxContainer = framed["box"]
	return box

func _create_panel(min_size: Vector2) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if min_size.x == 0 else Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if min_size.y == 0 else Control.SIZE_SHRINK_CENTER
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

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	return {"panel": panel, "box": box}

func _map_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

func _stat_chip(title: String, value: String, color: Color) -> PanelContainer:
	var framed := _create_panel(Vector2(0, 0))
	var chip: VBoxContainer = framed["box"]
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_child(_label(title, 9, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	chip.add_child(_label(value, 16, color, HORIZONTAL_ALIGNMENT_CENTER))
	var panel: PanelContainer = framed["panel"]
	return panel

func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.clip_text = true
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	return button

func _label(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, node_name := "") -> Label:
	var label := Label.new()
	if node_name != "":
		label.name = node_name
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
