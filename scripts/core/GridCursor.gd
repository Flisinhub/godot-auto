class_name GridCursor
extends Node2D

@export var cursor_color: Color = Color(0.2, 0.8, 0.2, 0.4)
@export var error_color: Color = Color(0.8, 0.2, 0.2, 0.4)

var main_node: Node = null

func _process(_delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	var snapped_pos: Vector2 = GridSettings.grid_to_world(grid_pos)
	
	if global_position != snapped_pos:
		global_position = snapped_pos
	
	queue_redraw()

func _draw() -> void:
	var base_size: float = float(GridSettings.CELL_SIZE)
	var current_mode = BuildToolbar.BuildMode.NONE
	var current_rot = GridSettings.Direction.UP
	
	if main_node != null:
		current_mode = main_node.current_mode
		current_rot = main_node.current_rotation
		
	# Calcular tamaño real (1x1 por defecto, o 3x3 si es Assembler)
	var size_cells: Vector2i = Vector2i(1, 1)
	if current_mode == BuildToolbar.BuildMode.ASSEMBLER:
		size_cells = GridSettings.get_rotated_size(Vector2i(3,3), current_rot)
	elif current_mode == BuildToolbar.BuildMode.LABORATORY:
		size_cells = GridSettings.get_rotated_size(Vector2i(2,2), current_rot)
		
	var pixel_size = Vector2(size_cells.x * base_size, size_cells.y * base_size)
	var rect: Rect2 = Rect2(Vector2.ZERO, pixel_size)
	
	# Verificar si el área completa está libre
	var is_valid: bool = true
	if main_node != null and main_node.grid_manager != null and current_mode != BuildToolbar.BuildMode.DEMOLISH:
		var grid_pos = GridSettings.world_to_grid(global_position)
		if not main_node.grid_manager.is_area_empty(grid_pos, size_cells):
			is_valid = false
			
	var color = cursor_color if is_valid else error_color
	
	if main_node != null:
		_draw_ghost(rect, color, current_mode, current_rot)
	else:
		draw_rect(rect, color, true)
		
	var border_color: Color = color
	border_color.a = 1.0
	draw_rect(rect, border_color, false, 2.0)

func _draw_ghost(rect: Rect2, base_color: Color, mode: int, dir: GridSettings.Direction) -> void:
	var center = rect.get_center()
	var half = rect.size.x / 2.0
	var dir_vec = Vector2(GridSettings.get_direction_vector(dir))
	
	match mode:
		1: # BELT
			draw_rect(rect, Color(0.5, 0.5, 0.5, 0.5), true)
			draw_line(center - dir_vec * (half * 0.5), center + dir_vec * (half * 0.5), base_color, 2.0)
		2: # DRILL
			draw_rect(rect, Color(1.0, 1.0, 0.0, 0.3), true)
		3: # SMELTER
			draw_rect(rect, Color(1.0, 0.5, 0.0, 0.3), true)
		4: # CHEST
			draw_rect(rect, Color(0.0, 0.5, 0.0, 0.3), true)
		5: # DEMOLISH
			draw_line(rect.position, rect.position + rect.size, Color.RED, 3.0)
			draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(0, rect.size.y), Color.RED, 3.0)
		6: # SPLITTER
			draw_rect(rect, Color(0.0, 1.0, 1.0, 0.3), true)
		7: # MERGER
			draw_rect(rect, Color(1.0, 0.0, 1.0, 0.3), true)
		8: # ASSEMBLER
			draw_rect(rect, Color(0.0, 0.0, 1.0, 0.3), true)
			draw_circle(center, 12.0, Color(1, 1, 1, 0.5))
		9: # LABORATORY
			draw_rect(rect, Color(0.5, 0.0, 0.5, 0.3), true)
			draw_circle(center, 10.0, Color(1, 1, 1, 0.5))
		_:
			draw_rect(rect, base_color, true)
