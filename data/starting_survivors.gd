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
		},
		{
			"id": 2,
			"name": "Jess",
			"role": "Medic",
			"health": 100,
			"morale": 85,
			"loyalty": 80,
			"infection_risk": 0,
			"assigned_task": "Medical",
			"assigned_building": "Main Warehouse",
			"status": "Healthy",
			"traits": ["Medical", "Calm", "Careful"]
		},
		{
			"id": 3,
			"name": "Aaron",
			"role": "Guard",
			"health": 100,
			"morale": 70,
			"loyalty": 65,
			"infection_risk": 0,
			"assigned_task": "Guard",
			"assigned_building": "Main Warehouse",
			"status": "Healthy",
			"traits": ["Combat", "Alert", "Suspicious"]
		},
		{
			"id": 4,
			"name": "Karen",
			"role": "Cook",
			"health": 100,
			"morale": 75,
			"loyalty": 70,
			"infection_risk": 0,
			"assigned_task": "Cook",
			"assigned_building": "Main Warehouse",
			"status": "Healthy",
			"traits": ["Food Prep", "Organised", "Anxious"]
		},
		{
			"id": 5,
			"name": "Mick",
			"role": "Builder",
			"health": 100,
			"morale": 78,
			"loyalty": 72,
			"infection_risk": 0,
			"assigned_task": "Build",
			"assigned_building": "Main Warehouse",
			"status": "Healthy",
			"traits": ["Repairs", "Heavy Lifting", "Noisy"]
		}
	]
