extends SceneTree

const SAVE_PATH := "user://dead_shift_save.json"
const SETTINGS_PATH := "user://dead_shift_settings.json"

var failures: Array = []
var had_save := false
var save_backup := ""
var had_settings := false
var settings_backup := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	_backup_save()
	GameManager.new_game()
	_assert_eq(ResourceManager.get_value("day_number"), 1, "new game starts on day 1")
	_assert_eq(SurvivorManager.survivors.size(), 1, "new game starts with Billy alone")
	_assert_eq(ResourceManager.get_value("population"), 1, "starting population is one")
	_assert_eq(SurvivorManager.get_crew_count(), 1, "Billy starts as direct crew")
	_assert_eq(String(GameManager.get_colony_tier().get("name", "")), "Hideout", "starting tier is hideout")
	_assert_true(BuildingManager.buildings.size() >= 9, "starting buildings loaded")
	var locked_garage := GameManager.building_action(5, "Scout")
	_assert_true(not bool(locked_garage.get("ok", false)), "garage starts locked until the colony has suitable people")

	var scout_result := GameManager.building_action(2, "Scout")
	_assert_true(bool(scout_result.get("ok", false)), "can scout unknown Signage Workshop")
	var clear_result := GameManager.building_action(2, "Clear")
	_assert_true(bool(clear_result.get("ok", false)), "can clear scouted Signage Workshop")
	var claim_result := GameManager.building_action(2, "Claim")
	_assert_true(bool(claim_result.get("ok", false)), "can claim cleared Signage Workshop")
	var use_result := GameManager.assign_building_use(2, "Workshop")
	_assert_true(bool(use_result.get("ok", false)), "can set claimed building use")
	var upgrade_result := GameManager.install_building_upgrade(2, "workshop_bench")
	_assert_true(bool(upgrade_result.get("ok", false)), "can install a persistent building upgrade")
	_assert_true(BuildingManager.get_upgrade_defence_bonus() >= 0, "upgrade defence bonus can be queried")

	GameManager.assign_survivor_task(1, "Guard")
	_assert_eq(ActivityManager.get_job(1).get("task", ""), "Guard", "survivor task starts tracked activity")

	var scavenge_start := GameManager.scavenge("Tool Hire Depot", 1)
	_assert_true(bool(scavenge_start.get("ok", false)), "can start timed scavenging")
	_assert_eq(ActivityManager.get_job(1).get("location", ""), "Tool Hire Depot", "scavenging job stores target location")
	ActivityManager.call("_complete_job", 1)
	_assert_eq(String(SurvivorManager.survivors[0].get("assigned_task", "")), "Rest", "scavenger returns to rest after completing expedition")
	var depot := _location("Tool Hire Depot")
	_assert_true(int(depot.get("remaining", 100)) < 100, "scavenging depletes location supplies")
	_assert_true(depot.has("cooldown"), "scavenge location tracks cooldown")
	var depot_remaining_after_scavenge := int(depot.get("remaining", 0))

	var recruit := SurvivorManager.generate_recruit()
	SurvivorManager.invite_recruit(recruit)
	_assert_eq(SurvivorManager.get_npc_count(), 1, "new recruits join as NPC residents")
	var new_survivor_id := int(SurvivorManager.survivors[1]["id"])
	var npc_order := GameManager.scavenge("Builder's Merchant", new_survivor_id)
	_assert_true(not bool(npc_order.get("ok", false)), "NPC residents cannot be sent scavenging directly")
	var crew_result := GameManager.set_survivor_control_mode(new_survivor_id, "Crew")
	_assert_true(bool(crew_result.get("ok", false)), "NPC survivor can be added to direct crew within limit")
	_assert_eq(SurvivorManager.get_crew_count(), 2, "crew count increases after promotion")
	_assert_eq(String(GameManager.get_colony_tier().get("name", "")), "Camp", "two survivors unlock camp tier")

	var preview := NightDefenseManager.get_preview()
	_assert_true(int(preview.get("attack_strength", 0)) >= 0, "night attack preview calculates attack")
	_assert_true(int(preview.get("defence_strength", 0)) > 0, "night attack preview calculates defence")
	var noise_before_tactic := ResourceManager.get_value("noise")
	var tactic := GameManager.prepare_defences("quiet_watch")
	_assert_true(bool(tactic.get("ok", false)), "can prepare a named defence tactic")
	_assert_true(ResourceManager.get_value("noise") < noise_before_tactic, "quiet watch reduces noise")

	var billy: Dictionary = SurvivorManager.survivors[0]
	billy["health"] = 64
	billy["infection_risk"] = 58
	billy["status"] = "At Risk"
	GameManager.assign_survivor_task(1, "Medical")
	var condition_messages := SurvivorManager.apply_condition_progression()
	_assert_true(not condition_messages.is_empty(), "condition progression creates medical/quarantine feedback")
	_assert_true(int(billy["health"]) > 64 or int(billy["infection_risk"]) < 60, "medical progression changes survivor condition")
	_assert_eq(ResourceManager.get_value("population"), SurvivorManager.get_population_count(), "population matches living survivors")

	var food_before_save := ResourceManager.get_value("food")
	_assert_true(SaveManager.save_game(GameManager.event_log), "save file can be written")
	var summary := SaveManager.get_save_summary()
	_assert_eq(int(summary.get("day_number", 0)), ResourceManager.get_value("day_number"), "save summary reports current day")
	_assert_true(SaveManager.save_settings({"sound_enabled": false}), "settings file can be written")
	_assert_true(not SaveManager.is_sound_enabled(), "sound setting persists false value")
	_assert_true(SaveManager.save_settings({"sound_enabled": true}), "settings can be changed back")
	_assert_true(SaveManager.is_sound_enabled(), "sound setting persists true value")
	ResourceManager.set_value("food", 1)
	var loaded := SaveManager.load_game()
	_assert_true(not loaded.is_empty(), "save file can be loaded")
	_assert_eq(ResourceManager.get_value("food"), food_before_save, "saved resources restore correctly")

	var day_before := ResourceManager.get_value("day_number")
	var night_result := GameManager.end_day()
	_assert_eq(ResourceManager.get_value("day_number"), day_before + 1, "end day advances the day")
	_assert_true(Array(night_result.get("daily_report", [])).size() > 0, "end day returns a report")
	_assert_true(int(_location("Tool Hire Depot").get("remaining", 0)) >= depot_remaining_after_scavenge, "locations recover or remain stable after day advances")

	if failures.is_empty():
		print("Dead Shift smoke test passed.")
		_restore_save()
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		_restore_save()
		quit(1)

func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])

func _backup_save() -> void:
	had_save = FileAccess.file_exists(SAVE_PATH)
	if not had_save:
		save_backup = ""
	else:
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			save_backup = file.get_as_text()
	had_settings = FileAccess.file_exists(SETTINGS_PATH)
	if had_settings:
		var settings_file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if settings_file != null:
			settings_backup = settings_file.get_as_text()

func _restore_save() -> void:
	if had_save:
		var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(save_backup)
	elif FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove("dead_shift_save.json")
	if had_settings:
		var settings_file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if settings_file != null:
			settings_file.store_string(settings_backup)
	elif FileAccess.file_exists(SETTINGS_PATH):
		var dir_settings := DirAccess.open("user://")
		if dir_settings != null:
			dir_settings.remove("dead_shift_settings.json")

func _location(location_name: String) -> Dictionary:
	for location in ScavengeManager.locations:
		if String(location.get("name", "")) == location_name:
			return location
	return {}
