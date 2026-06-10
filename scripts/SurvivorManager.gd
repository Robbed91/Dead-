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

func injure_random(amount: int, infection_added: int) -> Dictionary:
	var alive := get_available_scavengers()
	if alive.is_empty():
		return {}
	var survivor: Dictionary = alive.pick_random()
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
