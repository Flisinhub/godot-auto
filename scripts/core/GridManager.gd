class_name GridManager
extends RefCounted

## Diccionario principal de la cuadrícula. Mapea la coordenada (Vector2i) a la entidad u objeto que la ocupa (Variant).
var _cells: Dictionary[Vector2i, Variant] = {}

## Comprueba si la celda indicada está vacía.
func is_empty(cell_pos: Vector2i) -> bool:
	return not _cells.has(cell_pos)

## Registra una entidad en una celda. 
## Retorna 'true' si se registró exitosamente, o 'false' si la celda ya estaba ocupada.
## Esta operación atómica garantiza que es imposible registrar dos objetos en la misma coordenada.
func occupy_cell(cell_pos: Vector2i, entity: Variant) -> bool:
	if not is_empty(cell_pos):
		return false
	
	_cells[cell_pos] = entity
	return true

## Libera la celda especificada y retorna la entidad que contenía (o null si estaba vacía).
func free_cell(cell_pos: Vector2i) -> Variant:
	if is_empty(cell_pos):
		return null
		
	var entity: Variant = _cells[cell_pos]
	_cells.erase(cell_pos)
	return entity

## Obtiene la entidad ubicada en la coordenada, sin removerla (retorna null si está vacía).
func get_entity_at(cell_pos: Vector2i) -> Variant:
	return _cells.get(cell_pos, null)

## Limpia completamente el registro lógico.
func clear_grid() -> void:
	_cells.clear()
