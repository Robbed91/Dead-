extends Node

const SAVE_PATH := "user://dead_shift_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(event_log: Array) -> bool:
	var data := {
		"resources": ResourceManager.to_dict(),
		"survivors": SurvivorManager.to_dict(),
		"buildings": BuildingManager.to_dict(),
		"scavenge": ScavengeManager.to_dict(),
		"activity": ActivityManager.to_dict(),
		"event_log": event_log,
		"phase": GameManager.phase,
		"game_over_message": GameManager.game_over_message
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

func load_game() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	ResourceManager.from_dict(parsed.get("resources", {}))
	SurvivorManager.from_dict(parsed.get("survivors", {}))
	BuildingManager.from_dict(parsed.get("buildings", {}))
	ScavengeManager.from_dict(parsed.get("scavenge", {}))
	ActivityManager.from_dict(parsed.get("activity", {}))
	return parsed

func reset_save() -> void:
	if has_save():
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove("dead_shift_save.json")
