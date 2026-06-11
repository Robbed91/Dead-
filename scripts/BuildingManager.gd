extends Node

signal buildings_changed

const StartingBuildings = preload("res://data/starting_buildings.gd")
const USES := ["Storage", "Sleeping Quarters", "Workshop", "Medical Bay", "Radio Room", "Quarantine", "Watch Post", "Food Prep", "Vehicle Bay", "Training Room"]
const UPGRADES := {
	"barricade_kit": {
		"name": "Barricade Kit",
		"cost": {"materials": 20, "tools": 1},
		"security": 10,
		"condition": 5,
		"defence_bonus": 8,
		"description": "Permanent building security and night defence."
	},
	"floodlights": {
		"name": "Floodlights",
		"cost": {"materials": 16, "tools": 2, "fuel": 2},
		"security": 6,
		"condition": 0,
		"defence_bonus": 6,
		"description": "Improves guard visibility and lowers horde pressure."
	},
	"rain_catchers": {
		"name": "Rain Catchers",
		"cost": {"materials": 14, "tools": 1},
		"security": 0,
		"condition": 0,
		"defence_bonus": 0,
		"description": "Generates water at end of day."
	},
	"workshop_bench": {
		"name": "Workshop Bench",
		"cost": {"materials": 18, "tools": 2},
		"security": 0,
		"condition": 5,
		"defence_bonus": 0,
		"description": "Improves material production when staffed."
	},
	"spike_traps": {
		"name": "Spike Traps",
		"cost": {"materials": 24, "tools": 2, "ammo": 2},
		"security": 4,
		"condition": 0,
		"defence_bonus": 12,
		"description": "Strong night defence bonus."
	}
}

var buildings: Array = []

func _ready() -> void:
	reset()

func reset() -> void:
	buildings = StartingBuildings.get_data()
	buildings_changed.emit()

func get_fortified_bonus() -> int:
	var bonus := 0
	for building in buildings:
		if building.get("status", "") == "Fortified":
			bonus += 15
		elif building.get("status", "") == "Operational":
			bonus += int(int(building.get("security", 0)) / 5)
	return bonus

func get_upgrade_defence_bonus() -> int:
	var bonus := 0
	for building in buildings:
		if not ["Claimed", "Operational", "Fortified"].has(String(building.get("status", ""))):
			continue
		for upgrade_id in Array(building.get("upgrades", [])):
			bonus += int(UPGRADES.get(String(upgrade_id), {}).get("defence_bonus", 0))
	return bonus

func apply_use_bonuses() -> Array:
	var messages: Array = []
	for building in buildings:
		if not ["Claimed", "Operational", "Fortified"].has(building.get("status", "")):
			continue
		match building.get("current_use", "None"):
			"Sleeping Quarters":
				ResourceManager.set_value("beds", max(ResourceManager.get_value("beds"), 6 + int(building.get("capacity", 0))))
			"Watch Post":
				ResourceManager.add_resource("security", 2)
				messages.append("%s watch post improved perimeter security." % building["name"])
			"Medical Bay":
				ResourceManager.add_resource("infection_risk", -2)
				messages.append("%s medical bay reduced infection risk." % building["name"])
			"Food Prep":
				ResourceManager.add_resource("morale", 1)
			"Workshop":
				ResourceManager.add_resource("materials", 2)
			"Storage":
				ResourceManager.add_resource("materials", 1)
			"Radio Room":
				ResourceManager.add_resource("horde_threat", -1)
			"Quarantine":
				ResourceManager.add_resource("infection_risk", -1)
		for upgrade_id in Array(building.get("upgrades", [])):
			match String(upgrade_id):
				"rain_catchers":
					ResourceManager.add_resource("water", 3)
					messages.append("%s rain catchers collected +3 water." % building["name"])
				"workshop_bench":
					if String(building.get("current_use", "")) == "Workshop":
						ResourceManager.add_resource("materials", 3)
						messages.append("%s workshop bench produced +3 materials." % building["name"])
				"floodlights":
					if ResourceManager.get_value("power") > 0:
						ResourceManager.add_resource("power", -1)
						ResourceManager.add_resource("horde_threat", -1)
						messages.append("%s floodlights kept the perimeter visible." % building["name"])
	return messages

func assign_use(id: int, use_name: String) -> Dictionary:
	var building := _find_building(id)
	if building.is_empty():
		return {"ok": false, "message": "Building not found."}
	if not USES.has(use_name):
		return {"ok": false, "message": "Unknown building use."}
	if not ["Claimed", "Operational", "Fortified"].has(building.get("status", "")):
		return {"ok": false, "message": "%s must be claimed before assigning a use." % building["name"]}
	building["current_use"] = use_name
	if building["status"] == "Claimed":
		building["status"] = "Operational"
	_emit()
	return {"ok": true, "message": "%s set to %s." % [building["name"], use_name]}

func assign_survivor(id: int, survivor_id: int) -> Dictionary:
	var building := _find_building(id)
	if building.is_empty():
		return {"ok": false, "message": "Building not found."}
	if not ["Claimed", "Operational", "Fortified"].has(building.get("status", "")):
		return {"ok": false, "message": "%s must be claimed before assigning survivors." % building["name"]}
	var assigned := Array(building.get("assigned_survivors", []))
	if assigned.size() >= int(building.get("capacity", 0)):
		return {"ok": false, "message": "%s is at capacity." % building["name"]}
	if not assigned.has(survivor_id):
		assigned.append(survivor_id)
	building["assigned_survivors"] = assigned
	SurvivorManager.assign_building(survivor_id, String(building["name"]))
	_emit()
	return {"ok": true, "message": "%s assigned to %s." % [SurvivorManager.get_survivor_name(survivor_id), building["name"]]}

func perform_action(id: int, action: String) -> Dictionary:
	var building := _find_building(id)
	if building.is_empty():
		return {"ok": false, "message": "Building not found."}
	match action:
		"Scout":
			if building["status"] == "Unknown":
				building["status"] = "Scouted"
				ResourceManager.add_resource("noise", 2)
				_emit()
				return {"ok": true, "message": "%s has been scouted." % building["name"]}
		"Clear":
			if ["Scouted", "Infested"].has(building["status"]):
				building["infestation"] = max(0, int(building["infestation"]) - 25)
				ResourceManager.add_resource("ammo", -2)
				ResourceManager.add_resource("noise", 6)
				if int(building["infestation"]) <= 0:
					building["status"] = "Cleared"
				else:
					building["status"] = "Infested"
				_emit()
				return {"ok": true, "message": "%s clearing reduced infestation." % building["name"]}
		"Claim":
			if building["status"] == "Cleared":
				building["status"] = "Claimed"
				ResourceManager.add_resource("security", int(int(building["security"]) / 4))
				if building["type"] == "Living":
					ResourceManager.add_resource("beds", int(building["capacity"]))
				_emit()
				return {"ok": true, "message": "%s is now claimed." % building["name"]}
		"Repair":
			if ["Claimed", "Operational", "Fortified"].has(building["status"]) and ResourceManager.spend_resource("materials", 10):
				building["condition"] = min(100, int(building["condition"]) + 15)
				building["status"] = "Operational"
				_emit()
				return {"ok": true, "message": "%s repaired." % building["name"]}
		"Fortify":
			if ["Claimed", "Operational"].has(building["status"]) and ResourceManager.spend_resource("materials", 15):
				building["security"] = min(100, int(building["security"]) + 15)
				building["status"] = "Fortified"
				ResourceManager.add_resource("security", 5)
				_emit()
				return {"ok": true, "message": "%s fortified." % building["name"]}
	return {"ok": false, "message": "%s cannot be used on %s right now." % [action, building["name"]]}

func install_upgrade(id: int, upgrade_id: String) -> Dictionary:
	var building := _find_building(id)
	if building.is_empty():
		return {"ok": false, "message": "Building not found."}
	if not UPGRADES.has(upgrade_id):
		return {"ok": false, "message": "Unknown upgrade."}
	if not ["Claimed", "Operational", "Fortified"].has(String(building.get("status", ""))):
		return {"ok": false, "message": "%s must be claimed before installing upgrades." % building["name"]}
	var upgrades := Array(building.get("upgrades", []))
	if upgrades.has(upgrade_id):
		return {"ok": false, "message": "%s already has %s." % [building["name"], UPGRADES[upgrade_id]["name"]]}
	var cost: Dictionary = UPGRADES[upgrade_id]["cost"]
	for key in cost.keys():
		if ResourceManager.get_value(String(key)) < int(cost[key]):
			return {"ok": false, "message": "Not enough %s for %s." % [String(key), UPGRADES[upgrade_id]["name"]]}
	for key in cost.keys():
		ResourceManager.add_resource(String(key), -int(cost[key]))
	building["security"] = min(100, int(building.get("security", 0)) + int(UPGRADES[upgrade_id].get("security", 0)))
	building["condition"] = min(100, int(building.get("condition", 0)) + int(UPGRADES[upgrade_id].get("condition", 0)))
	upgrades.append(upgrade_id)
	building["upgrades"] = upgrades
	if building["status"] == "Claimed":
		building["status"] = "Operational"
	_emit()
	return {"ok": true, "message": "%s installed at %s." % [UPGRADES[upgrade_id]["name"], building["name"]]}

func get_upgrade_name(upgrade_id: String) -> String:
	return String(UPGRADES.get(upgrade_id, {}).get("name", upgrade_id))

func damage_random(amount: int) -> Dictionary:
	var targets := buildings.filter(func(b): return ["Operational", "Fortified", "Claimed"].has(b.get("status", "")))
	if targets.is_empty():
		return {}
	var building: Dictionary = targets.pick_random()
	building["condition"] = max(0, int(building["condition"]) - amount)
	if int(building["condition"]) <= 0:
		building["status"] = "Lost"
	_emit()
	return building

func repair_lowest_condition(amount: int) -> Dictionary:
	var target := {}
	for building in buildings:
		if ["Lost", "Unknown"].has(String(building.get("status", ""))):
			continue
		if target.is_empty() or int(building.get("condition", 100)) < int(target.get("condition", 100)):
			target = building
	if target.is_empty():
		return {}
	target["condition"] = min(100, int(target.get("condition", 0)) + amount)
	if String(target.get("status", "")) == "Cleared":
		target["status"] = "Claimed"
	_emit()
	return target

func count_by_status(status: String) -> int:
	var total := 0
	for building in buildings:
		if String(building.get("status", "")) == status:
			total += 1
	return total

func count_survivable_buildings() -> int:
	var total := 0
	for building in buildings:
		if ["Claimed", "Operational", "Fortified"].has(String(building.get("status", ""))):
			total += 1
	return total

func _find_building(id: int) -> Dictionary:
	for building in buildings:
		if int(building["id"]) == id:
			return building
	return {}

func _emit() -> void:
	buildings_changed.emit()
	ResourceManager.resources_changed.emit()

func to_dict() -> Dictionary:
	return {"buildings": buildings.duplicate(true)}

func from_dict(data: Dictionary) -> void:
	buildings = Array(data.get("buildings", [])).duplicate(true)
	buildings_changed.emit()
