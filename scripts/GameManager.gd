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

func install_building_upgrade(building_id: int, upgrade_id: String) -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var result := BuildingManager.install_upgrade(building_id, upgrade_id)
	add_log(result["message"])
	phase = "Building"
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
	for message in SurvivorManager.apply_condition_progression():
		add_log(message)
	var colony_event := _resolve_colony_event()
	if colony_event != "":
		add_log(colony_event)
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

func _resolve_colony_event() -> String:
	if randi_range(1, 100) > 38:
		return ""
	var roll := randi_range(1, 6)
	match roll:
		1:
			var found := randi_range(4, 12)
			ResourceManager.add_resource("materials", found)
			return "A storage cage was forced open. Materials +%d." % found
		2:
			ResourceManager.add_resource("fuel", -randi_range(2, 5))
			ResourceManager.add_resource("noise", 3)
			return "The generator coughed through the evening. Fuel lost and noise increased."
		3:
			var available := SurvivorManager.get_available_scavengers()
			if available.is_empty():
				return ""
			var survivor: Dictionary = available.pick_random()
			SurvivorManager.adjust_morale(int(survivor["id"]), -4)
			ResourceManager.add_resource("morale", -1)
			return "%s started an argument over rationing. Morale slipped." % survivor["name"]
		4:
			ResourceManager.add_resource("water", randi_range(4, 10))
			ResourceManager.add_resource("morale", 1)
			return "Rain barrels filled overnight. Water reserves improved."
		5:
			ResourceManager.add_resource("horde_threat", 4)
			ResourceManager.add_resource("noise", -3)
			return "Movement was spotted beyond the estate. The horde is closer."
		6:
			if ResourceManager.get_value("medicine") >= 2:
				ResourceManager.add_resource("medicine", -2)
				ResourceManager.add_resource("infection_risk", -3)
				return "Jess organised a quick clinic. Medicine used, infection risk reduced."
	return ""
