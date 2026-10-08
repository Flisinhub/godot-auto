class_name MiningDrillNode
extends Node2D

## Referencia pura a la lógica de la perforadora
@export var drill_logic: MiningDrill

func _process(_delta: float) -> void:
	if drill_logic == null:
		return
	
	# Aquí, si tuviéramos un AnimatedSprite2D, haríamos:
	# if drill_logic.is_working and not anim.is_playing(): anim.play("work")
	# elif not drill_logic.is_working and anim.is_playing(): anim.pause()
	
	queue_redraw()

func _draw() -> void:
	if drill_logic == null:
		return
		
	var cell_size: float = float(GridSettings.CELL_SIZE)
	
	# Usamos un color reactivo: Amarillo si trabaja, Rojo Oscuro si está atascada/apagada
	var state_color: Color = Color.YELLOW if drill_logic.is_working else Color.DARK_RED
	
	# Centrar en la celda
	var center = GridSettings.grid_to_world(drill_logic.grid_position)
	draw_rect(Rect2(center, Vector2(cell_size, cell_size)), state_color, true)
	
	# Representación del Búfer: Si tiene un ítem atascado/listo, dibujamos un indicador naranja
	if drill_logic.output_buffer != null:
		var buffer_pos: Vector2 = center + Vector2(cell_size / 2.0, cell_size / 2.0)
		draw_circle(buffer_pos, 4.0, Color.ORANGE)
