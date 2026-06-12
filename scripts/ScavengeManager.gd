extends Node

signal scavenge_completed(result: Dictionary)

const LocationData = preload("res://data/scavenging_locations.gd")

var locations: Array = []

func _ready() -> void:
	reset()

func reset() -> void:
	locations = LocationData.get_data()
	_normalize_locations()

func run_scavenge(location_name: String, survivor_id: int, assign_task := true, party_ids: Array = []) -> Dictionary:
	var location := _find_location(location_name)
	var availability := _availability_for_location(location, location_name)
	if not bool(availability.get("ok", false)):
		return availability
	if party_ids.is_empty():
		party_ids = [survivor_id]
	var party_size := max(1, party_ids.size())
	if assign_task:
		for party_id in party_ids:
			SurvivorManager.assign_task(int(party_id), "Scavenge")
	var danger := _danger_value(location["danger"])
	var alarm := _alarm_value(location["alarm_risk"])
	var loot := _roll_loot(location, party_size)
	var noise := randi_range(3, 8) + alarm + max(0, party_size - 1) * 2
	var injury_roll := randi_range(1, 100)
	var infection_roll := randi_range(1, 100)
	var injury_chance: int = max(danger * 6, danger * 12 - max(0, party_size - 1) * 4)
	var infection_chance: int = max(danger * 3, danger * 5 - max(0, party_size - 1) * 2)
	var injury := injury_roll <= injury_chance
	var infection := infection_roll <= infection_chance
	var recruit := {}

	for key in loot:
		ResourceManager.add_resource(key, int(loot[key]))
	ResourceManager.add_resource("noise", noise)

	var injured_survivor := {}
	if injury:
		var injured_id := int(party_ids.pick_random())
		injured_survivor = SurvivorManager.injure_survivor(injured_id, randi_range(8, 24), 8 if infection else 0)
		ResourceManager.add_resource("morale", -2)
	if infection:
		ResourceManager.add_resource("infection_risk", 2)
	var recruit_chance := 20
	if SurvivorManager.get_population_count() <= 1:
		recruit_chance = 65
	elif SurvivorManager.get_population_count() <= 3:
		recruit_chance = 35
	recruit_chance += min(15, max(0, party_size - 1) * 5)
	if bool(location["possible_survivors"]) and randi_range(1, 100) <= recruit_chance:
		recruit = SurvivorManager.generate_recruit()
	_update_location_after_scavenge(location, danger, alarm)

	var message := "%s scavenged by %d survivor(s): %s. Noise +%d. Supplies %d%%." % [location_name, party_size, _loot_text(loot), noise, int(location.get("remaining", 0))]
	if injury and not injured_survivor.is_empty():
		message += " %s was injured." % injured_survivor.get("name", "Someone")
	if not recruit.is_empty():
		message += " Found survivor: %s the %s." % [recruit["name"], recruit["role"]]

	var result := {
		"ok": true,
		"location": location_name,
		"loot": loot,
		"noise": noise,
		"party_size": party_size,
		"party_ids": party_ids.duplicate(),
		"remaining": int(location.get("remaining", 0)),
		"injury": injury,
		"infection": infection,
		"recruit": recruit,
		"message": message
	}
	scavenge_completed.emit(result)
	return result

func can_scavenge(location_name: String) -> Dictionary:
	return _availability_for_location(_find_location(location_name), location_name)

func _roll_loot(location: Dictionary, party_size: int = 1) -> Dictionary:
	var loot := {}
	var keys: Array = location["loot"]
	if keys.has("random"):
		keys = ["food", "water", "materials", "medicine", "ammo", "tools", "fuel"]
	var remaining: float = clampf(float(location.get("remaining", 100)) / 100.0, 0.15, 1.0)
	var party_multiplier: float = 1.0 + minf(0.75, float(max(0, party_size - 1)) * 0.25)
	for key in keys:
		var resource_key: String = "materials" if key == "vehicle_parts" else String(key)
		loot[resource_key] = max(1, int(round(float(randi_range(4, 16)) * remaining * party_multiplier)))
	return loot

func advance_day() -> Array:
	var messages: Array = []
	for location in locations:
		var cooldown: int = maxi(0, int(location.get("cooldown", 0)) - 1)
		location["cooldown"] = cooldown
		if cooldown == 0 and int(location.get("remaining", 100)) < 100:
			location["remaining"] = min(100, int(location.get("remaining", 100)) + 4)
		if cooldown == 0 and bool(location.get("was_hot", false)):
			location["was_hot"] = false
			messages.append("%s has quietened down enough for another run." % location["name"])
	return messages

func _loot_text(loot: Dictionary) -> String:
	var parts: Array = []
	for key in loot.keys():
		parts.append("+%d %s" % [loot[key], key])
	return ", ".join(parts)

func _find_location(location_name: String) -> Dictionary:
	for location in locations:
		if location["name"] == location_name:
			return location
	return {}

func _danger_value(value: String) -> int:
	return {"low": 1, "medium": 2, "high": 3}.get(value, 1)

func _alarm_value(value: String) -> int:
	return {"low": 1, "medium": 5, "high": 10}.get(value, 1)

func _update_location_after_scavenge(location: Dictionary, danger: int, alarm: int) -> void:
	var depletion := randi_range(12, 22) + danger * 3
	location["remaining"] = max(0, int(location.get("remaining", 100)) - depletion)
	if alarm >= 5 or randi_range(1, 100) <= alarm * 7:
		location["cooldown"] = max(int(location.get("cooldown", 0)), 1)
		location["was_hot"] = true

func _normalize_locations() -> void:
	for location in locations:
		if not location.has("min_population"):
			location["min_population"] = 1
		if not location.has("required_use"):
			location["required_use"] = ""
		if not location.has("remaining"):
			location["remaining"] = 100
		if not location.has("cooldown"):
			location["cooldown"] = 0
		if not location.has("was_hot"):
			location["was_hot"] = false

func _availability_for_location(location: Dictionary, location_name: String) -> Dictionary:
	if location.is_empty():
		return {"ok": false, "message": "Location not found."}
	var min_population := int(location.get("min_population", 1))
	if SurvivorManager.get_population_count() < min_population:
		return {"ok": false, "message": "%s needs a larger colony: %d survivors." % [location_name, min_population]}
	var required_use := String(location.get("required_use", ""))
	if required_use != "" and BuildingManager.count_by_use(required_use) <= 0:
		return {"ok": false, "message": "%s needs an operational %s." % [location_name, required_use]}
	if int(location.get("cooldown", 0)) > 0:
		return {"ok": false, "message": "%s is too hot to enter for %d more day(s)." % [location_name, int(location["cooldown"])]}
	if int(location.get("remaining", 100)) <= 0:
		return {"ok": false, "message": "%s has been stripped clean for now." % location_name}
	return {"ok": true, "message": "Location available."}

func to_dict() -> Dictionary:
	return {"locations": locations.duplicate(true)}

func from_dict(data: Dictionary) -> void:
	locations = Array(data.get("locations", LocationData.get_data())).duplicate(true)
	_normalize_locations()
