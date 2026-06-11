extends RefCounted

static func get_data() -> Array:
	return [
		{
			"id": 1,
			"name": "Billy",
			"role": "Sign Fitter",
			"health": 100,
			"morale": 80,
			"loyalty": 75,
			"infection_risk": 0,
			"assigned_task": "Rest",
			"assigned_building": "Main Warehouse",
			"status": "Healthy",
			"traits": ["Builder", "Practical", "Good With Fixings"]
		}
	]
