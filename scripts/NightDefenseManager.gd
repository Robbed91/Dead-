extends Node

signal night_resolved(result: Dictionary)

const DEFENCE_TACTICS := {
	"patch_barricades": {
		"name": "Patch Barricades",
		"cost": {"materials": 8},
		"security": 4,
		"noise": 2,
		"horde_threat": 0,
		"message": "Barricades patched. Security +4, noise +2."
	},
	"ammo_traps": {
		"name": "Ammo Traps",
		"cost": {"materials": 6, "ammo": 3},
		"security": 7,
		"noise": 4,
		"horde_threat": -1,
		"message": "Ammo traps laid near the fence. Security +7, noise +4, threat -1."
	},
	"quiet_watch": {
		"name": "Quiet Watch",
		"cost": {"fuel": 2},
		"security": 1,
		"noise": -7,
		"horde_threat": -2,
		"message": "Quiet watch posted. Noise -7, threat -2, security +1."
	}
}

func get_preview() -> Dictionary:
	var attack_strength := ResourceManager.get_value("day_number") * 5 + ResourceManager.get_value("horde_threat") + ResourceManager.get_value("noise")
	var upgrade_bonus := BuildingManager.get_upgrade_defence_bonus()
	var defence_strength := ResourceManager.get_value("security") + SurvivorManager.get_guard_count() * 10 + BuildingManager.get_fortified_bonus() + upgrade_bonus
	return {
		"attack_strength": attack_strength,
		"defence_strength": defence_strength,
		"guards": SurvivorManager.get_guard_count(),
		"fortified_bonus": BuildingManager.get_fortified_bonus(),
		"upgrade_bonus": upgrade_bonus
	}

func prepare_defences(tactic_id := "patch_barricades") -> Dictionary:
	if not DEFENCE_TACTICS.has(tactic_id):
		return {"ok": false, "message": "Unknown defence tactic."}
	var tactic: Dictionary = DEFENCE_TACTICS[tactic_id]
	var cost: Dictionary = tactic["cost"]
	for key in cost.keys():
		if ResourceManager.get_value(String(key)) < int(cost[key]):
			return {"ok": false, "message": "Not enough %s for %s." % [String(key), tactic["name"]]}
	for key in cost.keys():
		ResourceManager.add_resource(String(key), -int(cost[key]))
	ResourceManager.add_resource("security", int(tactic.get("security", 0)))
	ResourceManager.add_resource("noise", int(tactic.get("noise", 0)))
	ResourceManager.add_resource("horde_threat", int(tactic.get("horde_threat", 0)))
	return {"ok": true, "message": tactic["message"], "tactic": tactic_id}

func resolve_night() -> Dictionary:
	var preview := get_preview()
	var attack_strength: int = preview["attack_strength"]
	var defence_strength: int = preview["defence_strength"]
	var success := defence_strength >= attack_strength
	var result := preview.duplicate(true)
	result["success"] = success
	if success:
		ResourceManager.add_resource("ammo", -1)
		ResourceManager.add_resource("materials", -2)
		ResourceManager.add_resource("morale", 2)
		ResourceManager.add_resource("noise", -8)
		result["message"] = "The night attack was held. Minor supplies were spent."
	else:
		var breach := attack_strength - defence_strength
		var damaged := BuildingManager.damage_random(clamp(breach, 8, 30))
		var injured := SurvivorManager.injure_random(randi_range(10, 28), 6)
		ResourceManager.add_resource("materials", -int(clamp(breach / 2, 3, 20)))
		ResourceManager.add_resource("ammo", -int(clamp(breach / 4, 2, 10)))
		ResourceManager.add_resource("morale", -8)
		ResourceManager.add_resource("infection_risk", 4)
		ResourceManager.add_resource("horde_threat", 3)
		result["damaged_building"] = damaged
		result["injured_survivor"] = injured
		result["message"] = "The barricades failed. Damage, injuries, and infection risk increased."
	night_resolved.emit(result)
	return result
