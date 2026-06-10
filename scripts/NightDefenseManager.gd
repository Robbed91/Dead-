extends Node

signal night_resolved(result: Dictionary)

func get_preview() -> Dictionary:
	var attack_strength := ResourceManager.get_value("day_number") * 5 + ResourceManager.get_value("horde_threat") + ResourceManager.get_value("noise")
	var defence_strength := ResourceManager.get_value("security") + SurvivorManager.get_guard_count() * 10 + BuildingManager.get_fortified_bonus()
	return {
		"attack_strength": attack_strength,
		"defence_strength": defence_strength,
		"guards": SurvivorManager.get_guard_count(),
		"fortified_bonus": BuildingManager.get_fortified_bonus()
	}

func prepare_defences() -> Dictionary:
	var repaired := ResourceManager.spend_resource("materials", 8)
	if repaired:
		ResourceManager.add_resource("security", 4)
		ResourceManager.add_resource("noise", 2)
		return {"ok": true, "message": "Barricades patched. Security +4, noise +2."}
	return {"ok": false, "message": "Not enough materials to prepare defences."}

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
