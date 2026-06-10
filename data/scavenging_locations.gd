extends RefCounted

static func get_data() -> Array:
	return [
		{"name": "Tool Hire Depot", "danger": "medium", "loot": ["tools", "fuel", "materials"], "possible_survivors": true, "alarm_risk": "medium"},
		{"name": "Builder's Merchant", "danger": "medium", "loot": ["materials", "tools"], "possible_survivors": true, "alarm_risk": "low"},
		{"name": "Pharmacy", "danger": "high", "loot": ["medicine"], "possible_survivors": true, "alarm_risk": "medium"},
		{"name": "Garage", "danger": "medium", "loot": ["fuel", "tools", "vehicle_parts"], "possible_survivors": false, "alarm_risk": "low"},
		{"name": "Food Distribution Unit", "danger": "high", "loot": ["food", "water"], "possible_survivors": true, "alarm_risk": "high"},
		{"name": "Self-Storage Units", "danger": "high", "loot": ["random"], "possible_survivors": true, "alarm_risk": "medium"}
	]
