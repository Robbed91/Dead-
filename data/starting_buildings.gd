extends RefCounted

static func get_data() -> Array:
	return [
		{"id": 1, "name": "Main Warehouse", "type": "Base", "status": "Operational", "condition": 80, "security": 35, "infestation": 0, "power_required": 0, "noise": 5, "capacity": 3, "current_use": "Workshop", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 2, "name": "Signage Workshop", "type": "Crafting", "status": "Unknown", "condition": 65, "security": 25, "infestation": 20, "power_required": 5, "noise": 15, "capacity": 3, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 3, "name": "Builder's Merchant", "type": "Supplies", "status": "Unknown", "condition": 70, "security": 20, "infestation": 35, "power_required": 0, "noise": 10, "capacity": 4, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 4, "name": "Pharmacy", "type": "Medical", "status": "Unknown", "condition": 60, "security": 15, "infestation": 40, "power_required": 3, "noise": 8, "capacity": 2, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 5, "name": "Garage", "type": "Vehicle", "status": "Unknown", "condition": 70, "security": 25, "infestation": 25, "power_required": 4, "noise": 20, "capacity": 3, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 6, "name": "Security Office", "type": "Defence", "status": "Unknown", "condition": 75, "security": 30, "infestation": 20, "power_required": 2, "noise": 5, "capacity": 2, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 7, "name": "Food Distribution Unit", "type": "Food", "status": "Unknown", "condition": 50, "security": 15, "infestation": 45, "power_required": 3, "noise": 12, "capacity": 4, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 8, "name": "Self-Storage Units", "type": "Loot", "status": "Unknown", "condition": 55, "security": 10, "infestation": 50, "power_required": 0, "noise": 10, "capacity": 5, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}},
		{"id": 9, "name": "Office Block", "type": "Living", "status": "Unknown", "condition": 70, "security": 20, "infestation": 30, "power_required": 6, "noise": 8, "capacity": 8, "current_use": "None", "assigned_survivors": [], "upgrades": [], "stored_supplies": {}}
	]
