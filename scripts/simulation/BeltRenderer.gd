class_name BeltRenderer
extends Node2D

## Referencia al motor de simulación principal para leer su estado sin alterarlo
@export var simulation: FactorySimulation

func _process(_delta: float) -> void:
	# Forzamos el redibujado cada fotograma (60+ FPS) aunque la simulación
	# lógica vaya a un ritmo más bajo (ej. 5 Ticks por segundo).
	queue_redraw()

func _draw() -> void:
	if simulation == null:
		return
		
	# Calculamos el progreso de la fracción del tick (valor entre 0.0 y 1.0)
	# Esto es la clave de la interpolación lineal (Lerp) sin guardar estados pasados
	var tick_progress: float = clamp(simulation._time_accumulator / simulation.TICK_RATE, 0.0, 1.0)
	var half_size: float = GridSettings.CELL_SIZE / 2.0
	
	for belt in simulation._belts:
		var center_pos: Vector2 = GridSettings.grid_to_world(belt.grid_position) + Vector2(half_size, half_size)
		var dir_vec: Vector2 = Vector2(GridSettings.get_direction_vector(belt.direction)) * half_size
		
		# Renderizado de la Ranura TRASERA / ENTRADA (Slot 1)
		if not belt.is_slot_empty(1):
			var item: ItemData = belt.get_item(1)
			if item.texture != null:
				var start_pos: Vector2 = center_pos - dir_vec # Borde de entrada
				var end_pos: Vector2 = center_pos             # Centro geométrico de la celda
				var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
				_draw_item_centered(visual_pos, item.texture)
				
		# Renderizado de la Ranura FRONTAL / SALIDA (Slot 0)
		if not belt.is_slot_empty(0):
			var item: ItemData = belt.get_item(0)
			if item.texture != null:
				var start_pos: Vector2 = center_pos             # Centro geométrico de la celda
				var end_pos: Vector2 = center_pos + dir_vec   # Borde de salida
				var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
				_draw_item_centered(visual_pos, item.texture)

## Función auxiliar para pintar una textura con su centro exacto en 'pos'
func _draw_item_centered(pos: Vector2, texture: Texture2D) -> void:
	var tex_size: Vector2 = texture.get_size()
	draw_texture(texture, pos - (tex_size / 2.0))
