class_name ResourceMap
extends TileMapLayer

## Diccionario que actúa como base de datos en memoria para los nodos de recursos
## Mapea coordenadas de la cuadrícula a recursos minables.
var _veins: Dictionary[Vector2i, ItemData] = {}

func _process(_delta: float) -> void:
	# Nos aseguramos de dibujarlo
	queue_redraw()

func _draw() -> void:
	var cell_size = float(GridSettings.CELL_SIZE)
	# Dibujamos un parche de color para las vetas para que el jugador sepa dónde colocar el Extractor
	for pos in _veins.keys():
		var rect = Rect2(GridSettings.grid_to_world(pos), Vector2(cell_size, cell_size))
		
		# Fondo sutil para el mineral
		draw_rect(rect, Color(0.3, 0.4, 0.5, 0.4), true)
		
		# Textura del mineral si existe
		var item = _veins[pos]
		if item.texture != null:
			draw_texture_rect(item.texture, rect, false, Color(1.0, 1.0, 1.0, 0.5))

## Registra de forma manual o procedural una veta de mineral
func register_vein(grid_pos: Vector2i, resource: ItemData) -> void:
	_veins[grid_pos] = resource
	queue_redraw()

## El GridManager o el MiningDrill consultan este método para saber qué extraer
func get_resource_at(grid_pos: Vector2i) -> ItemData:
	return _veins.get(grid_pos, null)

## Simula la extracción. Retorna el ItemData correspondiente.
func extract_resource(grid_pos: Vector2i) -> ItemData:
	return get_resource_at(grid_pos)
