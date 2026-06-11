extends Node

signal survivors_changed

const StartingSurvivors = preload("res://data/starting_survivors.gd")
const TASKS := ["Rest", "Guard", "Build", "Repair", "Scavenge", "Medical", "Cook", "Scout"]
const RECRUIT_ROLES := ["Builder", "Medic", "Mechanic", "Cook", "Scout", "Guard", "Engineer", "Farmer", "Teacher", "Negotiator", "Quartermaster", "Radio Operator", "Driver", "Fabricator"]
const FIRST_NAMES := ["Nina", "Raj", "Leanne", "Tom", "Sofia", "Gareth", "Priya", "Dylan", "Mo", "Hannah", "Callum", "Aisha"]
const TRAITS := ["Steady", "Quick Learner", "Tired", "Brave", "Practical", "Quiet", "Resourceful", "Nervous", "Methodical"]

var survivors: Array = []
var next_id := 1

func _ready() -> void:
	reset()

func reset() -> void:
	survivors = StartingSurvivors.get_data()
	next_id = 1
	for survivor in survivors:
		next_id = max(next_id, int(survivor["id"]) + 1)
	survivors_changed.emit()

func assign_task(id: int, task: String) -> void:
	for survivor in survivors:
		if int(survivor["id"]) == id and TASKS.has(task):
			survivor["assigned_task"] = task
			survivors_changed.emit()
			return

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
		"status": "Waiting",
		"traits": [TRAITS.pick_random(), TRAITS.pick_random()]
	}

func invite_recruit(recruit: Dictionary) -> void:
	var survivor := recruit.duplicate(true)
	survivor["id"] = next_id
	survivor["status"] = "Healthy"
	next_id += 1
	survivors.append(survivor)
	ResourceManager.set_value("population", survivors.size())
	ResourceManager.add_resource("morale", 3)
	survivors_changed.emit()

func quarantine_recruit(_recruit: Dictionary) -> void:
	ResourceManager.add_resource("morale", -2)
	ResourceManager.add_resource("infection_risk", -3)

func reject_recruit(_recruit: Dictionary) -> void:
	ResourceManager.add_resource("morale", -1)

func to_dict() -> Dictionary:
	return {"survivors": survivors.duplicate(true), "next_id": next_id}

func from_dict(data: Dictionary) -> void:
	survivors = Array(data.get("survivors", [])).duplicate(true)
	next_id = int(data.get("next_id", survivors.size() + 1))
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
