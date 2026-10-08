class_name StorageChest
extends RefCounted

var grid_position: Vector2i

## Cinta que apunta hacia el cofre (por donde entran los ítems)
var input_belt: BeltCell = null

## Inventario del contenedor. Mapea ItemData a su cantidad.
var inventory: Dictionary[ItemData, int] = {}

var current_total: int = 0
var max_capacity: int = 100

func _init(pos: Vector2i) -> void:
	self.grid_position = pos

## Método invocado por la simulación en cada _tick()
func process_tick() -> void:
	if input_belt == null or current_total >= max_capacity:
		return
		
	# Absorbe el ítem ubicado en la ranura FRONTAL (0) de la cinta que lo alimenta
	if not input_belt.is_slot_empty(0):
		var item: ItemData = input_belt.extract_item(0)
		inventory[item] = inventory.get(item, 0) + 1
		current_total += 1
