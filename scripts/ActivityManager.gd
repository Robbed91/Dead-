extends Node

signal activity_changed
signal job_completed(survivor_id: int, task: String, message: String)

const TASK_DURATIONS := {
	"Rest": 10.0,
	"Guard": 14.0,
	"Build": 16.0,
	"Repair": 15.0,
	"Scavenge": 18.0,
	"Medical": 14.0,
	"Cook": 12.0,
	"Scout": 16.0,
}

var active_jobs: Dictionary = {}
var update_accumulator := 0.0
var next_expedition_id := 1

func _process(delta: float) -> void:
	if active_jobs.is_empty():
		return
	update_accumulator += delta
	var completed: Array = []
	for survivor_id in active_jobs.keys():
		var job: Dictionary = active_jobs[survivor_id]
		job["progress"] = float(job.get("progress", 0.0)) + delta
		active_jobs[survivor_id] = job
		if float(job["progress"]) >= float(job["duration"]):
			completed.append(int(survivor_id))
	for survivor_id in completed:
		_complete_job(survivor_id)
	if not completed.is_empty() or update_accumulator >= 0.5:
		update_accumulator = 0.0
		activity_changed.emit()

func reset() -> void:
	active_jobs = {}
	next_expedition_id = 1
	for survivor in SurvivorManager.get_available_scavengers():
		start_task(int(survivor["id"]), String(survivor.get("assigned_task", "Rest")))
	activity_changed.emit()

func start_task(survivor_id: int, task: String) -> void:
	if not SurvivorManager.TASKS.has(task):
		task = "Rest"
	active_jobs[survivor_id] = {
		"task": task,
		"progress": 0.0,
		"duration": float(TASK_DURATIONS.get(task, 12.0)),
		"target": _target_for_task(task),
	}
	activity_changed.emit()

func start_scavenge(survivor_id: int, location_name: String) -> void:
	start_scavenge_party([survivor_id], location_name)

func start_scavenge_party(party_ids: Array, location_name: String) -> void:
	if party_ids.is_empty():
		return
	var expedition_id := next_expedition_id
	next_expedition_id += 1
	var duration := float(TASK_DURATIONS.get("Scavenge", 18.0)) + randf_range(0.0, 6.0)
	for raw_id in party_ids:
		var survivor_id := int(raw_id)
		active_jobs[survivor_id] = {
			"task": "Scavenge",
			"progress": 0.0,
			"duration": duration,
			"target": "Garage",
			"location": location_name,
			"expedition_id": expedition_id,
			"party_ids": party_ids.duplicate(),
		}
		SurvivorManager.assign_task(survivor_id, "Scavenge")
	activity_changed.emit()

func get_job(survivor_id: int) -> Dictionary:
	return Dictionary(active_jobs.get(survivor_id, {}))

func get_progress(survivor_id: int) -> float:
	var job := get_job(survivor_id)
	if job.is_empty():
		return 0.0
	return clamp(float(job.get("progress", 0.0)) / max(0.1, float(job.get("duration", 1.0))), 0.0, 1.0)

func get_target(survivor_id: int) -> String:
	var job := get_job(survivor_id)
	return String(job.get("target", "Main Warehouse"))

func to_dict() -> Dictionary:
	return {"active_jobs": active_jobs.duplicate(true), "next_expedition_id": next_expedition_id}

func from_dict(data: Dictionary) -> void:
	active_jobs = {}
	next_expedition_id = int(data.get("next_expedition_id", 1))
	var loaded := Dictionary(data.get("active_jobs", {}))
	for key in loaded.keys():
		active_jobs[int(key)] = Dictionary(loaded[key]).duplicate(true)
	for survivor in SurvivorManager.get_available_scavengers():
		var id := int(survivor["id"])
		if not active_jobs.has(id):
			start_task(id, String(survivor.get("assigned_task", "Rest")))
	activity_changed.emit()

func _complete_job(survivor_id: int) -> void:
	var job := get_job(survivor_id)
	if job.is_empty():
		return
	var task := String(job.get("task", "Rest"))
	var message := _apply_reward(survivor_id, task)
	if task == "Scavenge" and String(job.get("location", "")) != "":
		var party_ids := Array(job.get("party_ids", [survivor_id]))
		for raw_id in party_ids:
			var party_id := int(raw_id)
			active_jobs.erase(party_id)
			SurvivorManager.assign_task(party_id, "Rest")
			start_task(party_id, "Rest")
		job_completed.emit(survivor_id, task, message)
		return
	job["progress"] = 0.0
	job["duration"] = float(TASK_DURATIONS.get(task, 12.0)) + randf_range(-2.0, 2.0)
	active_jobs[survivor_id] = job
	job_completed.emit(survivor_id, task, message)

func _apply_reward(survivor_id: int, task: String) -> String:
	var survivor_name := SurvivorManager.get_survivor_name(survivor_id)
	var job := get_job(survivor_id)
	match task:
		"Rest":
			SurvivorManager.heal_survivor(survivor_id, 4)
			return "%s rested and recovered health." % survivor_name
		"Guard":
			ResourceManager.add_resource("security", 1)
			ResourceManager.add_resource("horde_threat", -1)
			return "%s patrolled the perimeter." % survivor_name
		"Build":
			ResourceManager.add_resource("materials", 1)
			ResourceManager.add_resource("noise", 1)
			return "%s fabricated useful fittings." % survivor_name
		"Repair":
			var building := BuildingManager.repair_lowest_condition(5)
			return "%s repaired %s." % [survivor_name, building.get("name", "the base")]
		"Scavenge":
			var location := String(job.get("location", ""))
			if location != "":
				var party_ids := Array(job.get("party_ids", [survivor_id]))
				var result := ScavengeManager.run_scavenge(location, survivor_id, false, party_ids)
				return "%s's party returned from %s. %s" % [survivor_name, location, result.get("message", "Scavenge complete.")]
			ResourceManager.add_resource("materials", randi_range(1, 4))
			ResourceManager.add_resource("noise", 1)
			return "%s hauled in useful salvage." % survivor_name
		"Medical":
			SurvivorManager.treat_worst_survivor(5, 2)
			return "%s treated injuries and infection risk." % survivor_name
		"Cook":
			ResourceManager.add_resource("food", 1)
			ResourceManager.add_resource("morale", 1)
			return "%s stretched rations for the colony." % survivor_name
		"Scout":
			ResourceManager.add_resource("horde_threat", -2)
			ResourceManager.add_resource("noise", 1)
			return "%s mapped horde movement." % survivor_name
	return "%s completed %s." % [survivor_name, task]

func _target_for_task(task: String) -> String:
	match task:
		"Guard":
			return "Security Office"
		"Build", "Repair":
			return "Signage Workshop"
		"Scavenge", "Scout":
			return "Garage"
		"Medical":
			return "Pharmacy"
		"Cook":
			return "Food Distribution Unit"
	return "Main Warehouse"
