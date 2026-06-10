extends Node

signal state_changed
signal log_changed
signal recruit_found(recruit: Dictionary)

var event_log: Array = []
var current_objective := "Assign tasks, scavenge supplies, and survive the night."
var pending_recruit: Dictionary = {}

func _ready() -> void:
	randomize()

func new_game() -> void:
	ResourceManager.reset()
	SurvivorManager.reset()
	BuildingManager.reset()
	ScavengeManager.reset()
	event_log = []
	pending_recruit = {}
	add_log("Day 1: Dead Shift begins at the Main Warehouse.")
	SaveManager.save_game(event_log)
	state_changed.emit()

func continue_game() -> bool:
	var data := SaveManager.load_game()
	if data.is_empty():
		return false
	event_log = Array(data.get("event_log", [])).duplicate()
	add_log("Save loaded. Day %d continues." % ResourceManager.get_value("day_number"))
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
	SurvivorManager.assign_task(id, task)
	add_log("Task assigned: %s." % task)
	state_changed.emit()

func building_action(id: int, action: String) -> Dictionary:
	var result := BuildingManager.perform_action(id, action)
	add_log(result["message"])
	state_changed.emit()
	return result

func assign_building_use(id: int, use_name: String) -> Dictionary:
	var result := BuildingManager.assign_use(id, use_name)
	add_log(result["message"])
	state_changed.emit()
	return result

func assign_survivor_to_building(building_id: int, survivor_id: int) -> Dictionary:
	var result := BuildingManager.assign_survivor(building_id, survivor_id)
	add_log(result["message"])
	state_changed.emit()
	return result

func scavenge(location_name: String, survivor_id: int) -> Dictionary:
	var result := ScavengeManager.run_scavenge(location_name, survivor_id)
	add_log(result.get("message", "Scavenge failed."))
	if not result.get("recruit", {}).is_empty():
		pending_recruit = result["recruit"]
		recruit_found.emit(pending_recruit)
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
	state_changed.emit()

func prepare_defences() -> Dictionary:
	var result := NightDefenseManager.prepare_defences()
	add_log(result["message"])
	state_changed.emit()
	return result

func end_day() -> Dictionary:
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
	add_log("Auto-save complete. Morning begins.")
	SaveManager.save_game(event_log)
	state_changed.emit()
	return night

func reset_save_and_game() -> void:
	SaveManager.reset_save()
	new_game()
