class_name MachineRenderer
extends Node2D

@export var main_node: Main

func _process(_delta: float) -> void:
	queue_redraw()

func _draw_direction_arrow(center: Vector2, dir: GridSettings.Direction, size: float, color: Color) -> void:
	var dir_vec = Vector2(GridSettings.get_direction_vector(dir))
	var start = center - dir_vec * (size * 0.3)
	var end = center + dir_vec * (size * 0.3)
	draw_line(start, end, color, 3.0)
	draw_circle(end, 3.0, color)

## Dibuja una pequeña barra de progreso estilo UI sobre la máquina
func _draw_progress_bar(center: Vector2, progress: float, width: float) -> void:
	var bar_h = 4.0
	var bg_rect = Rect2(center.x - width/2.0, center.y + width/2.0 - bar_h - 2.0, width, bar_h)
	draw_rect(bg_rect, Color.BLACK, true)
	var fg_rect = Rect2(bg_rect.position, Vector2(width * progress, bar_h))
	draw_rect(fg_rect, Color.GREEN, true)

func _draw() -> void:
	if main_node == null:
		return
		
	var cell_size: float = float(GridSettings.CELL_SIZE)
	var default_font = ThemeDB.fallback_font
	
	for drill in main_node.drills:
		var center = GridSettings.grid_to_world(drill.grid_position)
		var color = Color(0.8, 0.8, 0.1) if drill.is_working else Color.DARK_RED
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), color, true)
		
		var arrow_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_direction_arrow(arrow_center, drill.direction, cell_size, Color.BLACK)
			
	for smelter in main_node.smelters:
		var center = GridSettings.grid_to_world(smelter.grid_position)
		var color = Color.CORAL if smelter.is_working else Color.DIM_GRAY
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), color, true)
		
		var m_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_direction_arrow(m_center, smelter.direction, cell_size, Color.WHITE)
		
		if smelter.is_working and smelter.active_recipe != null:
			var prog = float(smelter._current_ticks) / float(smelter.active_recipe.processing_ticks)
			_draw_progress_bar(m_center, prog, cell_size * 0.8)
		
	for chest in main_node.chests:
		var center = GridSettings.grid_to_world(chest.grid_position)
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), Color.FOREST_GREEN, true)
		var text = str(chest.current_total)
		var text_pos = center + Vector2(2, 20)
		draw_string(default_font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
		
	for splitter in main_node.splitters:
		var center = GridSettings.grid_to_world(splitter.grid_position)
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), Color.CYAN, true)
		var arrow_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_direction_arrow(arrow_center, splitter.direction, cell_size, Color.BLACK)
		
	for merger in main_node.mergers:
		var center = GridSettings.grid_to_world(merger.grid_position)
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), Color.MAGENTA, true)
		var arrow_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_direction_arrow(arrow_center, merger.direction, cell_size, Color.WHITE)
		
	for assembler in main_node.assemblers:
		var top_left = GridSettings.grid_to_world(assembler.grid_position)
		var pixel_size = Vector2(assembler.current_size.x * cell_size, assembler.current_size.y * cell_size)
		
		var color = Color.ROYAL_BLUE if assembler.is_working else Color.DARK_BLUE
		draw_rect(Rect2(top_left, pixel_size), color, true)
		draw_rect(Rect2(top_left, pixel_size), Color.LIGHT_BLUE, false, 2.0)
		
		draw_string(default_font, top_left + Vector2(10, 20), "ENSAMBLADORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		
		var m_center = top_left + pixel_size / 2.0
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
		var color = Color.PURPLE if lab.is_working else Color.DARK_PURPLE
		draw_rect(Rect2(top_left, pixel_size), color, true)
		draw_rect(Rect2(top_left, pixel_size), Color.ORCHID, false, 2.0)
		draw_string(default_font, top_left + Vector2(10, 20), "LABORATORIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

