extends RefCounted

static func get_data() -> Array:
	return [
		{"name": "Tool Hire Depot", "danger": "medium", "loot": ["tools", "fuel", "materials"], "possible_survivors": true, "alarm_risk": "medium", "min_population": 1},
		{"name": "Builder's Merchant", "danger": "medium", "loot": ["materials", "tools"], "possible_survivors": true, "alarm_risk": "low", "min_population": 1},
		{"name": "Pharmacy", "danger": "high", "loot": ["medicine"], "possible_survivors": true, "alarm_risk": "medium", "min_population": 2},
		{"name": "Garage", "danger": "medium", "loot": ["fuel", "tools", "vehicle_parts"], "possible_survivors": false, "alarm_risk": "low", "min_population": 3},
		{"name": "Food Distribution Unit", "danger": "high", "loot": ["food", "water"], "possible_survivors": true, "alarm_risk": "high", "min_population": 3},
		{"name": "Self-Storage Units", "danger": "high", "loot": ["random"], "possible_survivors": true, "alarm_risk": "medium", "min_population": 4},
		{"name": "Supermarket Loading Bay", "danger": "high", "loot": ["food", "water", "medicine"], "possible_survivors": true, "alarm_risk": "high", "min_population": 5},
		{"name": "Police Checkpoint", "danger": "high", "loot": ["ammo", "medicine", "fuel"], "possible_survivors": true, "alarm_risk": "high", "min_population": 6, "required_use": "Watch Post"},
		{"name": "Canal Pump House", "danger": "medium", "loot": ["water", "fuel", "tools"], "possible_survivors": false, "alarm_risk": "medium", "min_population": 8},
		{"name": "Community Centre", "danger": "medium", "loot": ["food", "medicine", "materials"], "possible_survivors": true, "alarm_risk": "medium", "min_population": 10, "required_use": "Radio Room"},
		{"name": "Hospital Stores", "danger": "high", "loot": ["medicine", "tools"], "possible_survivors": true, "alarm_risk": "high", "min_population": 12, "required_use": "Medical Bay"},
		{"name": "Depot Fuel Yard", "danger": "high", "loot": ["fuel", "materials", "tools"], "possible_survivors": false, "alarm_risk": "high", "min_population": 15, "required_use": "Vehicle Bay"}
	]
