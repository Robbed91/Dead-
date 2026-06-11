extends Node

signal scavenge_completed(result: Dictionary)

const LocationData = preload("res://data/scavenging_locations.gd")

var locations: Array = []

func _ready() -> void:
	reset()

func reset() -> void:
	locations = LocationData.get_data()
	_normalize_locations()

func run_scavenge(location_name: String, survivor_id: int, assign_task := true) -> Dictionary:
	var location := _find_location(location_name)
	var availability := _availability_for_location(location, location_name)
	if not bool(availability.get("ok", false)):
		return availability
	if assign_task:
		SurvivorManager.assign_task(survivor_id, "Scavenge")
	var danger := _danger_value(location["danger"])
	var alarm := _alarm_value(location["alarm_risk"])
	var loot := _roll_loot(location)
	var noise := randi_range(3, 8) + alarm
	var injury_roll := randi_range(1, 100)
	var infection_roll := randi_range(1, 100)
	var injury := injury_roll <= danger * 12
	var infection := infection_roll <= danger * 5
	var recruit := {}

	for key in loot:
		ResourceManager.add_resource(key, int(loot[key]))
	ResourceManager.add_resource("noise", noise)

	var injured_survivor := {}
	if injury:
		injured_survivor = SurvivorManager.injure_survivor(survivor_id, randi_range(8, 24), 8 if infection else 0)
		ResourceManager.add_resource("morale", -2)
	if infection:
		ResourceManager.add_resource("infection_risk", 2)
	if bool(location["possible_survivors"]) and randi_range(1, 100) <= 20:
		recruit = SurvivorManager.generate_recruit()
	_update_location_after_scavenge(location, danger, alarm)

	var message := "%s scavenged: %s. Noise +%d. Supplies %d%%." % [location_name, _loot_text(loot), noise, int(location.get("remaining", 0))]
	if injury and not injured_survivor.is_empty():
		message += " %s was injured." % injured_survivor.get("name", "Someone")
	if not recruit.is_empty():
		message += " Found survivor: %s the %s." % [recruit["name"], recruit["role"]]

	var result := {
		"ok": true,
		"location": location_name,
		"loot": loot,
		"noise": noise,
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

func _roll_loot(location: Dictionary) -> Dictionary:
	var loot := {}
	var keys: Array = location["loot"]
	if keys.has("random"):
		keys = ["food", "water", "materials", "medicine", "ammo", "tools", "fuel"]
	var remaining := clamp(float(location.get("remaining", 100)) / 100.0, 0.15, 1.0)
	for key in keys:
		var resource_key := "materials" if key == "vehicle_parts" else String(key)
		loot[resource_key] = max(1, int(round(float(randi_range(4, 16)) * remaining)))
	return loot

func advance_day() -> Array:
	var messages: Array = []
	for location in locations:
		var cooldown := max(0, int(location.get("cooldown", 0)) - 1)
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
		if not location.has("remaining"):
			location["remaining"] = 100
		if not location.has("cooldown"):
			location["cooldown"] = 0
		if not location.has("was_hot"):
			location["was_hot"] = false

func _availability_for_location(location: Dictionary, location_name: String) -> Dictionary:
	if location.is_empty():
		return {"ok": false, "message": "Location not found."}
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
