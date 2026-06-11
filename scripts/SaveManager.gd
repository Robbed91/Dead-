extends Node

const SAVE_PATH := "user://dead_shift_save.json"
const SETTINGS_PATH := "user://dead_shift_settings.json"

var settings := {
	"sound_enabled": true
}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_save_summary() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var resources := Dictionary(parsed.get("resources", {}))
	var survivors := Dictionary(parsed.get("survivors", {}))
	var roster := Array(survivors.get("survivors", []))
	var alive := roster.filter(func(s): return String(s.get("status", "Healthy")) != "Dead").size()
	return {
		"day_number": int(resources.get("day_number", 1)),
		"population": alive,
		"morale": int(resources.get("morale", 0)),
		"security": int(resources.get("security", 0))
	}

func save_game(event_log: Array) -> bool:
	var data := {
		"resources": ResourceManager.to_dict(),
		"survivors": SurvivorManager.to_dict(),
		"buildings": BuildingManager.to_dict(),
		"scavenge": ScavengeManager.to_dict(),
		"activity": ActivityManager.to_dict(),
		"event_log": event_log,
		"phase": GameManager.phase,
		"game_over_message": GameManager.game_over_message,
		"colony_tier_index": GameManager.colony_tier_index
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

func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return settings.duplicate(true)
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return settings.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in parsed.keys():
			settings[key] = parsed[key]
	return settings.duplicate(true)

func save_settings(updated: Dictionary) -> bool:
	for key in updated.keys():
		settings[key] = updated[key]
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(settings, "\t"))
	return true

func is_sound_enabled() -> bool:
	load_settings()
	return bool(settings.get("sound_enabled", true))
