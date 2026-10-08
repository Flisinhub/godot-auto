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

func _draw() -> void:
	if main_node == null:
		return
		
	var cell_size: float = float(GridSettings.CELL_SIZE)
	var default_font = ThemeDB.fallback_font
	
	for drill in main_node.drills:
		var center = GridSettings.grid_to_world(drill.grid_position)
		var color = Color.YELLOW if drill.is_working else Color.DARK_RED
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), color, true)
		
		# Flecha apuntando a dónde exporta el Extractor
		var arrow_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_direction_arrow(arrow_center, drill.direction, cell_size, Color.BLACK)
			
	for smelter in main_node.smelters:
		var center = GridSettings.grid_to_world(smelter.grid_position)
		var color = Color.CORAL if smelter.is_working else Color.DIM_GRAY
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), color, true)
		
		# Flecha enorme en el medio de la Fundición mostrando hacia dónde procesa
		var arrow_center = center + Vector2(cell_size/2, cell_size/2)
		_draw_direction_arrow(arrow_center, smelter.direction, cell_size, Color.WHITE)
		
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
		
		# Flecha en el centro
		var arrow_center = top_left + pixel_size / 2.0
		_draw_direction_arrow(arrow_center, assembler.direction, cell_size * 1.5, Color.WHITE)
		
		# Dibujar puertos de colores en el borde de la máquina
		for in_port in assembler.global_input_ports:
			var port_center = GridSettings.grid_to_world(in_port) + Vector2(cell_size/2, cell_size/2)
			draw_circle(port_center, 6.0, Color.BLUE)
		for out_port in assembler.global_output_ports:
			var port_center = GridSettings.grid_to_world(out_port) + Vector2(cell_size/2, cell_size/2)
			draw_circle(port_center, 6.0, Color.RED)
