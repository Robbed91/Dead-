extends Node

signal resources_changed

const CAPPED_VALUES := {
	"power": 100,
	"morale": 100,
	"security": 100,
	"infection_risk": 100,
	"noise": 100,
	"horde_threat": 100,
}

var resources: Dictionary = {}

func _ready() -> void:
	reset()

func reset() -> void:
	resources = {
		"food": 80,
		"water": 70,
		"fuel": 30,
		"power": 50,
		"materials": 100,
		"medicine": 15,
		"ammo": 25,
		"tools": 10,
		"morale": 75,
		"security": 30,
		"infection_risk": 5,
		"noise": 4,
		"horde_threat": 0,
		"beds": 2,
		"population": 1,
		"day_number": 1
	}
	resources_changed.emit()

func get_value(key: String) -> int:
	return int(resources.get(key, 0))

func set_value(key: String, value: int) -> void:
	resources[key] = clamp(value, 0, int(CAPPED_VALUES.get(key, 9999)))
	resources_changed.emit()

func add_resource(key: String, amount: int) -> void:
	set_value(key, get_value(key) + amount)

func spend_resource(key: String, amount: int) -> bool:
	if get_value(key) < amount:
		return false
	add_resource(key, -amount)
	return true

func apply_daily_consumption(population: int) -> Dictionary:
	var food_needed := population * 2
	var water_needed := population * 2
	var shortage := 0
	var bed_shortage := max(0, population - get_value("beds"))
	if get_value("food") < food_needed:
		shortage += food_needed - get_value("food")
	if get_value("water") < water_needed:
		shortage += water_needed - get_value("water")
	add_resource("food", -food_needed)
	add_resource("water", -water_needed)
	if population >= 8:
		add_resource("fuel", -1)
	if population >= 15:
		add_resource("power", -1)
	add_resource("noise", -5)
	add_resource("horde_threat", 2 + int(floor(float(population) / 8.0)))
	if shortage > 0:
		add_resource("morale", -shortage * 2)
		add_resource("infection_risk", 1)
	else:
		add_resource("morale", 1)
	if bed_shortage > 0:
		add_resource("morale", -bed_shortage)
		add_resource("infection_risk", 1)
	return {"food_needed": food_needed, "water_needed": water_needed, "shortage": shortage, "bed_shortage": bed_shortage}

func advance_day() -> void:
	add_resource("day_number", 1)

func to_dict() -> Dictionary:
	return resources.duplicate(true)

func from_dict(data: Dictionary) -> void:
	resources = data.duplicate(true)
	resources_changed.emit()
