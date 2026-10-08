class_name MachineRenderer
extends Node2D

@export var main_node: Main

var smoke_particles: Array[Dictionary] = []

func _process(delta: float) -> void:
	# Actualizar humo de fundiciones
	for p in smoke_particles:
		p.life -= delta
		p.pos += p.vel * delta
	smoke_particles = smoke_particles.filter(func(p): return p.life > 0)
	
	if main_node != null:
		for s in main_node.smelters:
			if s.is_working and randf() < 0.15:
				var c = GridSettings.grid_to_world(s.grid_position) + Vector2(GridSettings.CELL_SIZE/2, GridSettings.CELL_SIZE/2)
				smoke_particles.append({
					"pos": c + Vector2(randf_range(-10, 10), -10),
					"vel": Vector2(randf_range(-15, 15), -40),
					"life": 1.5, "max_life": 1.5
				})
	queue_redraw()

func _draw_direction_arrow(center: Vector2, dir: GridSettings.Direction, size: float, color: Color) -> void:
	var dir_vec = Vector2(GridSettings.get_direction_vector(dir))
	var start = center - dir_vec * (size * 0.3)
	var end = center + dir_vec * (size * 0.3)
	draw_line(start, end, color, 3.0)
	draw_circle(end, 3.0, color)

func _draw_metal_panel(rect: Rect2, base_color: Color) -> void:
	draw_rect(rect, base_color, true)
	
	# Biselado (Luz y Sombra) para dar volumen
	var thickness = 3.0
	var light = Color.WHITE.blend(base_color).lightened(0.3)
	var dark = Color.BLACK.blend(base_color).darkened(0.5)
	
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), light, thickness)
	draw_line(rect.position, rect.position + Vector2(0, rect.size.y), light, thickness)
	draw_line(rect.position + Vector2(0, rect.size.y), rect.position + rect.size, dark, thickness)
	draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, dark, thickness)
	
	# Remaches
	var inset = 6.0
	var c_col = Color(0.1, 0.1, 0.1)
	for corner in [
		rect.position + Vector2(inset, inset),
		rect.position + Vector2(rect.size.x - inset, inset),
		rect.position + Vector2(inset, rect.size.y - inset),
		rect.position + Vector2(rect.size.x - inset, rect.size.y - inset)
	]:
		draw_circle(corner, 2.0, c_col)
		draw_circle(corner + Vector2(0.5, 0.5), 1.0, Color.GRAY)

func _draw_rotating_rect(center: Vector2, size: float, angle: float, color: Color, outline: bool = false) -> void:
	var p1 = center + Vector2(-size, -size).rotated(angle)
	var p2 = center + Vector2(size, -size).rotated(angle)
	var p3 = center + Vector2(size, size).rotated(angle)
	var p4 = center + Vector2(-size, size).rotated(angle)
	if outline:
		draw_line(p1, p2, color, 2.0); draw_line(p2, p3, color, 2.0)
		draw_line(p3, p4, color, 2.0); draw_line(p4, p1, color, 2.0)
	else:
		draw_polygon(PackedVector2Array([p1, p2, p3, p4]), PackedColorArray([color, color, color, color]))

func _draw_progress_bar(center: Vector2, progress: float, width: float) -> void:
	var bar_h = 4.0
	var bg_rect = Rect2(center.x - width/2.0, center.y + width/2.0 - bar_h - 2.0, width, bar_h)
	draw_rect(bg_rect, Color.BLACK, true)
	var fg_rect = Rect2(bg_rect.position, Vector2(width * progress, bar_h))
	draw_rect(fg_rect, Color.GREEN, true)

func _draw() -> void:
	if main_node == null: return
		
	var cell_size: float = float(GridSettings.CELL_SIZE)
	var default_font = ThemeDB.fallback_font
	var time = float(Time.get_ticks_msec()) / 1000.0
	
	# --- FASE 0: SOMBRAS GLOBALES ---
	var shadow_color = Color(0, 0, 0, 0.4)
	var s_off = Vector2(5, 5)
	
	for drill in main_node.drills: draw_rect(Rect2(GridSettings.grid_to_world(drill.grid_position) + s_off, Vector2(cell_size, cell_size)), shadow_color)
	for smelter in main_node.smelters: draw_rect(Rect2(GridSettings.grid_to_world(smelter.grid_position) + s_off, Vector2(cell_size, cell_size)), shadow_color)
	for chest in main_node.chests: draw_rect(Rect2(GridSettings.grid_to_world(chest.grid_position) + s_off, Vector2(cell_size, cell_size)), shadow_color)
	for splitter in main_node.splitters: draw_rect(Rect2(GridSettings.grid_to_world(splitter.grid_position) + s_off, Vector2(cell_size, cell_size)), shadow_color)
	for merger in main_node.mergers: draw_rect(Rect2(GridSettings.grid_to_world(merger.grid_position) + s_off, Vector2(cell_size, cell_size)), shadow_color)
	for asm in main_node.assemblers: 
		var size = Vector2(asm.current_size.x, asm.current_size.y) * cell_size
		draw_rect(Rect2(GridSettings.grid_to_world(asm.grid_position) + s_off, size), shadow_color)
	for lab in main_node.laboratories:
		var size = Vector2(lab.current_size.x, lab.current_size.y) * cell_size
		draw_rect(Rect2(GridSettings.grid_to_world(lab.grid_position) + s_off, size), shadow_color)
	
	# --- FASE 1: DIBUJO NORMAL DE MÁQUINAS ---
	for drill in main_node.drills:
		var center = GridSettings.grid_to_world(drill.grid_position)
		var m_center = center + Vector2(cell_size/2, cell_size/2)
		var color = Color(0.6, 0.6, 0.1) if drill.is_working else Color.DARK_RED
		_draw_metal_panel(Rect2(center, Vector2(cell_size, cell_size)), color)
		
		# Animación: Cuchilla extractora girando
		var rot_angle = time * PI * 4.0 if drill.is_working else 0.0
		_draw_rotating_rect(m_center, cell_size * 0.35, rot_angle, Color.DARK_GRAY)
		_draw_rotating_rect(m_center, cell_size * 0.35, rot_angle + PI/4.0, Color.DIM_GRAY)
		
		_draw_direction_arrow(m_center, drill.direction, cell_size, Color.BLACK)
			
	for smelter in main_node.smelters:
		var center = GridSettings.grid_to_world(smelter.grid_position)
		var m_center = center + Vector2(cell_size/2, cell_size/2)
		var color = Color.CORAL.darkened(0.3) if smelter.is_working else Color.DIM_GRAY
		_draw_metal_panel(Rect2(center, Vector2(cell_size, cell_size)), color)
		
		# Animación: Núcleo incandescente palpitando
		if smelter.is_working:
			var pulse = sin(time * 8.0) * 0.2 + 0.8
			draw_circle(m_center, cell_size * 0.3 * pulse, Color.ORANGE_RED)
			draw_circle(m_center, cell_size * 0.15 * pulse, Color.YELLOW)
		else:
			draw_circle(m_center, cell_size * 0.3, Color.DARK_GRAY)
			
		_draw_direction_arrow(m_center, smelter.direction, cell_size, Color.WHITE)
		
		if smelter.is_working and smelter.active_recipe != null:
			var prog = float(smelter._current_ticks) / float(smelter.active_recipe.processing_ticks)
			_draw_progress_bar(m_center, prog, cell_size * 0.8)
		
	for chest in main_node.chests:
		var center = GridSettings.grid_to_world(chest.grid_position)
		var m_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_metal_panel(Rect2(center, Vector2(cell_size, cell_size)), Color.FOREST_GREEN.darkened(0.2))
		
		# Detalle: Tapa superior metálica
		var inner = cell_size * 0.7
		draw_rect(Rect2(m_center - Vector2(inner/2, inner/2), Vector2(inner, inner)), Color.FOREST_GREEN, false, 3.0)
		
		var text = str(chest.current_total)
		draw_string(default_font, center + Vector2(2, 20), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
		
	for splitter in main_node.splitters:
		var center = GridSettings.grid_to_world(splitter.grid_position)
		var m_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_metal_panel(Rect2(center, Vector2(cell_size, cell_size)), Color.CYAN.darkened(0.4))
		_draw_direction_arrow(m_center, splitter.direction, cell_size, Color.CYAN)
		
	for merger in main_node.mergers:
		var center = GridSettings.grid_to_world(merger.grid_position)
		var m_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_metal_panel(Rect2(center, Vector2(cell_size, cell_size)), Color.MAGENTA.darkened(0.4))
		_draw_direction_arrow(m_center, merger.direction, cell_size, Color.MAGENTA)
		
	for assembler in main_node.assemblers:
		var top_left = GridSettings.grid_to_world(assembler.grid_position)
		var pixel_size = Vector2(assembler.current_size.x * cell_size, assembler.current_size.y * cell_size)
		var m_center = top_left + pixel_size / 2.0
		
		var color = Color.ROYAL_BLUE.darkened(0.4) if assembler.is_working else Color.DARK_BLUE
		_draw_metal_panel(Rect2(top_left, pixel_size), color)
		
		# Animación: Gran engranaje central girando
		var rot_angle = -time * PI * 1.5 if assembler.is_working else 0.0
		_draw_rotating_rect(m_center, cell_size * 0.8, rot_angle, Color.ROYAL_BLUE)
		_draw_rotating_rect(m_center, cell_size * 0.8, rot_angle + PI/4.0, Color.CORNFLOWER_BLUE)
		draw_circle(m_center, cell_size * 0.5, Color.DARK_SLATE_BLUE)
		
		draw_string(default_font, top_left + Vector2(10, 20), "ENSAMBLADORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		_draw_direction_arrow(m_center, assembler.direction, cell_size * 1.5, Color.WHITE)
		
		if assembler.is_working and assembler.active_recipe != null:
			var prog = float(assembler._current_ticks) / float(assembler.active_recipe.processing_ticks)
			_draw_progress_bar(m_center, prog, pixel_size.x * 0.8)
		
		for in_port in assembler.global_input_ports:
			var port_center = GridSettings.grid_to_world(in_port) + Vector2(cell_size/2, cell_size/2)
			draw_circle(port_center, 6.0, Color.BLUE)
		for out_port in assembler.global_output_ports:
			var port_center = GridSettings.grid_to_world(out_port) + Vector2(cell_size/2, cell_size/2)
			draw_circle(port_center, 6.0, Color.RED)
			
	for lab in main_node.laboratories:
		var top_left = GridSettings.grid_to_world(lab.grid_position)
		var pixel_size = Vector2(lab.current_size.x * cell_size, lab.current_size.y * cell_size)
		var m_center = top_left + pixel_size / 2.0
		var color = Color.PURPLE.darkened(0.5)
		_draw_metal_panel(Rect2(top_left, pixel_size), color)
		
		# Animación: Domo de energía
		if lab.is_working:
			var pulse = fmod(time * 2.0, 1.0) # 0 to 1 repeatedly
			draw_circle(m_center, (cell_size * 0.8) * pulse, Color(0.8, 0.2, 1.0, 1.0 - pulse))
			draw_circle(m_center, cell_size * 0.4, Color.MEDIUM_PURPLE)
		else:
			draw_circle(m_center, cell_size * 0.4, Color.DARK_PURPLE)
			
		draw_string(default_font, top_left + Vector2(10, 20), "LABORATORIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	for ins in main_node.inserters:
		var center = GridSettings.grid_to_world(ins.grid_position)
		var m_center = center + Vector2(cell_size/2, cell_size/2)
		var dir_vec = Vector2(GridSettings.get_direction_vector(ins.direction))
		
		# Base rotatoria del Inserter
		draw_circle(m_center, cell_size * 0.25, Color.DARK_GOLDENROD)
		draw_circle(m_center, cell_size * 0.1, Color.BLACK)
		
		var target_pos = m_center + dir_vec * (cell_size * 0.6)
		var source_pos = m_center - dir_vec * (cell_size * 0.6)
		
		var is_extended = ins.held_item != null
		var arm_pos = target_pos if is_extended else source_pos
		
		# Cinemática inversa falsa (Codo del brazo articulado)
		var mid_point = (m_center + arm_pos) / 2.0
		var ortho = Vector2(-dir_vec.y, dir_vec.x)
		var elbow = mid_point + ortho * (12.0 if is_extended else -12.0)
		
		# Brazo articulado
		draw_line(m_center, elbow, Color.ORANGE, 5.0)
		draw_line(elbow, arm_pos, Color.DARK_ORANGE, 4.0)
		
		# Articulaciones (Círculos)
		draw_circle(elbow, 4.0, Color.DARK_GRAY)
		draw_circle(arm_pos, 4.0, Color.YELLOW)
		
		# Dibujar el objeto agarrado geométricamente
		if ins.held_item != null:
			ItemData.draw_icon(self, arm_pos, 6.0, ins.held_item)
			
	# --- FASE 2: EFECTOS DE PARTÍCULAS (Humo) ---
	for p in smoke_particles:
		var alpha = p.life / p.max_life
		draw_circle(p.pos, 4.0 + (1.0 - alpha) * 8.0, Color(0.5, 0.5, 0.5, alpha * 0.6))
