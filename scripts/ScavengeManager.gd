extends Node

signal scavenge_completed(result: Dictionary)

const LocationData = preload("res://data/scavenging_locations.gd")

var locations: Array = []

func _ready() -> void:
	reset()

func reset() -> void:
	locations = LocationData.get_data()

func run_scavenge(location_name: String, survivor_id: int, assign_task := true) -> Dictionary:
	var location := _find_location(location_name)
	if location.is_empty():
		return {"ok": false, "message": "Location not found."}
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

	var message := "%s scavenged: %s. Noise +%d." % [location_name, _loot_text(loot), noise]
	if injury and not injured_survivor.is_empty():
		message += " %s was injured." % injured_survivor.get("name", "Someone")
	if not recruit.is_empty():
		message += " Found survivor: %s the %s." % [recruit["name"], recruit["role"]]

	var result := {
		"ok": true,
		"location": location_name,
		"loot": loot,
		"noise": noise,
		"injury": injury,
		"infection": infection,
		"recruit": recruit,
		"message": message
	}
	scavenge_completed.emit(result)
	return result

func _roll_loot(location: Dictionary) -> Dictionary:
	var loot := {}
	var keys: Array = location["loot"]
	if keys.has("random"):
		keys = ["food", "water", "materials", "medicine", "ammo", "tools", "fuel"]
	for key in keys:
		var resource_key := "materials" if key == "vehicle_parts" else String(key)
		loot[resource_key] = randi_range(4, 16)
	return loot

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

func to_dict() -> Dictionary:
	return {"locations": locations.duplicate(true)}

func from_dict(data: Dictionary) -> void:
	locations = Array(data.get("locations", LocationData.get_data())).duplicate(true)
