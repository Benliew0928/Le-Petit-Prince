extends Node

## Inventory — Autoload singleton for simple item tracking.
##
## Usage: Inventory.add_item("watering_can"), Inventory.has_item("watering_can")

signal item_added(item_id: String)
signal item_removed(item_id: String)

var _items: Dictionary = {}


func add_item(item_id: String, count: int = 1) -> void:
	_items[item_id] = _items.get(item_id, 0) + count
	item_added.emit(item_id)


func has_item(item_id: String) -> bool:
	return _items.get(item_id, 0) > 0


func use_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	_items[item_id] -= 1
	if _items[item_id] <= 0:
		_items.erase(item_id)
	return true


func remove_item(item_id: String) -> void:
	_items.erase(item_id)
	item_removed.emit(item_id)


func get_all_items() -> Dictionary:
	return _items.duplicate()
