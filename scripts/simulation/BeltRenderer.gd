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
	
	# Usamos el tiempo global real para animar constantemente la cinta,
	# independientemente de los ticks lógicos.
	var current_time = float(Time.get_ticks_msec()) / 1000.0
	
	# FASE 0: DIBUJAR SOMBRAS (Drop Shadows)
	for belt in simulation._belts:
		var center_pos: Vector2 = GridSettings.grid_to_world(belt.grid_position) + Vector2(half_size, half_size)
		var shadow_rect = Rect2(center_pos - Vector2(half_size, half_size) + Vector2(4, 4), Vector2(cell_size, cell_size))
		draw_rect(shadow_rect, Color(0, 0, 0, 0.4), true)
		
	# FASE 1: DIBUJAR CINTAS Y OBJETOS
	for belt in simulation._belts:
		var center_pos: Vector2 = GridSettings.grid_to_world(belt.grid_position) + Vector2(half_size, half_size)
		var dir_vec: Vector2 = Vector2(GridSettings.get_direction_vector(belt.direction))
		var pixel_dir: Vector2 = dir_vec * half_size
		
		# 1. DIBUJAR LA CINTA BASE (Fondo)
		var belt_rect = Rect2(center_pos - Vector2(half_size, half_size), Vector2(cell_size, cell_size))
		draw_rect(belt_rect, Color(0.15, 0.15, 0.15), true)
		
		# 1.5 DIBUJAR RAÍLES LATERALES Y RODILLOS (Metálicos)
		var ortho = Vector2(-dir_vec.y, dir_vec.x) * (half_size - 1.0)
		var p_back = center_pos - pixel_dir
		var p_front = center_pos + pixel_dir
		draw_line(p_back + ortho, p_front + ortho, Color(0.4, 0.4, 0.4), 2.0)
		draw_line(p_back - ortho, p_front - ortho, Color(0.4, 0.4, 0.4), 2.0)
		
		# Rodillos
		for i in range(-2, 3):
			var roller_pos = center_pos + dir_vec * (i * (cell_size / 6.0))
			draw_line(roller_pos + ortho * 0.8, roller_pos - ortho * 0.8, Color(0.1, 0.1, 0.1), 3.0)
		
		# 2. DIBUJAR FLECHAS ANIMADAS (Chevrons)
		var speed = 20.0
		var pattern_spacing = 10.0
		var scroll_offset = fmod(current_time * speed, pattern_spacing)
		
		for i in range(-1, 3):
			var base_offset = (i * pattern_spacing) - (pattern_spacing / 2.0)
			var total_offset = base_offset + scroll_offset
			
			if abs(total_offset) <= half_size:
				var line_center = center_pos + dir_vec * total_offset
				var p1 = line_center + ortho - (dir_vec * 2)
				var p2 = line_center
				var p3 = line_center - ortho - (dir_vec * 2)
				
				draw_line(p1, p2, Color(0.3, 0.3, 0.3), 2.0)
				draw_line(p2, p3, Color(0.3, 0.3, 0.3), 2.0)
		
		# 3. DIBUJAR LOS ÍTEMS INTERPOLADOS
		var bobbing = sin(current_time * 15.0) * 1.5
		
		if not belt.is_slot_empty(1):
			var item: ItemData = belt.get_item(1)
			var start_pos: Vector2 = center_pos - pixel_dir
			var end_pos: Vector2 = center_pos
			var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
			visual_pos.y += bobbing
			_draw_item_centered(visual_pos, item)
				
		if not belt.is_slot_empty(0):
			var item: ItemData = belt.get_item(0)
			var start_pos: Vector2 = center_pos
			var end_pos: Vector2 = center_pos + pixel_dir
			var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
			visual_pos.y += bobbing
			_draw_item_centered(visual_pos, item)

func _draw_item_centered(pos: Vector2, item: ItemData) -> void:
	# Sombra proyectada por el objeto
	ItemData.draw_icon(self, pos + Vector2(2, 2), 6.0, item)
	# Dibujar objeto real
	ItemData.draw_icon(self, pos, 6.0, item)
