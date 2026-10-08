class_name BeltCell
extends RefCounted

## Coordenada espacial en la cuadrícula de la simulación
var grid_position: Vector2i = Vector2i.ZERO

## Dirección lógica hacia la que la cinta transporta los ítems
var direction: GridSettings.Direction = GridSettings.Direction.UP

## Referencia vinculada a la siguiente celda receptora (null si no desemboca en otra cinta)
var next_cell: BeltCell = null

## Memoria estática de la celda: 2 ranuras (slots).
## slots[0] = Mitad frontal (salida).
## slots[1] = Mitad trasera (entrada).
var slots: Array[ItemData] = [null, null]

func _init(pos: Vector2i, dir: GridSettings.Direction) -> void:
	self.grid_position = pos
	self.direction = dir

## Comprueba si una ranura específica (0 o 1) está completamente libre.
func is_slot_empty(slot_index: int) -> bool:
	return slots[slot_index] == null

## Obtiene el ítem de la ranura, manteniéndolo en su lugar.
func get_item(slot_index: int) -> ItemData:
	return slots[slot_index]

## Inserta un ítem en la ranura deseada. Sobreescribirá sin piedad (la lógica superior debe validarlo antes).
func put_item(slot_index: int, item: ItemData) -> void:
	slots[slot_index] = item

## Extrae un ítem de la ranura, dejándola inmediatamente vacía para nuevos ítems.
func extract_item(slot_index: int) -> ItemData:
	var item: ItemData = slots[slot_index]
	slots[slot_index] = null
	return item
