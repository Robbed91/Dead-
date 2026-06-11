extends Node

signal state_changed
signal log_changed
signal recruit_found(recruit: Dictionary)
signal game_over(message: String)
signal colony_tier_changed(tier: Dictionary)

const COLONY_TIERS := [
	{"id": "hideout", "name": "Hideout", "population": 1, "buildings": 1, "reward": {"morale": 0, "security": 0}, "description": "One survivor holding one warehouse."},
	{"id": "camp", "name": "Camp", "population": 2, "buildings": 1, "reward": {"morale": 2, "security": 1}, "description": "A small camp with enough hands to share work."},
	{"id": "community", "name": "Community", "population": 5, "buildings": 2, "reward": {"morale": 4, "security": 3}, "description": "A proper group with roles, routines, and claimed space."},
	{"id": "settlement", "name": "Settlement", "population": 10, "buildings": 4, "reward": {"morale": 5, "security": 5}, "description": "A defended settlement spreading across the estate."},
	{"id": "district", "name": "District", "population": 18, "buildings": 6, "reward": {"morale": 6, "security": 7}, "description": "A reclaimed industrial district with specialised buildings."},
	{"id": "city", "name": "City", "population": 30, "buildings": 9, "reward": {"morale": 8, "security": 10}, "description": "A survivor city built from the old estate."}
]

var event_log: Array = []
var current_objective := "Billy is alone. Scavenge nearby units, find survivors, and build the colony."
var pending_recruit: Dictionary = {}
var phase := "Morning"
var game_over_message := ""
var colony_tier_index := 0

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
	colony_tier_index = _calculate_colony_tier_index()
	add_log("Day 1: Billy barricaded himself inside his workshop.")
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
	colony_tier_index = int(data.get("colony_tier_index", _calculate_colony_tier_index()))
	add_log("Save loaded. Day %d continues." % ResourceManager.get_value("day_number"))
	_update_colony_tier(false)
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
	if not SurvivorManager.is_crew(id):
		add_log("%s is an NPC resident. Add them to the crew before giving direct orders." % SurvivorManager.get_survivor_name(id))
		state_changed.emit()
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
	_update_colony_tier(true)
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
	if not SurvivorManager.is_crew(survivor_id):
		return {"ok": false, "message": "%s is an NPC resident. Add them to the crew before sending them outside." % SurvivorManager.get_survivor_name(survivor_id)}
	if ActivityManager.get_job(survivor_id).get("task", "") == "Scavenge" and ActivityManager.get_job(survivor_id).get("location", "") != "":
		return {"ok": false, "message": "%s is already outside scavenging." % SurvivorManager.get_survivor_name(survivor_id)}
	var availability := ScavengeManager.can_scavenge(location_name)
	if not bool(availability.get("ok", false)):
		return availability
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
	_update_colony_tier(true)
	_update_objective()
	state_changed.emit()

func prepare_defences(tactic_id := "patch_barricades") -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var result := NightDefenseManager.prepare_defences(tactic_id)
	add_log(result["message"])
	phase = "Defence"
	_update_objective()
	state_changed.emit()
	return result

func call_radio_contact() -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	if ResourceManager.get_value("power") < 2:
		return {"ok": false, "message": "Not enough power to run the radio."}
	ResourceManager.add_resource("power", -2)
	ResourceManager.add_resource("horde_threat", -2)
	ResourceManager.add_resource("noise", 1)
	phase = "Radio"
	var message := "Radio scan complete. Horde threat reduced."
	var recruit_chance := 55 if SurvivorManager.get_population_count() < 5 else 30
	if pending_recruit.is_empty() and randi_range(1, 100) <= recruit_chance:
		pending_recruit = SurvivorManager.generate_recruit()
		message += " A survivor answered the call: %s the %s." % [pending_recruit["name"], pending_recruit["role"]]
		add_log(message)
		recruit_found.emit(pending_recruit)
		_update_objective()
		state_changed.emit()
		return {"ok": true, "message": message, "recruit_found": true}
	else:
		add_log(message)
	_update_objective()
	state_changed.emit()
	return {"ok": true, "message": message, "recruit_found": false}

func end_day() -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var report: Array = []
	phase = "Night"
	var night := NightDefenseManager.resolve_night()
	add_log(night["message"])
	report.append(night["message"])
	for message in SurvivorManager.assign_npc_routines():
		add_log(message)
		report.append(message)
	for message in SurvivorManager.apply_task_effects():
		add_log(message)
		report.append(message)
	for message in BuildingManager.apply_use_bonuses():
		add_log(message)
		report.append(message)
	for message in SurvivorManager.apply_condition_progression():
		add_log(message)
		report.append(message)
	var colony_event := _resolve_colony_event()
	if colony_event != "":
		add_log(colony_event)
		report.append(colony_event)
	for message in ScavengeManager.advance_day():
		add_log(message)
		report.append(message)
	var consumption := ResourceManager.apply_daily_consumption(SurvivorManager.get_available_scavengers().size())
	if int(consumption["shortage"]) > 0:
		add_log("Food or water shortage hurt morale.")
		report.append("Food or water shortage hurt morale.")
	else:
		add_log("Rations issued: %d food, %d water." % [consumption["food_needed"], consumption["water_needed"]])
		report.append("Rations issued: %d food, %d water." % [consumption["food_needed"], consumption["water_needed"]])
	if int(consumption.get("bed_shortage", 0)) > 0:
		var bed_message := "Overcrowding hurt morale: %d survivor(s) have no bed." % int(consumption["bed_shortage"])
		add_log(bed_message)
		report.append(bed_message)
	ResourceManager.advance_day()
	phase = "Morning"
	_update_colony_tier(true)
	_check_failure_state()
	_update_objective()
	add_log("Auto-save complete. Morning begins.")
	SaveManager.save_game(event_log)
	state_changed.emit()
	night["daily_report"] = report
	night["message"] = "Night Report\n%s" % "\n".join(report.slice(0, 9))
	return night

func reset_save_and_game() -> void:
	SaveManager.reset_save()
	new_game()

func is_game_over() -> bool:
	return game_over_message != ""

func set_survivor_control_mode(id: int, mode: String) -> Dictionary:
	if is_game_over():
		return {"ok": false, "message": game_over_message}
	var result := SurvivorManager.set_control_mode(id, mode)
	add_log(result["message"])
	_update_colony_tier(true)
	_update_objective()
	state_changed.emit()
	return result

func get_colony_tier() -> Dictionary:
	var tier: Dictionary = COLONY_TIERS[colony_tier_index]
	return tier

func get_next_colony_tier() -> Dictionary:
	if colony_tier_index >= COLONY_TIERS.size() - 1:
		return {}
	var tier: Dictionary = COLONY_TIERS[colony_tier_index + 1]
	return tier

func get_colony_growth_summary() -> String:
	var tier: Dictionary = get_colony_tier()
	var next: Dictionary = get_next_colony_tier()
	var population := SurvivorManager.get_population_count()
	var buildings := BuildingManager.count_controlled_buildings()
	var crew := SurvivorManager.get_crew_count()
	var crew_limit := SurvivorManager.get_direct_control_limit()
	if next.is_empty():
		return "%s: %d survivors, %d controlled buildings, crew %d/%d. The estate has become a survivor city." % [tier["name"], population, buildings, crew, crew_limit]
	return "%s: %d/%d survivors, %d/%d buildings, crew %d/%d toward %s." % [tier["name"], population, int(next["population"]), buildings, int(next["buildings"]), crew, crew_limit, next["name"]]

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
	var next_tier: Dictionary = get_next_colony_tier()
	if SurvivorManager.get_population_count() <= 1:
		current_objective = "Billy is alone. Scout a nearby location and look for survivors."
	elif not next_tier.is_empty() and SurvivorManager.get_population_count() < int(next_tier["population"]):
		current_objective = "Grow from %s to %s: recruit survivors through scavenging and radio contact." % [get_colony_tier()["name"], next_tier["name"]]
	elif not next_tier.is_empty() and BuildingManager.count_controlled_buildings() < int(next_tier["buildings"]):
		current_objective = "Grow from %s to %s: scout, clear, and claim more buildings." % [get_colony_tier()["name"], next_tier["name"]]
	elif BuildingManager.count_by_status("Claimed") + BuildingManager.count_by_status("Operational") + BuildingManager.count_by_status("Fortified") < 2:
		current_objective = "Scout, clear, and claim a second building for the colony."
	elif int(r["food"]) < 40 or int(r["water"]) < 40:
		current_objective = "Food and water are low. Send a survivor to scavenge supplies."
	elif int(r["security"]) < 60:
		current_objective = "Security is weak. Assign guards, repair defences, or fortify a building."
	elif int(r["horde_threat"]) >= 45:
		current_objective = "Horde pressure is rising. Scout, call radio, or prepare defences."
	else:
		current_objective = get_colony_growth_summary()

func _calculate_colony_tier_index() -> int:
	var population := SurvivorManager.get_population_count()
	var buildings := BuildingManager.count_controlled_buildings()
	var unlocked := 0
	for index in range(COLONY_TIERS.size()):
		var tier: Dictionary = COLONY_TIERS[index]
		if population >= int(tier["population"]) and buildings >= int(tier["buildings"]):
			unlocked = index
	return unlocked

func _update_colony_tier(announce: bool) -> void:
	var next_index := _calculate_colony_tier_index()
	if next_index == colony_tier_index:
		return
	var previous_index := colony_tier_index
	colony_tier_index = next_index
	if announce and next_index > previous_index:
		var tier: Dictionary = COLONY_TIERS[next_index]
		var reward: Dictionary = tier["reward"]
		ResourceManager.add_resource("morale", int(reward.get("morale", 0)))
		ResourceManager.add_resource("security", int(reward.get("security", 0)))
		add_log("Colony grew into a %s. %s" % [tier["name"], tier["description"]])
		colony_tier_changed.emit(tier)

func _check_failure_state() -> void:
	if colony_tier_index >= COLONY_TIERS.size() - 1 and BuildingManager.count_controlled_buildings() >= 9 and ResourceManager.get_value("day_number") >= 30:
		game_over_message = "Victory: Dead Shift has become a survivor city. The estate is secured for now."
	elif SurvivorManager.get_available_scavengers().is_empty():
		game_over_message = "Colony lost: no living survivors remain."
	elif ResourceManager.get_value("morale") <= 0:
		game_over_message = "Colony broken: morale has collapsed."
	elif BuildingManager.count_survivable_buildings() <= 0:
		game_over_message = "Colony lost: all claimed buildings are gone."
	if game_over_message != "":
		add_log(game_over_message)
		game_over.emit(game_over_message)

func _resolve_colony_event() -> String:
	var event_chance := 35 + mini(25, SurvivorManager.get_population_count())
	if randi_range(1, 100) > event_chance:
		return ""
	var roll := randi_range(1, 14)
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
		7:
			if ResourceManager.get_value("food") >= 8:
				ResourceManager.add_resource("food", -8)
				ResourceManager.add_resource("ammo", 4)
				ResourceManager.add_resource("morale", 1)
				return "A trader at the fence swapped cartridges for food. Ammo +4."
		8:
			ResourceManager.add_resource("tools", 1)
			ResourceManager.add_resource("materials", 6)
			return "A locked van was opened behind the units. Tools +1, materials +6."
		9:
			ResourceManager.add_resource("noise", 8)
			ResourceManager.add_resource("horde_threat", 5)
			return "A distant alarm echoed through the estate. Noise and horde threat rose."
		10:
			var repaired := BuildingManager.repair_lowest_condition(randi_range(4, 9))
			if not repaired.is_empty():
				return "A repair crew patched %s during downtime." % repaired.get("name", "a building")
		11:
			if BuildingManager.count_by_use("Radio Room") > 0:
				ResourceManager.add_resource("horde_threat", -4)
				return "Radio chatter warned of horde movement. Threat reduced."
		12:
			if BuildingManager.count_by_use("Food Prep") > 0:
				ResourceManager.add_resource("food", randi_range(4, 9))
				ResourceManager.add_resource("morale", 1)
				return "The kitchen turned scraps into a proper meal. Food and morale improved."
		13:
			if SurvivorManager.get_population_count() >= 6:
				var target := SurvivorManager.injure_random(randi_range(4, 10), 0)
				if not target.is_empty():
					return "%s was hurt moving supplies in the dark." % target.get("name", "Someone")
		14:
			if ResourceManager.get_value("power") > 0:
				ResourceManager.add_resource("power", -2)
				ResourceManager.add_resource("security", 2)
				return "Floodlights ran longer than planned. Power -2, security +2."
	return ""
