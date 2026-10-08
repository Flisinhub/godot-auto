class_name GridSettings
extends RefCounted

const CELL_SIZE: int = 32

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / CELL_SIZE)),
		int(floor(world_pos.y / CELL_SIZE))
	)

static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE,
		grid_pos.y * CELL_SIZE
	)

static func get_direction_vector(dir: Direction) -> Vector2i:
	match dir:
		Direction.UP: return Vector2i.UP
		Direction.RIGHT: return Vector2i.RIGHT
		Direction.DOWN: return Vector2i.DOWN
		Direction.LEFT: return Vector2i.LEFT
	return Vector2i.ZERO

## Rota un vector bidimensional (ej. el tamaño de una máquina) según la dirección
static func get_rotated_size(size: Vector2i, dir: Direction) -> Vector2i:
	if dir == Direction.LEFT or dir == Direction.RIGHT:
		return Vector2i(size.y, size.x)
	return size

## Rota un puerto local (coordenada de entrada/salida relativa al Top-Left de la máquina)
## basándose en el tamaño original de la máquina y la rotación deseada.
static func rotate_local_offset(offset: Vector2i, size: Vector2i, dir: Direction) -> Vector2i:
	var x = offset.x
	var y = offset.y
	var w = size.x
	var h = size.y
	match dir:
		Direction.UP: return Vector2i(x, y)
		Direction.RIGHT: return Vector2i(h - 1 - y, x)
		Direction.DOWN: return Vector2i(w - 1 - x, h - 1 - y)
		Direction.LEFT: return Vector2i(y, w - 1 - x)
	return offset
