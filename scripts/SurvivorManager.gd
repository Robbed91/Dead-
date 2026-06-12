extends Node

signal survivors_changed

const StartingSurvivors = preload("res://data/starting_survivors.gd")
const TASKS := ["Rest", "Guard", "Build", "Repair", "Scavenge", "Medical", "Cook", "Scout"]
const RECRUIT_ROLES := ["Builder", "Medic", "Mechanic", "Cook", "Scout", "Guard", "Engineer", "Farmer", "Teacher", "Negotiator", "Quartermaster", "Radio Operator", "Driver", "Fabricator"]
const FIRST_NAMES := ["Nina", "Raj", "Leanne", "Tom", "Sofia", "Gareth", "Priya", "Dylan", "Mo", "Hannah", "Callum", "Aisha"]
const TRAITS := ["Steady", "Quick Learner", "Tired", "Brave", "Practical", "Quiet", "Resourceful", "Nervous", "Methodical"]
const STORY_RECRUITS := [
	{"name": "Jess", "role": "Medic", "morale": 85, "loyalty": 80, "traits": ["Medical", "Calm", "Careful"]},
	{"name": "Aaron", "role": "Guard", "morale": 70, "loyalty": 65, "traits": ["Combat", "Alert", "Suspicious"]},
	{"name": "Karen", "role": "Cook", "morale": 75, "loyalty": 70, "traits": ["Food Prep", "Organised", "Anxious"]},
	{"name": "Mick", "role": "Builder", "morale": 78, "loyalty": 72, "traits": ["Repairs", "Heavy Lifting", "Noisy"]}
]

var survivors: Array = []
var next_id := 1
var next_story_recruit_index := 0

func _ready() -> void:
	reset()

func reset() -> void:
	survivors = StartingSurvivors.get_data()
	_normalize_survivors()
	next_id = 1
	next_story_recruit_index = 0
	for survivor in survivors:
		next_id = max(next_id, int(survivor["id"]) + 1)
	survivors_changed.emit()

func assign_task(id: int, task: String) -> void:
	for survivor in survivors:
		if int(survivor["id"]) == id and TASKS.has(task):
			survivor["assigned_task"] = task
			survivors_changed.emit()
			return

func set_control_mode(id: int, mode: String) -> Dictionary:
	if not ["Crew", "NPC"].has(mode):
		return {"ok": false, "message": "Unknown control mode."}
	var survivor := _find_survivor(id)
	if survivor.is_empty() or String(survivor.get("status", "Healthy")) == "Dead":
		return {"ok": false, "message": "Survivor not available."}
	if mode == "Crew" and String(survivor.get("control_mode", "NPC")) != "Crew" and get_crew_count() >= get_direct_control_limit():
		return {"ok": false, "message": "Crew limit reached. Grow the colony to control more survivors directly."}
	if mode == "NPC" and String(survivor.get("control_mode", "NPC")) == "Crew" and get_crew_count() <= 1:
		return {"ok": false, "message": "At least one survivor must remain in your direct crew."}
	survivor["control_mode"] = mode
	if mode == "NPC":
		survivor["assigned_task"] = _npc_task_for_survivor(survivor)
	survivors_changed.emit()
	return {"ok": true, "message": "%s is now %s." % [survivor["name"], mode]}

func is_crew(id: int) -> bool:
	var survivor := _find_survivor(id)
	return not survivor.is_empty() and String(survivor.get("control_mode", "NPC")) == "Crew"

func is_alive(id: int) -> bool:
	var survivor := _find_survivor(id)
	return not survivor.is_empty() and String(survivor.get("status", "Healthy")) != "Dead"

func get_crew_count() -> int:
	var total := 0
	for survivor in get_available_scavengers():
		if String(survivor.get("control_mode", "NPC")) == "Crew":
			total += 1
	return total

func get_npc_count() -> int:
	return max(0, get_population_count() - get_crew_count())

func get_direct_control_limit() -> int:
	var population := get_population_count()
	var buildings := BuildingManager.count_controlled_buildings()
	if population >= 30 and buildings >= 9:
		return 6
	if population >= 18 and buildings >= 6:
		return 5
	if population >= 10 and buildings >= 4:
		return 4
	if population >= 5 and buildings >= 2:
		return 3
	if population >= 2:
		return 2
	return 1

func get_crew_survivors() -> Array:
	return get_available_scavengers().filter(func(s): return String(s.get("control_mode", "NPC")) == "Crew")

func assign_building(id: int, building_name: String) -> bool:
	for survivor in survivors:
		if int(survivor["id"]) == id and survivor.get("status", "Healthy") != "Dead":
			survivor["assigned_building"] = building_name
			survivors_changed.emit()
			return true
	return false

func heal_survivor(id: int, amount: int) -> bool:
	for survivor in survivors:
		if int(survivor["id"]) == id and survivor.get("status", "Healthy") != "Dead":
			survivor["health"] = min(100, int(survivor.get("health", 100)) + amount)
			if int(survivor["health"]) >= 85 and int(survivor.get("infection_risk", 0)) < 40:
				survivor["status"] = "Healthy"
			survivors_changed.emit()
			return true
	return false

func treat_worst_survivor(heal_amount: int, infection_reduction: int) -> Dictionary:
	var target := {}
	for survivor in get_available_scavengers():
		if target.is_empty() or int(survivor.get("health", 100)) < int(target.get("health", 100)) or int(survivor.get("infection_risk", 0)) > int(target.get("infection_risk", 0)):
			target = survivor
	if target.is_empty():
		return {}
	target["health"] = min(100, int(target.get("health", 100)) + heal_amount)
	target["infection_risk"] = max(0, int(target.get("infection_risk", 0)) - infection_reduction)
	if int(target["health"]) >= 85 and int(target["infection_risk"]) < 40:
		target["status"] = "Healthy"
	survivors_changed.emit()
	return target

func get_survivor_name(id: int) -> String:
	for survivor in survivors:
		if int(survivor["id"]) == id:
			return String(survivor.get("name", "Unknown"))
	return "Unknown"

func get_guard_count() -> int:
	var count := 0
	for survivor in survivors:
		if survivor.get("status", "Healthy") != "Dead" and survivor.get("assigned_task", "") == "Guard":
			count += 1
	return count

func get_available_scavengers() -> Array:
	return survivors.filter(func(s): return s.get("status", "Healthy") != "Dead")

func get_population_count() -> int:
	return get_available_scavengers().size()

func apply_task_effects() -> Array:
	var messages: Array = []
	var cooks := 0
	var medics := 0
	var builders := 0
	var scouts := 0
	for survivor in get_available_scavengers():
		match survivor.get("assigned_task", "Rest"):
			"Cook":
				cooks += 1
			"Medical":
				medics += 1
			"Build", "Repair":
				builders += 1
			"Scout":
				scouts += 1
			"Rest":
				survivor["health"] = min(100, int(survivor.get("health", 100)) + 5)
	if cooks > 0:
		ResourceManager.add_resource("food", cooks)
		messages.append("Cooks stretched rations and recovered +%d food." % cooks)
	if medics > 0:
		ResourceManager.add_resource("infection_risk", -medics)
		messages.append("Medical care reduced infection risk by %d." % medics)
	if builders > 0:
		ResourceManager.add_resource("security", builders)
		ResourceManager.add_resource("noise", builders)
		messages.append("Builders improved barricades: security +%d, noise +%d." % [builders, builders])
	if scouts > 0:
		ResourceManager.add_resource("horde_threat", -scouts)
		messages.append("Scouts tracked horde movement: threat -%d." % scouts)
	survivors_changed.emit()
	return messages

func assign_npc_routines() -> Array:
	var messages: Array = []
	var changed := 0
	for survivor in get_available_scavengers():
		if String(survivor.get("control_mode", "NPC")) == "Crew":
			continue
		var old_task := String(survivor.get("assigned_task", "Rest"))
		var new_task := _npc_task_for_survivor(survivor)
		if old_task != new_task:
			survivor["assigned_task"] = new_task
			ActivityManager.start_task(int(survivor["id"]), new_task)
			changed += 1
	if changed > 0:
		messages.append("%d NPC residents took colony jobs automatically." % changed)
	survivors_changed.emit()
	return messages

func apply_condition_progression() -> Array:
	var messages: Array = []
	var medics := _task_count("Medical")
	var quarantine_slots := BuildingManager.count_by_use("Quarantine")
	var global_risk := ResourceManager.get_value("infection_risk")
	var treated := 0
	var quarantined := 0
	for survivor in survivors:
		if String(survivor.get("status", "Healthy")) == "Dead":
			continue
		var id := int(survivor["id"])
		var status := String(survivor.get("status", "Healthy"))
		var infection := int(survivor.get("infection_risk", 0))
		var health := int(survivor.get("health", 100))
		if global_risk >= 20 and status != "Healthy":
			infection += 1
		if status == "Injured" and survivor.get("assigned_task", "") != "Rest":
			health -= 2
		if status == "At Risk":
			infection += 2
		if status == "Infected":
			infection += 3
			health -= 5
		if medics > treated and (health < 80 or infection >= 35):
			treated += 1
			health += 8
			infection -= 5
			if ResourceManager.get_value("medicine") > 0:
				ResourceManager.add_resource("medicine", -1)
				infection -= 4
			messages.append("%s received medical treatment." % survivor["name"])
		elif quarantine_slots > quarantined and infection >= 45:
			quarantined += 1
			infection -= 3
			ResourceManager.add_resource("morale", -1)
			messages.append("%s was kept isolated overnight." % survivor["name"])
		if infection >= 85 or health <= 0:
			survivor["health"] = 0
			survivor["status"] = "Dead"
			survivor["assigned_task"] = "Rest"
			ActivityManager.active_jobs.erase(id)
			ResourceManager.add_resource("morale", -8)
			ResourceManager.add_resource("infection_risk", 3)
			messages.append("%s did not survive the night." % survivor["name"])
			continue
		survivor["health"] = clamp(health, 0, 100)
		survivor["infection_risk"] = clamp(infection, 0, 100)
		if int(survivor["infection_risk"]) >= 70:
			survivor["status"] = "Infected"
		elif int(survivor["infection_risk"]) >= 50:
			survivor["status"] = "At Risk"
		elif int(survivor["health"]) < 70:
			survivor["status"] = "Injured"
		elif int(survivor["health"]) >= 85 and int(survivor["infection_risk"]) < 35:
			survivor["status"] = "Healthy"
	ResourceManager.set_value("population", get_population_count())
	survivors_changed.emit()
	return messages

func injure_random(amount: int, infection_added: int) -> Dictionary:
	var alive := get_available_scavengers()
	if alive.is_empty():
		return {}
	var survivor: Dictionary = alive.pick_random()
	return injure_survivor(int(survivor["id"]), amount, infection_added)

func injure_survivor(id: int, amount: int, infection_added: int) -> Dictionary:
	var survivor := _find_survivor(id)
	if survivor.is_empty() or survivor.get("status", "Healthy") == "Dead":
		return {}
	survivor["health"] = max(0, int(survivor["health"]) - amount)
	survivor["infection_risk"] = min(100, int(survivor["infection_risk"]) + infection_added)
	if int(survivor["health"]) <= 0:
		survivor["status"] = "Dead"
	elif int(survivor["infection_risk"]) >= 60:
		survivor["status"] = "At Risk"
	else:
		survivor["status"] = "Injured"
	survivors_changed.emit()
	return survivor

func adjust_morale(id: int, amount: int) -> void:
	var survivor := _find_survivor(id)
	if survivor.is_empty() or survivor.get("status", "Healthy") == "Dead":
		return
	survivor["morale"] = clamp(int(survivor.get("morale", 75)) + amount, 0, 100)
	survivors_changed.emit()

func generate_recruit() -> Dictionary:
	if next_story_recruit_index < STORY_RECRUITS.size():
		var story_recruit: Dictionary = STORY_RECRUITS[next_story_recruit_index]
		return {
			"id": next_id,
			"name": story_recruit["name"],
			"role": story_recruit["role"],
			"health": randi_range(86, 100),
			"morale": int(story_recruit["morale"]),
			"loyalty": int(story_recruit["loyalty"]),
			"infection_risk": randi_range(0, 8),
			"assigned_task": "Rest",
			"assigned_building": "Main Warehouse",
			"control_mode": "NPC",
			"status": "Waiting",
			"traits": Array(story_recruit["traits"]).duplicate(true),
			"story_recruit": true,
			"story_index": next_story_recruit_index
		}
	var role: String = RECRUIT_ROLES.pick_random()
	return {
		"id": next_id,
		"name": FIRST_NAMES.pick_random(),
		"role": role,
		"health": randi_range(70, 100),
		"morale": randi_range(55, 85),
		"loyalty": randi_range(45, 80),
		"infection_risk": randi_range(0, 20),
		"assigned_task": "Rest",
		"assigned_building": "Main Warehouse",
		"control_mode": "NPC",
		"status": "Waiting",
		"traits": [TRAITS.pick_random(), TRAITS.pick_random()]
	}

func invite_recruit(recruit: Dictionary) -> void:
	var survivor := recruit.duplicate(true)
	survivor["id"] = next_id
	survivor["status"] = "Healthy"
	survivor["control_mode"] = "NPC"
	survivor["assigned_task"] = _npc_task_for_survivor(survivor)
	survivor.erase("story_recruit")
	survivor.erase("story_index")
	next_id += 1
	_consume_story_recruit(recruit)
	survivors.append(survivor)
	ResourceManager.set_value("population", survivors.size())
	ResourceManager.add_resource("morale", 3)
	survivors_changed.emit()

func quarantine_recruit(recruit: Dictionary) -> void:
	_consume_story_recruit(recruit)
	ResourceManager.add_resource("morale", -2)
	ResourceManager.add_resource("infection_risk", -3)

func reject_recruit(recruit: Dictionary) -> void:
	_consume_story_recruit(recruit)
	ResourceManager.add_resource("morale", -1)

func to_dict() -> Dictionary:
	return {"survivors": survivors.duplicate(true), "next_id": next_id, "next_story_recruit_index": next_story_recruit_index}

func from_dict(data: Dictionary) -> void:
	survivors = Array(data.get("survivors", [])).duplicate(true)
	_normalize_survivors()
	next_id = int(data.get("next_id", survivors.size() + 1))
	next_story_recruit_index = int(data.get("next_story_recruit_index", _infer_next_story_recruit_index()))
	ResourceManager.set_value("population", survivors.filter(func(s): return s.get("status", "Healthy") != "Dead").size())
	survivors_changed.emit()

func _task_count(task: String) -> int:
	var total := 0
	for survivor in get_available_scavengers():
		if String(survivor.get("assigned_task", "")) == task:
			total += 1
	return total

func _find_survivor(id: int) -> Dictionary:
	for survivor in survivors:
		if int(survivor["id"]) == id:
			return survivor
	return {}

func _normalize_survivors() -> void:
	var first_alive_crew_assigned := false
	for survivor in survivors:
		if not survivor.has("control_mode"):
			survivor["control_mode"] = "Crew" if not first_alive_crew_assigned and String(survivor.get("status", "Healthy")) != "Dead" else "NPC"
		if String(survivor.get("control_mode", "")) == "Crew" and String(survivor.get("status", "Healthy")) != "Dead":
			first_alive_crew_assigned = true

func _consume_story_recruit(recruit: Dictionary) -> void:
	if bool(recruit.get("story_recruit", false)):
		next_story_recruit_index = max(next_story_recruit_index, int(recruit.get("story_index", next_story_recruit_index)) + 1)

func _infer_next_story_recruit_index() -> int:
	var index := 0
	for story_recruit in STORY_RECRUITS:
		for survivor in survivors:
			if String(survivor.get("name", "")) == String(story_recruit["name"]) and String(survivor.get("role", "")) == String(story_recruit["role"]):
				index += 1
				break
	return index

func _npc_task_for_survivor(survivor: Dictionary) -> String:
	var role := String(survivor.get("role", ""))
	if ResourceManager.get_value("food") < 35 or ResourceManager.get_value("water") < 35:
		if ["Cook", "Farmer", "Quartermaster"].has(role):
			return "Cook"
		if ["Scout", "Driver", "Negotiator"].has(role):
			return "Scout"
	if ResourceManager.get_value("infection_risk") >= 18 or role == "Medic":
		return "Medical"
	if ResourceManager.get_value("security") < 55 or ResourceManager.get_value("horde_threat") >= 30:
		if ["Guard", "Scout", "Radio Operator"].has(role):
			return "Guard"
	if ["Builder", "Engineer", "Mechanic", "Fabricator", "Sign Fitter"].has(role):
		return "Build"
	if role == "Cook":
		return "Cook"
	if role == "Guard":
		return "Guard"
	if role == "Scout":
		return "Scout"
	return "Rest"
