class_name ResourceMap
extends TileMapLayer

## Diccionario que actúa como base de datos en memoria para los nodos de recursos
## Mapea coordenadas de la cuadrícula a recursos minables.
var _veins: Dictionary[Vector2i, ItemData] = {}

## Registra de forma manual o procedural una veta de mineral
func register_vein(grid_pos: Vector2i, resource: ItemData) -> void:
	_veins[grid_pos] = resource
	
	# Aquí opcionalmente pintaríamos un Tile visual en el TileMapLayer
	# set_cell(grid_pos, 0, coord_atlas)

## El GridManager o el MiningDrill consultan este método para saber qué extraer
func get_resource_at(grid_pos: Vector2i) -> ItemData:
	return _veins.get(grid_pos, null)

## Simula la extracción. Retorna el ItemData correspondiente.
## Si la veta fuera finita, aquí reduciríamos su contador.
func extract_resource(grid_pos: Vector2i) -> ItemData:
	return get_resource_at(grid_pos)
