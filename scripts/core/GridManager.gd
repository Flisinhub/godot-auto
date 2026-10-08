class_name GridManager
extends RefCounted

var _cells: Dictionary[Vector2i, Variant] = {}

func is_empty(cell_pos: Vector2i) -> bool:
	return not _cells.has(cell_pos)

## Comprueba si un área entera está libre
func is_area_empty(base_pos: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			if not is_empty(base_pos + Vector2i(x, y)):
				return false
	return true

## Registra una entidad en una sola celda
func occupy_cell(cell_pos: Vector2i, entity: Variant) -> bool:
	if not is_empty(cell_pos):
		return false
	_cells[cell_pos] = entity
	return true

## Registra una entidad Multi-Celda (ej. Ensambladoras 3x3)
func occupy_area(base_pos: Vector2i, size: Vector2i, entity: Variant) -> bool:
	if not is_area_empty(base_pos, size):
		return false
	for x in range(size.x):
		for y in range(size.y):
			_cells[base_pos + Vector2i(x, y)] = entity
	return true

## Libera la celda y elimina todas las referencias de esa misma entidad en la cuadrícula
func free_cell(cell_pos: Vector2i) -> Variant:
	if is_empty(cell_pos):
		return null
		
	var entity: Variant = _cells[cell_pos]
	var keys_to_remove: Array[Vector2i] = []
	
	for key in _cells.keys():
		if _cells[key] == entity:
			keys_to_remove.append(key)
			
	for key in keys_to_remove:
		_cells.erase(key)
		
	return entity

func get_entity_at(cell_pos: Vector2i) -> Variant:
	return _cells.get(cell_pos, null)

func clear_grid() -> void:
	_cells.clear()
