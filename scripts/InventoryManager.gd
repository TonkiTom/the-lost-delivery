extends Node

signal inventory_changed

var inventory: Dictionary = {}
var inventory_open: bool = false

func _ready() -> void:
	add_item("Moon Tea", 1)
	add_item("Delivery Note", 1)
	add_item("Town Map", 1)

func add_item(item_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	if inventory.has(item_name):
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount
	emit_signal("inventory_changed")

func remove_item(item_name: String, amount: int = 1) -> void:
	if not inventory.has(item_name):
		return
	inventory[item_name] = max(inventory[item_name] - amount, 0)
	if inventory[item_name] <= 0:
		inventory.erase(item_name)
	emit_signal("inventory_changed")

func has_item(item_name: String) -> bool:
	return inventory.has(item_name) and inventory[item_name] > 0

func clear_inventory() -> void:
	inventory.clear()
	emit_signal("inventory_changed")

func toggle_inventory() -> void:
	inventory_open = not inventory_open
	emit_signal("inventory_changed")

func get_items() -> Array:
	return inventory.keys()
