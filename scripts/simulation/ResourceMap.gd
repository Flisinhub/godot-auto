class_name ResourceMap
extends TileMapLayer

var _veins: Dictionary[Vector2i, ItemData] = {}

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cell_size = float(GridSettings.CELL_SIZE)
	var half = cell_size / 2.0
	
	for pos in _veins.keys():
		var center = GridSettings.grid_to_world(pos) + Vector2(half, half)
		var item = _veins[pos]
		
		# Determinar el color base según el mineral
		var base_color = Color.WHITE
		if item.id == "iron_ore": base_color = Color.LIGHT_SLATE_GRAY
		elif item.id == "copper_ore": base_color = Color.PERU
		
		# Generador de números aleatorios con semilla determinista basada en la posición,
		# para que las rocas no "bailen" en cada frame y siempre estén en el mismo sitio.
		var rng = RandomNumberGenerator.new()
		rng.seed = pos.x * 73856 + pos.y * 19349
		
		# Dibujar un fondo oscuro sutil para la veta
		draw_rect(Rect2(center - Vector2(half, half), Vector2(cell_size, cell_size)), Color(0.1, 0.1, 0.1, 0.4), true)
		
		# Dibujar 5 "rocas" procedurales
		for i in range(5):
			var offset = Vector2(rng.randf_range(-half*0.7, half*0.7), rng.randf_range(-half*0.7, half*0.7))
			var rock_size = rng.randf_range(3.0, 7.0)
			var shade = rng.randf_range(0.0, 0.4)
			draw_circle(center + offset, rock_size, base_color.darkened(shade))

func register_vein(grid_pos: Vector2i, resource: ItemData) -> void:
	_veins[grid_pos] = resource
	queue_redraw()

func get_resource_at(grid_pos: Vector2i) -> ItemData:
	return _veins.get(grid_pos, null)

func extract_resource(grid_pos: Vector2i) -> ItemData:
	return get_resource_at(grid_pos)
