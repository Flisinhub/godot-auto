class_name GridCursor
extends Node2D

@export var cursor_color: Color = Color(0.2, 0.8, 0.2, 0.4)
@export var error_color: Color = Color(0.8, 0.2, 0.2, 0.4)

## Referencia a Main para leer el estado de construcción actual
var main_node: Node = null

func _process(_delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	var snapped_pos: Vector2 = GridSettings.grid_to_world(grid_pos)
	
	if global_position != snapped_pos:
		global_position = snapped_pos
	
	# Forzamos redibujado continuo para mostrar la rotación correcta instantáneamente
	queue_redraw()

func _draw() -> void:
	var size: float = float(GridSettings.CELL_SIZE)
	var rect: Rect2 = Rect2(Vector2.ZERO, Vector2(size, size))
	
	var is_valid: bool = true
	if main_node != null and main_node.grid_manager != null:
		var grid_pos = GridSettings.world_to_grid(global_position)
		if not main_node.grid_manager.is_empty(grid_pos):
			is_valid = false
			
	var color = cursor_color if is_valid else error_color
	
	# Dibuja fantasma según el modo actual
	if main_node != null:
		_draw_ghost(rect, color, main_node.current_mode, main_node.current_rotation)
	else:
		draw_rect(rect, color, true)
		
	var border_color: Color = color
	border_color.a = 1.0
	draw_rect(rect, border_color, false, 2.0)

func _draw_ghost(rect: Rect2, base_color: Color, mode: int, dir: GridSettings.Direction) -> void:
	# El modo 1 es BELT, 2 es DRILL, 3 es SMELTER, 4 es CHEST, 5 DEMOLISH, 6 SPLITTER, 7 MERGER
	var center = rect.get_center()
	var half = rect.size.x / 2.0
	var dir_vec = Vector2(GridSettings.get_direction_vector(dir))
	
	match mode:
		1: # BELT (Gris semitransparente con flecha)
			draw_rect(rect, Color(0.5, 0.5, 0.5, 0.5), true)
			draw_line(center - dir_vec * (half * 0.5), center + dir_vec * (half * 0.5), base_color, 2.0)
		2: # DRILL (Amarillo semitransparente)
			draw_rect(rect, Color(1.0, 1.0, 0.0, 0.3), true)
		3: # SMELTER (Naranja semitransparente)
			draw_rect(rect, Color(1.0, 0.5, 0.0, 0.3), true)
		4: # CHEST (Verde semitransparente)
			draw_rect(rect, Color(0.0, 0.5, 0.0, 0.3), true)
		5: # DEMOLISH
			draw_line(rect.position, rect.position + rect.size, Color.RED, 3.0)
			draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(0, rect.size.y), Color.RED, 3.0)
		6: # SPLITTER (Cian)
			draw_rect(rect, Color(0.0, 1.0, 1.0, 0.3), true)
		7: # MERGER (Magenta)
			draw_rect(rect, Color(1.0, 0.0, 1.0, 0.3), true)
		_:
			draw_rect(rect, base_color, true)
