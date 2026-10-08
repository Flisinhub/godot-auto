class_name BeltRenderer
extends Node2D

@export var simulation: FactorySimulation

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if simulation == null:
		return
		
	var tick_progress: float = clamp(simulation._time_accumulator / simulation.TICK_RATE, 0.0, 1.0)
	var half_size: float = GridSettings.CELL_SIZE / 2.0
	var cell_size: float = float(GridSettings.CELL_SIZE)
	
	for belt in simulation._belts:
		var center_pos: Vector2 = GridSettings.grid_to_world(belt.grid_position) + Vector2(half_size, half_size)
		var dir_vec: Vector2 = Vector2(GridSettings.get_direction_vector(belt.direction)) * half_size
		
		# 1. DIBUJAR LA CINTA BASE (Un fondo gris)
		var belt_rect = Rect2(center_pos - Vector2(half_size, half_size), Vector2(cell_size, cell_size))
		draw_rect(belt_rect, Color(0.2, 0.2, 0.2), true)
		
		# 2. DIBUJAR FLECHA DE DIRECCIÓN
		var arrow_start = center_pos - (dir_vec * 0.5)
		var arrow_end = center_pos + (dir_vec * 0.5)
		draw_line(arrow_start, arrow_end, Color.LIGHT_GRAY, 2.0)
		draw_circle(arrow_end, 2.0, Color.WHITE) # Punta de flecha
		
		# 3. DIBUJAR LOS ÍTEMS INTERPOLADOS
		if not belt.is_slot_empty(1):
			var item: ItemData = belt.get_item(1)
			if item.texture != null:
				var start_pos: Vector2 = center_pos - dir_vec
				var end_pos: Vector2 = center_pos
				var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
				_draw_item_centered(visual_pos, item.texture)
				
		if not belt.is_slot_empty(0):
			var item: ItemData = belt.get_item(0)
			if item.texture != null:
				var start_pos: Vector2 = center_pos
				var end_pos: Vector2 = center_pos + dir_vec
				var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
				_draw_item_centered(visual_pos, item.texture)

func _draw_item_centered(pos: Vector2, texture: Texture2D) -> void:
	var tex_size: Vector2 = texture.get_size()
	draw_texture(texture, pos - (tex_size / 2.0))
