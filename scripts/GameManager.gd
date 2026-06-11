extends Node

signal state_changed
signal log_changed
signal recruit_found(recruit: Dictionary)
signal game_over(message: String)

var event_log: Array = []
var current_objective := "Assign tasks, scavenge supplies, and survive the night."
var pending_recruit: Dictionary = {}
var phase := "Morning"
var game_over_message := ""

func _ready() -> void:
	randomize()
	ActivityManager.job_completed.connect(_on_activity_job_completed)
	ScavengeManager.scavenge_completed.connect(_on_scavenge_completed)

func new_game() -> void:
	ResourceManager.reset()
	SurvivorManager.reset()
	BuildingManager.reset()
	ScavengeManager.reset()
	ActivityManager.reset()
	event_log = []
	pending_recruit = {}
	phase = "Morning"
	game_over_message = ""
	add_log("Day 1: Dead Shift begins at the Main Warehouse.")
	_update_objective()
	SaveManager.save_game(event_log)
	state_changed.emit()

func continue_game() -> bool:
	var data := SaveManager.load_game()
	if data.is_empty():
		return false
	event_log = Array(data.get("event_log", [])).duplicate()
	phase = String(data.get("phase", "Morning"))
	game_over_message = String(data.get("game_over_message", ""))
	add_log("Save loaded. Day %d continues." % ResourceManager.get_value("day_number"))
	_update_objective()
	state_changed.emit()
	return true

func manual_save() -> bool:
	add_log("Manual save complete.")
	return SaveManager.save_game(event_log)

func add_log(message: String) -> void:
	var stamp := "Day %d" % ResourceManager.get_value("day_number")
	event_log.push_front("%s - %s" % [stamp, message])
	if event_log.size() > 80:
		event_log.resize(80)
	log_changed.emit()

func assign_survivor_task(id: int, task: String) -> void:
	if is_game_over():
		return
	SurvivorManager.assign_task(id, task)
	ActivityManager.start_task(id, task)
	add_log("Task assigned: %s." % task)
	phase = "Management"
	_update_objective()
	state_changed.emit()

func building_action(id: int, action: String) -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var result := BuildingManager.perform_action(id, action)
	add_log(result["message"])
	phase = "Building"
	_update_objective()
	state_changed.emit()
	return result

func assign_building_use(id: int, use_name: String) -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var result := BuildingManager.assign_use(id, use_name)
	add_log(result["message"])
	phase = "Building"
	_update_objective()
	state_changed.emit()
	return result

func assign_survivor_to_building(building_id: int, survivor_id: int) -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var result := BuildingManager.assign_survivor(building_id, survivor_id)
	add_log(result["message"])
	phase = "Management"
	_update_objective()
	state_changed.emit()
	return result

func scavenge(location_name: String, survivor_id: int) -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	if ActivityManager.get_job(survivor_id).get("task", "") == "Scavenge" and ActivityManager.get_job(survivor_id).get("location", "") != "":
		return {"ok": false, "message": "%s is already outside scavenging." % SurvivorManager.get_survivor_name(survivor_id)}
	ActivityManager.start_scavenge(survivor_id, location_name)
	var result := {"ok": true, "message": "%s left to scavenge %s." % [SurvivorManager.get_survivor_name(survivor_id), location_name]}
	add_log(result["message"])
	phase = "Scavenge"
	_update_objective()
	state_changed.emit()
	return result

func handle_recruit(choice: String) -> void:
	if pending_recruit.is_empty():
		return
	match choice:
		"Invite":
			SurvivorManager.invite_recruit(pending_recruit)
			add_log("%s joined the colony." % pending_recruit["name"])
		"Quarantine":
			SurvivorManager.quarantine_recruit(pending_recruit)
			add_log("%s was quarantined outside the warehouse." % pending_recruit["name"])
		"Reject":
			SurvivorManager.reject_recruit(pending_recruit)
			add_log("%s was turned away." % pending_recruit["name"])
	pending_recruit = {}
	_update_objective()
	state_changed.emit()

func prepare_defences() -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var result := NightDefenseManager.prepare_defences()
	add_log(result["message"])
	phase = "Defence"
	_update_objective()
	state_changed.emit()
	return result

func end_day() -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	phase = "Night"
	var night := NightDefenseManager.resolve_night()
	add_log(night["message"])
	for message in SurvivorManager.apply_task_effects():
		add_log(message)
	for message in BuildingManager.apply_use_bonuses():
		add_log(message)
	var consumption := ResourceManager.apply_daily_consumption(SurvivorManager.get_available_scavengers().size())
	if int(consumption["shortage"]) > 0:
		add_log("Food or water shortage hurt morale.")
	else:
		add_log("Rations issued: %d food, %d water." % [consumption["food_needed"], consumption["water_needed"]])
	ResourceManager.advance_day()
	phase = "Morning"
	_check_failure_state()
	_update_objective()
	add_log("Auto-save complete. Morning begins.")
	SaveManager.save_game(event_log)
	state_changed.emit()
	return night

func reset_save_and_game() -> void:
	SaveManager.reset_save()
	new_game()

func is_game_over() -> bool:
	return game_over_message != ""

func _on_activity_job_completed(_survivor_id: int, _task: String, message: String) -> void:
	add_log(message)
	_update_objective()
	state_changed.emit()

func _on_scavenge_completed(result: Dictionary) -> void:
	if not result.get("recruit", {}).is_empty():
		pending_recruit = result["recruit"]
		recruit_found.emit(pending_recruit)

func _update_objective() -> void:
	if game_over_message != "":
		current_objective = game_over_message
		return
	var r := ResourceManager.resources
	if BuildingManager.count_by_status("Claimed") + BuildingManager.count_by_status("Operational") + BuildingManager.count_by_status("Fortified") < 2:
		current_objective = "Scout, clear, and claim a second building for the colony."
	elif int(r["food"]) < 40 or int(r["water"]) < 40:
		current_objective = "Food and water are low. Send a survivor to scavenge supplies."
	elif int(r["security"]) < 60:
		current_objective = "Security is weak. Assign guards, repair defences, or fortify a building."
	elif int(r["horde_threat"]) >= 45:
		current_objective = "Horde pressure is rising. Scout, call radio, or prepare defences."
	else:
		current_objective = "Expand the estate, keep morale stable, and survive the next night."

func _check_failure_state() -> void:
	if SurvivorManager.get_available_scavengers().is_empty():
		game_over_message = "Colony lost: no living survivors remain."
	elif ResourceManager.get_value("morale") <= 0:
		game_over_message = "Colony broken: morale has collapsed."
	elif BuildingManager.count_survivable_buildings() <= 0:
		game_over_message = "Colony lost: all claimed buildings are gone."
	if game_over_message != "":
		add_log(game_over_message)
		game_over.emit(game_over_message)
