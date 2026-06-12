extends SceneTree

var failures: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1228, 691))
	await process_frame
	GameManager.new_game()
	var scene := load("res://scenes/Game.tscn") as PackedScene
	_assert_true(scene != null, "Game scene loads")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_assert_true(game.get_child_count() >= 3, "Game scene builds visible UI children")
	_assert_true(_has_button_text(game, "MENU"), "Game scene contains menu button")
	_assert_true(_has_label_text(game, "DEAD SHIFT"), "Game scene contains title label")
	_assert_rect_inside_viewport(game.find_child("BottomCommandBar", true, false) as Control, game, "Bottom command bar starts inside phone viewport")
	_assert_rect_inside_viewport(game.find_child("QuickMenuBar", true, false) as Control, game, "Quick menu starts inside phone viewport")
	await _assert_game_popup_fit(game, "_show_scavenge_popup", [], "Scavenge popup")
	await _assert_game_popup_fit(game, "_show_build_popup", [], "Build popup")
	await _assert_game_popup_fit(game, "_show_defence_popup", [], "Defence popup")
	await _assert_game_popup_fit(game, "_show_game_menu", [], "Game menu popup")
	await _assert_game_popup_fit(game, "_show_tutorial", [], "Tutorial popup")
	await _assert_game_popup_fit(game, "_show_task_popup", [1], "Survivor task popup")
	await _assert_game_popup_fit(game, "_show_result", ["Phone viewport test message"], "Result popup")
	await _assert_menu_button_route(game, "BUILD / MANAGE", "Build & Manage", "menu build route")
	await _assert_menu_button_route(game, "SCOUT LOCATIONS", "Scout Locations", "menu scout route")
	await _assert_menu_button_route(game, "PREPARE DEFENCES", "Prepare Defences", "menu defence route")
	await _assert_menu_button_route(game, "MANUAL SAVE", "Dead Shift", "menu manual save route")
	await _assert_menu_button_route(game, "HOW TO PLAY", "How To Survive", "menu tutorial route")
	await _assert_tab_routes(game)
	game.queue_free()

	var menu_scene := load("res://scenes/MainMenu.tscn") as PackedScene
	_assert_true(menu_scene != null, "Main menu scene loads")
	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	_assert_true(menu.has_method("_safe_area_margins"), "Main menu exposes safe-area layout helper")
	menu.call("_show_message", "Test message")
	await process_frame
	_assert_true(_largest_panel(menu) != null, "Main menu modal opens inside the scene")
	menu.call("_dismiss_modal")
	menu.call("_new_game")
	await process_frame
	await process_frame
	var current := current_scene
	_assert_true(current != null, "New Game leaves an active scene")
	if current != null:
		_assert_true(String(current.scene_file_path) == "res://scenes/Game.tscn", "New Game changes to Game scene")
		_assert_true(current.get_child_count() >= 3, "New Game target scene builds visible UI children")
		_assert_true(_has_button_text(current, "MENU"), "New Game target scene contains menu button")

	var settings_scene := load("res://scenes/screens/SettingsScreen.tscn") as PackedScene
	_assert_true(settings_scene != null, "Settings scene loads")
	var settings := settings_scene.instantiate()
	root.add_child(settings)
	await process_frame
	_assert_true(settings.has_method("_safe_area_margins"), "Settings screen exposes safe-area layout helper")
	_assert_true(_has_button_text(settings, "BACK"), "Settings screen contains back button")
	settings.call("_message", "Test settings modal")
	await process_frame
	_assert_true(_largest_panel(settings) != null, "Settings modal opens inside the scene")
	settings.queue_free()

	if failures.is_empty():
		print("Dead Shift scene UI test passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _has_button_text(node: Node, text: String) -> bool:
	if node is Button and String(node.text) == text:
		return true
	for child in node.get_children():
		if _has_button_text(child, text):
			return true
	return false

func _has_label_text(node: Node, text: String) -> bool:
	if node is Label and String(node.text).contains(text):
		return true
	for child in node.get_children():
		if _has_label_text(child, text):
			return true
	return false

func _largest_panel(node: Node) -> PanelContainer:
	var best: PanelContainer = null
	if node is PanelContainer:
		best = node
	for child in node.get_children():
		var candidate := _largest_panel(child)
		if candidate == null:
			continue
		if best == null or candidate.size.length_squared() > best.size.length_squared():
			best = candidate
	return best

func _modal_panel(node: Node) -> PanelContainer:
	var overlay := _modal_overlay(node)
	if overlay == null:
		return null
	return _largest_panel(overlay)

func _modal_overlay(node: Node) -> ColorRect:
	if node is ColorRect and absf(float(node.color.a) - 0.72) < 0.02:
		return node
	for child in node.get_children():
		var found := _modal_overlay(child)
		if found != null:
			return found
	return null

func _assert_game_popup_fit(game: Control, method_name: String, args: Array, label: String) -> void:
	game.callv(method_name, args)
	await process_frame
	await process_frame
	var modal_panel := _modal_panel(game)
	_assert_true(modal_panel != null, "%s creates an in-game modal panel" % label)
	_assert_rect_inside_viewport(modal_panel, game, "%s remains inside phone viewport" % label)
	_assert_rect_inside_viewport(game.find_child("BottomCommandBar", true, false) as Control, game, "Bottom command bar remains inside after %s" % label)
	_assert_rect_inside_viewport(game.find_child("QuickMenuBar", true, false) as Control, game, "Quick menu remains inside after %s" % label)
	game.call("_dismiss_modal")
	await process_frame

func _assert_menu_button_route(game: Control, button_text: String, expected_title: String, label: String) -> void:
	game.call("_show_game_menu")
	await process_frame
	var button := _button_with_text(_modal_overlay(game), button_text)
	_assert_true(button != null, "%s has %s button" % [label, button_text])
	if button != null:
		button.pressed.emit()
		await process_frame
		await process_frame
		_assert_true(_has_label_text(_modal_overlay(game), expected_title), "%s opens %s" % [label, expected_title])
		_assert_rect_inside_viewport(_modal_panel(game), game, "%s popup remains inside phone viewport" % label)
	game.call("_dismiss_modal")
	await process_frame

func _assert_tab_routes(game: Control) -> void:
	for tab in ["Buildings", "Survivors", "Scavenge", "Crafting", "Defence", "Radio"]:
		var button := _button_with_text(game, tab)
		_assert_true(button != null, "bottom nav has %s tab" % tab)
		if button == null:
			continue
		button.pressed.emit()
		await process_frame
		_assert_true(_has_label_text(game, tab.to_upper()), "%s tab updates command title" % tab)
		_assert_rect_inside_viewport(game.find_child("BottomCommandBar", true, false) as Control, game, "%s tab keeps bottom command bar visible" % tab)

func _assert_rect_inside_viewport(control: Control, viewport_owner: Control, message: String) -> void:
	if control == null:
		failures.append("%s: missing control" % message)
		return
	var viewport_rect := Rect2(Vector2.ZERO, viewport_owner.get_viewport_rect().size)
	var rect := Rect2(control.global_position, control.size)
	_assert_true(viewport_rect.encloses(rect), message)

func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _button_with_text(node: Node, text: String) -> Button:
	if node == null:
		return null
	if node is Button and String(node.text) == text:
		return node
	for child in node.get_children():
		var found := _button_with_text(child, text)
		if found != null:
			return found
	return null
