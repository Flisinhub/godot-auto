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
	
	for belt in simulation._belts:
		var center_pos: Vector2 = GridSettings.grid_to_world(belt.grid_position) + Vector2(half_size, half_size)
		var dir_vec: Vector2 = Vector2(GridSettings.get_direction_vector(belt.direction))
		var pixel_dir: Vector2 = dir_vec * half_size
		
		# 1. DIBUJAR LA CINTA BASE (Fondo)
		var belt_rect = Rect2(center_pos - Vector2(half_size, half_size), Vector2(cell_size, cell_size))
		draw_rect(belt_rect, Color(0.15, 0.15, 0.15), true)
		
		# 1.5 DIBUJAR RAÍLES LATERALES (Metálicos)
		var ortho = Vector2(-dir_vec.y, dir_vec.x) * (half_size - 1.0)
		var p_back = center_pos - pixel_dir
		var p_front = center_pos + pixel_dir
		draw_line(p_back + ortho, p_front + ortho, Color(0.4, 0.4, 0.4), 2.0)
		draw_line(p_back - ortho, p_front - ortho, Color(0.4, 0.4, 0.4), 2.0)
		
		# 2. DIBUJAR FLECHAS ANIMADAS (Chevrons)
		# Creamos una ilusión de scroll usando módulo
		var speed = 20.0
		var pattern_spacing = 10.0
		var scroll_offset = fmod(current_time * speed, pattern_spacing)
		
		# Dibujamos 3 líneas ortogonales (chevrons simplificados) desplazándose
		var ortho = Vector2(-dir_vec.y, dir_vec.x) * (half_size * 0.6)
		for i in range(-1, 3):
			var base_offset = (i * pattern_spacing) - (pattern_spacing / 2.0)
			var total_offset = base_offset + scroll_offset
			
			# Ocultar las líneas si se salen de los límites de la celda
			if abs(total_offset) <= half_size:
				var line_center = center_pos + dir_vec * total_offset
				var p1 = line_center + ortho - (dir_vec * 2) # Ligera forma de 'V'
				var p2 = line_center
				var p3 = line_center - ortho - (dir_vec * 2)
				
				draw_line(p1, p2, Color(0.3, 0.3, 0.3), 2.0)
				draw_line(p2, p3, Color(0.3, 0.3, 0.3), 2.0)
		
		# 3. DIBUJAR LOS ÍTEMS INTERPOLADOS
		if not belt.is_slot_empty(1):
			var item: ItemData = belt.get_item(1)
			if item.texture != null:
				var start_pos: Vector2 = center_pos - pixel_dir
				var end_pos: Vector2 = center_pos
				var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
				_draw_item_centered(visual_pos, item.texture)
				
		if not belt.is_slot_empty(0):
			var item: ItemData = belt.get_item(0)
			if item.texture != null:
				var start_pos: Vector2 = center_pos
				var end_pos: Vector2 = center_pos + pixel_dir
				var visual_pos: Vector2 = start_pos.lerp(end_pos, tick_progress)
				_draw_item_centered(visual_pos, item.texture)

func _draw_item_centered(pos: Vector2, texture: Texture2D) -> void:
	var tex_size: Vector2 = texture.get_size()
	var rect = Rect2(pos - (tex_size / 2.0), tex_size)
	
	# Efecto visual: Borde negro y sombra debajo del ítem para que "resalte"
	draw_rect(rect.grow(1.0), Color(0.0, 0.0, 0.0, 0.8), true)
	draw_texture(texture, rect.position)
