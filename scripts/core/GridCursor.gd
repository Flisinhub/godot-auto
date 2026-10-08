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
	# Animación de respiración holográfica
	var t = float(Time.get_ticks_msec()) / 1000.0
	var pulse = sin(t * 10.0) * 0.1 + 0.9
	var color = Color(0.2, 0.8, 1.0, 0.5)
	if mode == 5: # DEMOLISH
		color = Color(1.0, 0.2, 0.2, 0.5)
	elif not (base_color == cursor_color):
		color = Color(1.0, 0.2, 0.2, 0.5) # Color de error (rojo) si no es válido
		
	var r_pos = rect.position - Vector2(1,1) * (pulse * 2.0)
	var r_size = rect.size + Vector2(2,2) * (pulse * 4.0)
	
	# Fondo transparente sutil
	draw_rect(Rect2(r_pos, r_size), Color(color.r, color.g, color.b, 0.15), true)
	
	# Dibujar esquinas (brackets)
	var corner_len = min(8.0, r_size.x * 0.25)
	var thickness = 2.0
	
	draw_line(r_pos, r_pos + Vector2(corner_len, 0), color, thickness)
	draw_line(r_pos, r_pos + Vector2(0, corner_len), color, thickness)
	var tr = r_pos + Vector2(r_size.x, 0)
	draw_line(tr, tr + Vector2(-corner_len, 0), color, thickness)
	draw_line(tr, tr + Vector2(0, corner_len), color, thickness)
	var bl = r_pos + Vector2(0, r_size.y)
	draw_line(bl, bl + Vector2(corner_len, 0), color, thickness)
	draw_line(bl, bl + Vector2(0, -corner_len), color, thickness)
	var br = r_pos + r_size
	draw_line(br, br + Vector2(-corner_len, 0), color, thickness)
	draw_line(br, br + Vector2(0, -corner_len), color, thickness)
	
	var center = rect.get_center()
	var half = rect.size.x / 2.0
	var dir_vec = Vector2(GridSettings.get_direction_vector(dir))
	
	match mode:
		1: # BELT
			draw_rect(rect, Color(0.2, 0.2, 0.2, 0.5), true)
			var p1 = center + dir_vec * (half * 0.4)
			var p2 = center - dir_vec * (half * 0.2) + dir_vec.orthogonal() * (half * 0.4)
			var p3 = center - dir_vec * (half * 0.2) - dir_vec.orthogonal() * (half * 0.4)
			draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([color]))
		2: # DRILL
			draw_rect(rect, Color(0.6, 0.6, 0.1, 0.5), true)
			draw_circle(center, half * 0.4, Color(0.4, 0.4, 0.4, 0.8))
			var arr1 = center + dir_vec * half
			draw_line(center, arr1, Color.YELLOW, 3.0)
		3: # SMELTER
			draw_rect(rect, Color.CORAL.darkened(0.3) * Color(1,1,1,0.5), true)
			draw_circle(center, half * 0.4, Color.ORANGE_RED * 0.8)
		4: # CHEST
			draw_rect(rect, Color.SADDLE_BROWN * Color(1,1,1,0.5), true)
			draw_rect(Rect2(center - Vector2(half*0.5, half*0.5), Vector2(half, half)), Color.DARK_GOLDENROD * Color(1,1,1,0.5), true)
		5: # DEMOLISH
			draw_line(rect.position, rect.position + rect.size, Color.RED, 3.0)
			draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(0, rect.size.y), Color.RED, 3.0)
		6: # SPLITTER
			draw_rect(rect, Color.CYAN * Color(1,1,1,0.5), true)
		7: # MERGER
			draw_rect(rect, Color.MAGENTA * Color(1,1,1,0.5), true)
		8: # ASSEMBLER
			draw_rect(rect, Color.ROYAL_BLUE.darkened(0.4) * Color(1,1,1,0.5), true)
			draw_circle(center, half * 0.5, Color.DARK_SLATE_BLUE * Color(1,1,1,0.5))
			var arr3 = center + dir_vec * half
			draw_line(center, arr3, Color.WHITE, 4.0)
		9: # LABORATORY
			draw_rect(rect, Color.PURPLE.darkened(0.4) * Color(1,1,1,0.5), true)
			draw_circle(center, half * 0.4, Color.PURPLE * Color(1,1,1,0.5))
		10: # INSERTER
			draw_rect(rect, Color(0.8, 0.8, 0.1, 0.3), true)
			draw_line(center - dir_vec * (half * 0.8), center + dir_vec * (half * 0.8), Color.WHITE, 3.0)
			draw_circle(center + dir_vec * (half * 0.8), 4.0, Color.YELLOW)
		_:
			draw_rect(rect, base_color, true)
