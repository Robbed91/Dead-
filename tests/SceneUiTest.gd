extends SceneTree

var failures: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
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
	game.call("_show_scavenge_popup")
	await process_frame
	var modal_panel := _largest_panel(game)
	_assert_true(modal_panel != null, "Scavenge popup creates an in-game modal panel")
	if modal_panel != null:
		var viewport_size: Vector2 = game.get_viewport_rect().size
		_assert_true(modal_panel.size.x <= viewport_size.x and modal_panel.size.y <= viewport_size.y, "Modal panel remains inside current viewport")
	game.queue_free()

	var menu_scene := load("res://scenes/MainMenu.tscn") as PackedScene
	_assert_true(menu_scene != null, "Main menu scene loads")
	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	menu.call("_new_game")
	await process_frame
	await process_frame
	var current := current_scene
	_assert_true(current != null, "New Game leaves an active scene")
	if current != null:
		_assert_true(String(current.scene_file_path) == "res://scenes/Game.tscn", "New Game changes to Game scene")
		_assert_true(current.get_child_count() >= 3, "New Game target scene builds visible UI children")
		_assert_true(_has_button_text(current, "MENU"), "New Game target scene contains menu button")

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

func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
