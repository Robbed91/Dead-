extends Control

@export var initial_tab := "Buildings"

const TABS := ["Buildings", "Survivors", "Scavenge", "Crafting", "Map", "Radio"]
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
const ESTATE_BACKGROUND := preload("res://assets/placeholders/estate_background.png")

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
var command_body: VBoxContainer
var selected_building_label: Label
var night_preview_label: Label
var end_day_button: Button
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
	root.offset_bottom = -5
	root.add_theme_constant_override("separation", 5)
	add_child(root)

	_build_top_bar(root)
	_build_middle(root)
	_build_command_bar(root)

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
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	map.add_child(grid)
	for i in range(12):
		var tile := ColorRect.new()
		tile.custom_minimum_size = Vector2(42, 22)
		tile.color = GREEN.darkened(0.25) if i in [2, 4, 7] else (RED.darkened(0.1) if i in [5, 10] else PANEL_LIGHT)
		grid.add_child(tile)
	var scout := _small_button("SCOUT LOCATION")
	scout.pressed.connect(func(): _switch_tab("Scavenge"))
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
	prep.pressed.connect(func(): _show_result(GameManager.prepare_defences()["message"]))
	defence.add_child(prep)

func _build_command_bar(root: VBoxContainer) -> void:
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size = Vector2(0, 128)
	bottom.add_theme_constant_override("separation", 5)
	root.add_child(bottom)

	var tabs := _add_panel(bottom, Vector2(370, 0))
	tabs.add_child(_label("BUILD & MANAGE", 13, TEXT))
	var tab_grid := GridContainer.new()
	tab_grid.columns = 3
	tab_grid.add_theme_constant_override("h_separation", 4)
	tab_grid.add_theme_constant_override("v_separation", 4)
	tabs.add_child(tab_grid)
	for tab in TABS:
		var button := _small_button(tab)
		button.custom_minimum_size = Vector2(112, 40)
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

	var end := _add_panel(bottom, Vector2(220, 0))
	end.add_child(_label("NEXT PHASE: NIGHT", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	end_day_button = _small_button("END DAY")
	end_day_button.custom_minimum_size = Vector2(0, 58)
	end_day_button.add_theme_font_size_override("font_size", 24)
	end_day_button.add_theme_color_override("font_color", RED.lightened(0.25))
	end_day_button.pressed.connect(func(): _show_result(GameManager.end_day()["message"]))
	end.add_child(end_day_button)

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
		button.pressed.connect(_select_building.bind(int(building["id"])))
		map.add_child(button)
		building_buttons[int(building["id"])] = button
	for survivor in SurvivorManager.survivors:
		var token := Button.new()
		token.text = String(survivor["name"]).substr(0, 1)
		token.custom_minimum_size = Vector2(22, 22)
		token.size = Vector2(22, 22)
		token.add_theme_font_size_override("font_size", 11)
		token.tooltip_text = "%s - %s" % [survivor["name"], survivor["assigned_task"]]
		token.pressed.connect(_show_task_popup.bind(int(survivor["id"])))
		map.add_child(token)
		survivor_tokens[int(survivor["id"])] = token
	return panel

func _draw_estate_map(map: Control) -> void:
	var size := map.size
	map.draw_rect(Rect2(Vector2.ZERO, size), Color("#101519"), true)
	map.draw_texture_rect(ESTATE_BACKGROUND, Rect2(Vector2.ZERO, size), false, Color(0.92, 0.92, 0.92, 0.82))
	map.draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.18), true)
	map.draw_rect(Rect2(Vector2(0, size.y * 0.04), Vector2(size.x, 12)), Color(0.145, 0.192, 0.227, 0.65), true)
	map.draw_rect(Rect2(Vector2(0, size.y * 0.9), Vector2(size.x, 14)), Color(0.188, 0.227, 0.251, 0.65), true)
	for i in range(9):
		var y := size.y * (0.12 + float(i) * 0.095)
		map.draw_line(Vector2(0, y), Vector2(size.x, y + sin(i) * 18), Color(0.125, 0.165, 0.188, 0.28), 2)
	for i in range(7):
		var x := size.x * (0.08 + float(i) * 0.14)
		map.draw_line(Vector2(x, 0), Vector2(x + cos(i) * 20, size.y), Color(0.11, 0.145, 0.169, 0.24), 2)
	map.draw_circle(size * Vector2(0.48, 0.5), 24, Color(0.843, 0.467, 0.145, 0.65))
	map.draw_circle(size * Vector2(0.48, 0.5), 15, Color(0.204, 0.129, 0.047, 0.75))
	for i in range(18):
		var pos := Vector2(fmod(float(i * 73), size.x), fmod(float(i * 47 + 31), size.y))
		map.draw_circle(pos, 2.0, Color(0.898, 0.608, 0.251, 0.45))
	var threat_count := clamp(int(ResourceManager.get_value("horde_threat") / 6), 2, 13)
	for i in range(threat_count):
		var wave := sin(ambient_time * 1.4 + i)
		var pos := Vector2(size.x * (0.05 + float(i) / max(1.0, float(threat_count)) * 0.9), size.y * 0.94 + wave * 4.0)
		map.draw_circle(pos, 5.0, RED.darkened(0.1))
		map.draw_line(pos + Vector2(-3, 5), pos + Vector2(3, 5), RED.darkened(0.25), 2)
	for building in BuildingManager.buildings:
		var rect := _building_rect(map, building)
		var color := _building_color(building).darkened(0.15)
		map.draw_rect(rect.grow(3), Color(0.02, 0.024, 0.027, 0.32), true)
		map.draw_rect(rect, Color(color.r, color.g, color.b, 0.28), true)
		map.draw_rect(rect, Color(0.82, 0.88, 0.91, 0.78), false, 2)
		_draw_building_detail(map, building, rect)

func _draw_building_detail(map: Control, building: Dictionary, rect: Rect2) -> void:
	var roof := Rect2(rect.position + Vector2(0, 3), Vector2(rect.size.x, max(6.0, rect.size.y * 0.16)))
	map.draw_rect(roof, Color("#050607").lightened(0.08), true)
	var condition := clamp(float(building.get("condition", 0)) / 100.0, 0.0, 1.0)
	var security := clamp(float(building.get("security", 0)) / 100.0, 0.0, 1.0)
	var infestation := clamp(float(building.get("infestation", 0)) / 100.0, 0.0, 1.0)
	var bar_w := max(18.0, rect.size.x - 10.0)
	_draw_map_bar(map, rect.position + Vector2(5, rect.size.y - 18), bar_w, condition, GREEN)
	_draw_map_bar(map, rect.position + Vector2(5, rect.size.y - 12), bar_w, security, BLUE)
	if infestation > 0.0:
		_draw_map_bar(map, rect.position + Vector2(5, rect.size.y - 6), bar_w, infestation, RED)
	var pulse := (sin(ambient_time * 3.0 + rect.position.x * 0.03) + 1.0) * 0.5
	if ["Claimed", "Operational", "Fortified"].has(String(building.get("status", ""))):
		map.draw_circle(rect.position + rect.size * Vector2(0.82, 0.28), 3.0 + pulse * 2.0, ORANGE)

func _draw_map_bar(map: Control, pos: Vector2, width: float, value: float, color: Color) -> void:
	map.draw_rect(Rect2(pos, Vector2(width, 3)), Color("#060809"), true)
	map.draw_rect(Rect2(pos, Vector2(width * value, 3)), color, true)

func _position_building_buttons(map: Control) -> void:
	for building in BuildingManager.buildings:
		var id := int(building["id"])
		if not building_buttons.has(id):
			continue
		var button: Button = building_buttons[id]
		var rect := _building_rect(map, building).grow(-4)
		button.position = rect.position
		button.size = rect.size

func _building_rect(map: Control, building: Dictionary) -> Rect2:
	var layout: Rect2 = BUILDING_LAYOUT.get(String(building["name"]), Rect2(0.4, 0.4, 0.16, 0.16))
	return Rect2(Vector2(layout.position.x * map.size.x, layout.position.y * map.size.y), Vector2(layout.size.x * map.size.x, layout.size.y * map.size.y))

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
	var day_label := find_child("day_value", true, false)
	if day_label != null:
		day_label.text = str(r["day_number"])
	if phase_label != null:
		phase_label.text = GameManager.phase.to_upper()

func _refresh_alerts() -> void:
	objective_body.text = GameManager.current_objective
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
		var portrait := ColorRect.new()
		portrait.custom_minimum_size = Vector2(34, 34)
		portrait.color = _status_color(survivor)
		row.add_child(portrait)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var job := ActivityManager.get_job(int(survivor["id"]))
		var job_suffix := ""
		if String(job.get("location", "")) != "":
			job_suffix = " @ %s" % String(job["location"])
		details.add_child(_label("%s  HP %s%%  INF %s%%" % [survivor["name"], survivor["health"], survivor["infection_risk"]], 12, TEXT))
		details.add_child(_label("%s - %s - %s%s" % [survivor["role"], survivor["status"], survivor["assigned_task"], job_suffix], 9, MUTED))
		var progress := ProgressBar.new()
		progress.custom_minimum_size = Vector2(0, 8)
		progress.max_value = 1.0
		progress.value = ActivityManager.get_progress(int(survivor["id"]))
		progress.show_percentage = false
		details.add_child(progress)
		var task := _small_button("Assign")
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
		var token := ColorRect.new()
		token.color = RED if not bool(result.get("success", false)) else ORANGE
		token.custom_minimum_size = Vector2(10, 10)
		token.size = Vector2(10, 10)
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

func _position_survivor_tokens(map: Control) -> void:
	for survivor in SurvivorManager.survivors:
		var id := int(survivor["id"])
		if not survivor_tokens.has(id):
			var token := Button.new()
			token.text = String(survivor["name"]).substr(0, 1)
			token.custom_minimum_size = Vector2(22, 22)
			token.size = Vector2(22, 22)
			token.add_theme_font_size_override("font_size", 11)
			token.pressed.connect(_show_task_popup.bind(id))
			map.add_child(token)
			survivor_tokens[id] = token
		var token: Button = survivor_tokens[id]
		token.tooltip_text = "%s - %s" % [survivor["name"], survivor["assigned_task"]]
		token.modulate = _status_color(survivor)
		var destination := _survivor_destination(map, survivor, id)
		var progress := int(ActivityManager.get_progress(id) * 100.0)
		token.text = "%s\n%d" % [String(survivor["name"]).substr(0, 1), progress]
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
	selected_building_label.text = "%s\n%s | %s\nCond %d  Sec %d  Inf %d\nUpgrades: %s" % [building["name"], building["status"], building["current_use"], building["condition"], building["security"], building["infestation"], upgrade_text]

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
		"Map":
			_build_map_commands()
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
	for survivor in SurvivorManager.get_available_scavengers():
		survivor_select.add_item(String(survivor["name"]), int(survivor["id"]))
		if int(survivor["id"]) == int(selected_building_survivor.get(id, -1)):
			survivor_select.select(survivor_select.get_item_count() - 1)
	if not SurvivorManager.get_available_scavengers().is_empty() and not selected_building_survivor.has(id):
		selected_building_survivor[id] = int(SurvivorManager.get_available_scavengers()[0]["id"])
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
	for survivor in SurvivorManager.get_available_scavengers():
		selector.add_item(String(survivor["name"]), int(survivor["id"]))
		if int(survivor["id"]) == selected_scavenger_id:
			selector.select(selector.get_item_count() - 1)
	selector.item_selected.connect(_on_scavenger_selected.bind(selector))
	command_body.add_child(selector)
	for location in ScavengeManager.locations:
		var loot_text := ", ".join(Array(location.get("loot", [])))
		var button := _small_button("%s\n%s | %s" % [location["name"], String(location["danger"]).to_upper(), loot_text])
		button.custom_minimum_size = Vector2(162, 54)
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

func _build_map_commands() -> void:
	for location in ScavengeManager.locations:
		var danger := String(location["danger"]).to_upper()
		var button := _small_button("%s\n%s" % [location["name"], danger])
		button.custom_minimum_size = Vector2(130, 54)
		button.pressed.connect(_switch_tab.bind("Scavenge"))
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

func _on_building_use_selected(index: int, selector: OptionButton, building_id: int) -> void:
	selected_building_use[building_id] = selector.get_item_text(index)

func _on_assign_building_use(building_id: int) -> void:
	_show_result(GameManager.assign_building_use(building_id, String(selected_building_use.get(building_id, BuildingManager.USES[0])))["message"])

func _on_building_survivor_selected(index: int, selector: OptionButton, building_id: int) -> void:
	selected_building_survivor[building_id] = selector.get_item_id(index)

func _on_assign_survivor_to_building(building_id: int) -> void:
	var survivors := SurvivorManager.get_available_scavengers()
	if survivors.is_empty():
		_show_result("No survivors available.")
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

func _show_task_popup(survivor_id: int) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Assign Survivor"
	dialog.dialog_text = "Choose a task for %s." % SurvivorManager.get_survivor_name(survivor_id)
	add_child(dialog)
	for task in SurvivorManager.TASKS:
		dialog.add_button(task, false, task)
	dialog.custom_action.connect(func(action: StringName):
		GameManager.assign_survivor_task(survivor_id, String(action))
		dialog.queue_free()
	)
	dialog.popup_centered(Vector2(380, 260))

func _show_recruit_popup(recruit: Dictionary) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Survivor Found"
	dialog.dialog_text = "%s, %s\nHealth %d  Infection %d%%" % [recruit["name"], recruit["role"], recruit["health"], recruit["infection_risk"]]
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
	dialog.popup_centered(Vector2(420, 220))
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
	var assigned := Array(building.get("assigned_survivors", []))
	return "%s\n%s  %d/%d" % [building["name"], building["status"], assigned.size(), int(building.get("capacity", 0))]

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
	for key in cost.keys():
		if ResourceManager.get_value(String(key)) < int(cost[key]):
			return false
	return true

func _cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for key in cost.keys():
		parts.append("%s %s" % [cost[key], String(key).substr(0, 3)])
	return "-%s" % ", ".join(parts)

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
