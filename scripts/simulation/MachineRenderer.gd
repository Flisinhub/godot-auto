class_name MachineRenderer
extends Node2D

@export var main_node: Main

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if main_node == null:
		return
		
	var cell_size: float = float(GridSettings.CELL_SIZE)
	
	for drill in main_node.drills:
		var center = GridSettings.grid_to_world(drill.grid_position)
		var color = Color.YELLOW if drill.is_working else Color.DARK_RED
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), color, true)
		if drill.output_buffer != null:
			draw_circle(center + (Vector2.ONE * cell_size/2.0), 4.0, Color.ORANGE)
			
	for smelter in main_node.smelters:
		var center = GridSettings.grid_to_world(smelter.grid_position)
		var color = Color.CORAL if smelter.is_working else Color.DIM_GRAY
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), color, true)
		var in_pos = GridSettings.grid_to_world(smelter.input_port_pos) + Vector2(cell_size/2, cell_size/2)
		var out_pos = GridSettings.grid_to_world(smelter.output_port_pos) + Vector2(cell_size/2, cell_size/2)
		draw_circle(in_pos, 3.0, Color.BLUE)
		draw_circle(out_pos, 3.0, Color.RED)
		
	var default_font = ThemeDB.fallback_font
	for chest in main_node.chests:
		var center = GridSettings.grid_to_world(chest.grid_position)
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), Color.FOREST_GREEN, true)
		var text = str(chest.current_total)
		var text_pos = center + Vector2(2, 20)
		draw_string(default_font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
		
	for splitter in main_node.splitters:
		var center = GridSettings.grid_to_world(splitter.grid_position)
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), Color.CYAN, true)
		# Indicador visual del Divisor
		draw_circle(center + Vector2(cell_size/2, cell_size/2), 6.0, Color.DARK_CYAN)
		
	for merger in main_node.mergers:
		var center = GridSettings.grid_to_world(merger.grid_position)
		draw_rect(Rect2(center, Vector2(cell_size, cell_size)), Color.MAGENTA, true)
		# Indicador visual de la Unión
		var p1 = center + Vector2(4, 4)
		var p2 = center + Vector2(cell_size - 4, cell_size - 4)
		draw_line(p1, p2, Color.PURPLE, 3.0)
