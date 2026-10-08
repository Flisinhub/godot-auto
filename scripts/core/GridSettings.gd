class_name GridSettings
extends RefCounted

const CELL_SIZE: int = 32

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

## Convierte una posición en el mundo (píxeles) a coordenadas de cuadrícula (celdas)
static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / CELL_SIZE)),
		int(floor(world_pos.y / CELL_SIZE))
	)

## Convierte coordenadas de cuadrícula a la posición local en el mundo (esquina superior izquierda de la celda)
static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE,
		grid_pos.y * CELL_SIZE
	)

## Devuelve el vector de desplazamiento unitario asociado a una dirección cardinal
static func get_direction_vector(dir: Direction) -> Vector2i:
	match dir:
		Direction.UP:
			return Vector2i.UP
		Direction.RIGHT:
			return Vector2i.RIGHT
		Direction.DOWN:
			return Vector2i.DOWN
		Direction.LEFT:
			return Vector2i.LEFT
	return Vector2i.ZERO
