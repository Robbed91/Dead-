extends Control

@export var initial_tab := "Colony"

const TAB_NAMES := ["Colony", "Buildings", "Survivors", "Scavenge", "Crafting", "Defence"]
const THEME_BG := Color("#111317")
const PANEL := Color("#20252b")
const PANEL_LIGHT := Color("#2d343b")
const ORANGE := Color("#f28c28")
const RED := Color("#c23b33")
const GREEN := Color("#70b86b")
const TEXT := Color("#e8e0d2")

var ui_scale := 1.0
var resource_bar: Label
var status_bar: Label
var objective_label: Label
var log_box: VBoxContainer
var content: VBoxContainer
var tab_buttons: Dictionary = {}
var active_tab := "Colony"
var selected_scavenger_id := 1
var selected_building_use: Dictionary = {}
var selected_building_survivor: Dictionary = {}

func _ready() -> void:
	active_tab = initial_tab if TAB_NAMES.has(initial_tab) else "Colony"
	_calculate_mobile_scale()
	_build_theme()
	_build_layout()
	_connect_signals()
	_refresh()

func _calculate_mobile_scale() -> void:
	var width := get_viewport_rect().size.x
	if width <= 0:
		width = 390
	ui_scale = clamp(width / 430.0, 0.78, 1.0)

func _scaled(value: float) -> int:
	return int(round(value * ui_scale))

func _build_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = _scaled(14)
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = PANEL_LIGHT
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	button_style.border_width_left = 1
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.border_color = Color("#4d5863")
	theme.set_stylebox("normal", "Button", button_style)
	theme.set_stylebox("hover", "Button", button_style)
	theme.set_stylebox("pressed", "Button", button_style)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_color", "Label", TEXT)
	set_theme(theme)

func _build_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = THEME_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", _scaled(4))
	root.offset_left = _scaled(6)
	root.offset_top = _scaled(4)
	root.offset_right = -_scaled(6)
	root.offset_bottom = -_scaled(4)
	add_child(root)

	var title := Label.new()
	title.text = "DEAD SHIFT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _scaled(18))
	title.add_theme_color_override("font_color", ORANGE)
	root.add_child(title)

	resource_bar = Label.new()
	resource_bar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_bar.add_theme_font_size_override("font_size", _scaled(12))
	root.add_child(resource_bar)

	status_bar = Label.new()
	status_bar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar.add_theme_font_size_override("font_size", _scaled(12))
	root.add_child(status_bar)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_label.add_theme_font_size_override("font_size", _scaled(12))
	root.add_child(objective_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", _scaled(6))
	scroll.add_child(content)

	var log_title := Label.new()
	log_title.text = "Event Log"
	log_title.add_theme_font_size_override("font_size", _scaled(12))
	log_title.add_theme_color_override("font_color", ORANGE)
	root.add_child(log_title)

	var log_scroll := ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(0, _scaled(62))
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(log_scroll)

	log_box = VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(log_box)

	var nav := GridContainer.new()
	nav.columns = 3
	nav.add_theme_constant_override("h_separation", _scaled(4))
	nav.add_theme_constant_override("v_separation", _scaled(4))
	root.add_child(nav)
	for tab in TAB_NAMES:
		var button := Button.new()
		button.text = "Scav" if tab == "Scavenge" else tab
		button.custom_minimum_size = Vector2(0, _scaled(36))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", _scaled(12))
		button.pressed.connect(_switch_tab.bind(tab))
		nav.add_child(button)
		tab_buttons[tab] = button

func _connect_signals() -> void:
	GameManager.state_changed.connect(_refresh)
	GameManager.log_changed.connect(_refresh_log)
	ResourceManager.resources_changed.connect(_refresh)
	SurvivorManager.survivors_changed.connect(_refresh)
	BuildingManager.buildings_changed.connect(_refresh)
	GameManager.recruit_found.connect(_show_recruit_popup)

func _switch_tab(tab: String) -> void:
	active_tab = tab
	_refresh()

func _refresh() -> void:
	if resource_bar == null:
		return
	var r := ResourceManager.resources
	resource_bar.text = "Food %d  Water %d  Mat %d  Med %d\nAmmo %d  Fuel %d  Power %d  Tools %d" % [r["food"], r["water"], r["materials"], r["medicine"], r["ammo"], r["fuel"], r["power"], r["tools"]]
	status_bar.text = "Day %d  Pop %d/%d  Mor %d  Sec %d  Noise %d  Inf %d%%" % [r["day_number"], SurvivorManager.get_available_scavengers().size(), r["beds"], r["morale"], r["security"], r["noise"], r["infection_risk"]]
	objective_label.text = GameManager.current_objective
	for child in content.get_children():
		child.queue_free()
	for tab in TAB_NAMES:
		tab_buttons[tab].modulate = ORANGE if tab == active_tab else Color.WHITE
	match active_tab:
		"Colony":
			_build_colony()
		"Buildings":
			_build_buildings()
		"Survivors":
			_build_survivors()
		"Scavenge":
			_build_scavenge()
		"Crafting":
			_build_crafting()
		"Defence":
			_build_defence()
	_refresh_log()

func _refresh_log() -> void:
	if log_box == null:
		return
	for child in log_box.get_children():
		child.queue_free()
	for entry in GameManager.event_log.slice(0, 8):
		var label := Label.new()
		label.text = entry
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", _scaled(10))
		log_box.add_child(label)

func _build_colony() -> void:
	_add_section("Warehouse Status", "Survivors hold one warehouse unit in a British industrial estate. Keep food, water, morale, and security stable.")
	var summary := _card()
	summary.add_child(_heading("Daily Work"))
	summary.add_child(_body(_task_summary()))
	var end_day := Button.new()
	end_day.text = "Resolve Night / End Day"
	end_day.custom_minimum_size = Vector2(0, _scaled(44))
	end_day.add_theme_font_size_override("font_size", _scaled(13))
	end_day.pressed.connect(func(): _show_result(GameManager.end_day()["message"]))
	content.add_child(end_day)
	var save := Button.new()
	save.text = "Manual Save"
	save.custom_minimum_size = Vector2(0, _scaled(42))
	save.add_theme_font_size_override("font_size", _scaled(13))
	save.pressed.connect(func(): _show_result("Saved." if GameManager.manual_save() else "Save failed."))
	content.add_child(save)

func _build_buildings() -> void:
	for building in BuildingManager.buildings:
		var card := _card()
		card.add_child(_heading("%s [%s]" % [building["name"], building["type"]]))
		card.add_child(_body("Status: %s\nCondition: %d  Security: %d  Infestation: %d\nUse: %s  Capacity: %d\nAssigned: %s" % [building["status"], building["condition"], building["security"], building["infestation"], building["current_use"], building["capacity"], _assigned_names(building.get("assigned_survivors", []))]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		for action in ["Scout", "Clear", "Claim", "Repair", "Fortify"]:
			var button := Button.new()
			button.text = action
			button.custom_minimum_size = Vector2(0, _scaled(38))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", _scaled(11))
			button.pressed.connect(_on_building_action.bind(int(building["id"]), action))
			row.add_child(button)
		card.add_child(row)
		var controls := GridContainer.new()
		controls.columns = 2
		controls.add_theme_constant_override("h_separation", 6)
		controls.add_theme_constant_override("v_separation", 6)
		var use_select := OptionButton.new()
		use_select.custom_minimum_size = Vector2(0, _scaled(38))
		use_select.add_theme_font_size_override("font_size", _scaled(11))
		for use_name in BuildingManager.USES:
			use_select.add_item(use_name)
			if String(building.get("current_use", "")) == use_name:
				use_select.select(use_select.get_item_count() - 1)
		var building_id := int(building["id"])
		if not selected_building_use.has(building_id):
			selected_building_use[building_id] = String(building.get("current_use", BuildingManager.USES[0])) if BuildingManager.USES.has(String(building.get("current_use", ""))) else BuildingManager.USES[0]
		use_select.item_selected.connect(_on_building_use_selected.bind(use_select, building_id))
		controls.add_child(use_select)
		var use_button := Button.new()
		use_button.text = "Set Use"
		use_button.custom_minimum_size = Vector2(0, _scaled(38))
		use_button.add_theme_font_size_override("font_size", _scaled(11))
		use_button.pressed.connect(_on_assign_building_use.bind(building_id))
		controls.add_child(use_button)
		var survivor_select := _survivor_selector(building_id)
		survivor_select.item_selected.connect(_on_building_survivor_selected.bind(survivor_select, building_id))
		controls.add_child(survivor_select)
		var survivor_button := Button.new()
		survivor_button.text = "Assign"
		survivor_button.custom_minimum_size = Vector2(0, _scaled(38))
		survivor_button.add_theme_font_size_override("font_size", _scaled(11))
		survivor_button.pressed.connect(_on_assign_survivor_to_building.bind(building_id))
		controls.add_child(survivor_button)
		card.add_child(controls)

func _build_survivors() -> void:
	for survivor in SurvivorManager.survivors:
		var card := _card()
		card.add_child(_heading("%s - %s" % [survivor["name"], survivor["role"]]))
		card.add_child(_body("Health: %d  Morale: %d  Loyalty: %d\nInfection: %d%%  Task: %s\nTraits: %s" % [survivor["health"], survivor["morale"], survivor["loyalty"], survivor["infection_risk"], survivor["assigned_task"], ", ".join(survivor["traits"])]))
		var task_grid := GridContainer.new()
		task_grid.columns = 3
		for task in SurvivorManager.TASKS:
			var button := Button.new()
			button.text = task
			button.custom_minimum_size = Vector2(0, _scaled(38))
			button.add_theme_font_size_override("font_size", _scaled(11))
			button.pressed.connect(GameManager.assign_survivor_task.bind(int(survivor["id"]), task))
			task_grid.add_child(button)
		card.add_child(task_grid)

func _build_scavenge() -> void:
	var survivors := SurvivorManager.get_available_scavengers()
	if survivors.is_empty():
		_add_section("No Scavengers", "No living survivors can scavenge.")
		return
	if not _survivor_id_exists(selected_scavenger_id):
		selected_scavenger_id = int(survivors[0]["id"])
	var selector_card := _card()
	selector_card.add_child(_heading("Scavenging Team"))
	selector_card.add_child(_body("Choose who goes outside the estate. Injuries and infection risk can hit anyone, but the assigned scavenger changes task automatically."))
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(0, _scaled(42))
	selector.add_theme_font_size_override("font_size", _scaled(12))
	for survivor in survivors:
		selector.add_item("%s - %s" % [survivor["name"], survivor["role"]], int(survivor["id"]))
		if int(survivor["id"]) == selected_scavenger_id:
			selector.select(selector.get_item_count() - 1)
	selector.item_selected.connect(_on_scavenger_selected.bind(selector))
	selector_card.add_child(selector)
	for location in ScavengeManager.locations:
		var card := _card()
		card.add_child(_heading(location["name"]))
		card.add_child(_body("Danger: %s  Alarm: %s\nLoot: %s\nPossible survivors: %s" % [location["danger"], location["alarm_risk"], ", ".join(location["loot"]), "Yes" if location["possible_survivors"] else "No"]))
		var button := Button.new()
		button.text = "Start Scavenge"
		button.custom_minimum_size = Vector2(0, _scaled(42))
		button.add_theme_font_size_override("font_size", _scaled(13))
		button.pressed.connect(_on_scavenge.bind(String(location["name"])))
		card.add_child(button)

func _build_crafting() -> void:
	_add_section("Crafting Prototype", "Use materials to make emergency supplies while the workshop system is expanded.")
	var ammo := Button.new()
	ammo.text = "Craft Ammo (-12 materials, +6 ammo)"
	ammo.custom_minimum_size = Vector2(0, _scaled(42))
	ammo.add_theme_font_size_override("font_size", _scaled(12))
	ammo.pressed.connect(func(): _craft("materials", 12, "ammo", 6))
	content.add_child(ammo)
	var med := Button.new()
	med.text = "Pack Med Kits (-8 materials, +3 medicine)"
	med.custom_minimum_size = Vector2(0, _scaled(42))
	med.add_theme_font_size_override("font_size", _scaled(12))
	med.pressed.connect(func(): _craft("materials", 8, "medicine", 3))
	content.add_child(med)

func _build_defence() -> void:
	var preview := NightDefenseManager.get_preview()
	_add_section("Night Defence", "Threat: %d\nDefence: %d\nGuards: %d\nFortified bonus: %d" % [preview["attack_strength"], preview["defence_strength"], preview["guards"], preview["fortified_bonus"]])
	var prep := Button.new()
	prep.text = "Prepare Defences"
	prep.custom_minimum_size = Vector2(0, _scaled(42))
	prep.add_theme_font_size_override("font_size", _scaled(13))
	prep.pressed.connect(func(): _show_result(GameManager.prepare_defences()["message"]))
	content.add_child(prep)
	var night := Button.new()
	night.text = "Resolve Night / End Day"
	night.custom_minimum_size = Vector2(0, _scaled(42))
	night.add_theme_font_size_override("font_size", _scaled(13))
	night.pressed.connect(func(): _show_result(GameManager.end_day()["message"]))
	content.add_child(night)

func _craft(cost_key: String, cost: int, gain_key: String, gain: int) -> void:
	if ResourceManager.spend_resource(cost_key, cost):
		ResourceManager.add_resource(gain_key, gain)
		GameManager.add_log("Crafted +%d %s." % [gain, gain_key])
		_show_result("Crafting complete.")
	else:
		_show_result("Not enough %s." % cost_key)
	_refresh()

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
	dialog.popup_centered()
	_refresh()

func _add_section(title: String, body: String) -> void:
	var card := _card()
	card.add_child(_heading(title))
	card.add_child(_body(body))

func _card() -> VBoxContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color("#3e4852")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _scaled(8))
	margin.add_theme_constant_override("margin_right", _scaled(8))
	margin.add_theme_constant_override("margin_top", _scaled(7))
	margin.add_theme_constant_override("margin_bottom", _scaled(7))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", _scaled(5))
	margin.add_child(box)
	card.add_child(margin)
	content.add_child(card)
	return box

func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", _scaled(15))
	label.add_theme_color_override("font_color", ORANGE)
	return label

func _body(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", _scaled(12))
	return label

func _survivor_selector(building_id: int) -> OptionButton:
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(0, _scaled(38))
	selector.add_theme_font_size_override("font_size", _scaled(11))
	var survivors := SurvivorManager.get_available_scavengers()
	for survivor in survivors:
		selector.add_item(String(survivor["name"]), int(survivor["id"]))
		if int(survivor["id"]) == int(selected_building_survivor.get(building_id, -1)):
			selector.select(selector.get_item_count() - 1)
	if not survivors.is_empty() and not selected_building_survivor.has(building_id):
		selected_building_survivor[building_id] = int(survivors[0]["id"])
	return selector

func _assigned_names(ids) -> String:
	if ids.is_empty():
		return "None"
	var names: Array = []
	for id in ids:
		names.append(SurvivorManager.get_survivor_name(int(id)))
	return ", ".join(names)

func _survivor_id_exists(id: int) -> bool:
	for survivor in SurvivorManager.get_available_scavengers():
		if int(survivor["id"]) == id:
			return true
	return false

func _task_summary() -> String:
	var counts := {}
	for task in SurvivorManager.TASKS:
		counts[task] = 0
	for survivor in SurvivorManager.get_available_scavengers():
		var task := String(survivor.get("assigned_task", "Rest"))
		counts[task] = int(counts.get(task, 0)) + 1
	var parts: Array = []
	for task in SurvivorManager.TASKS:
		if int(counts[task]) > 0:
			parts.append("%s: %d" % [task, counts[task]])
	return "\n".join(parts)
