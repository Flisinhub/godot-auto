class_name Main
extends Node2D

var current_mode: BuildToolbar.BuildMode = BuildToolbar.BuildMode.BELT
var current_rotation: GridSettings.Direction = GridSettings.Direction.UP

var grid_manager: GridManager = GridManager.new()

@onready var simulation: FactorySimulation = $FactorySimulation
@onready var resource_map: ResourceMap = $ResourceMap
@onready var ui_label: Label = $UI/Instructions
@onready var machine_renderer: Node2D = $MachineRenderer
@onready var belt_renderer: BeltRenderer = $BeltRenderer
@onready var cursor: GridCursor = $GridCursor

var drills: Array[MiningDrill] = []
var smelters: Array[Smelter] = []
var chests: Array[StorageChest] = []
var belts: Array[BeltCell] = []
var splitters: Array[Splitter] = []
var mergers: Array[Merger] = []
var assemblers: Array[Assembler] = []

var debug_iron_ore: ItemData
var debug_iron_ingot: ItemData
var debug_recipe: RecipeData

func _ready() -> void:
	cursor.main_node = self
	machine_renderer.main_node = self
	
	simulation.simulation_ticked.connect(_on_simulation_ticked)
	_setup_debug_data()
	_generate_ore_veins()
	_update_ui_text()

func _setup_debug_data() -> void:
	debug_iron_ore = ItemData.new(); debug_iron_ore.id = &"iron_ore"
	var tex_ore = GradientTexture2D.new(); tex_ore.width = 16; tex_ore.height = 16
	var grad_ore = Gradient.new(); grad_ore.colors = PackedColorArray([Color.SLATE_GRAY, Color.LIGHT_SLATE_GRAY])
	tex_ore.gradient = grad_ore; debug_iron_ore.texture = tex_ore
	
	debug_iron_ingot = ItemData.new(); debug_iron_ingot.id = &"iron_ingot"
	var tex_ingot = GradientTexture2D.new(); tex_ingot.width = 16; tex_ingot.height = 16
	var grad_ingot = Gradient.new(); grad_ingot.colors = PackedColorArray([Color.DARK_ORANGE, Color.ORANGE])
	tex_ingot.gradient = grad_ingot; debug_iron_ingot.texture = tex_ingot
	
	debug_recipe = RecipeData.new()
	debug_recipe.processing_ticks = 10
	debug_recipe.inputs[debug_iron_ore] = 1
	debug_recipe.outputs[debug_iron_ingot] = 1

func _generate_ore_veins() -> void:
	for x in range(4, 12):
		for y in range(4, 12):
			resource_map.register_vein(Vector2i(x, y), debug_iron_ore)

func _on_simulation_ticked() -> void:
	for drill in drills: drill.process_tick()
	for smelter in smelters: smelter.process_tick()
	for chest in chests: chest.process_tick()
	for splitter in splitters: splitter.process_tick()
	for merger in mergers: merger.process_tick()
	for assembler in assemblers: assembler.process_tick()
	
	machine_renderer.queue_redraw()
	belt_renderer.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1: current_mode = BuildToolbar.BuildMode.BELT
			KEY_2: current_mode = BuildToolbar.BuildMode.DRILL
			KEY_3: current_mode = BuildToolbar.BuildMode.SMELTER
			KEY_4: current_mode = BuildToolbar.BuildMode.CHEST
			KEY_5: current_mode = BuildToolbar.BuildMode.DEMOLISH
			KEY_6: current_mode = BuildToolbar.BuildMode.SPLITTER
			KEY_7: current_mode = BuildToolbar.BuildMode.MERGER
			KEY_8: current_mode = BuildToolbar.BuildMode.ASSEMBLER
			KEY_R: current_rotation = (current_rotation + 1) % 4 as GridSettings.Direction
			KEY_F9: SaveLoadSystem.save_game(self)
			KEY_F10: SaveLoadSystem.load_game(self)
		_update_ui_text()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_handle_build_click(get_global_mouse_position())

func _update_ui_text() -> void:
	var mode_name = "NINGUNO"
	match current_mode:
		BuildToolbar.BuildMode.BELT: mode_name = "CINTA (Gris)"
		BuildToolbar.BuildMode.DRILL: mode_name = "EXTRACTOR (Amarillo)"
		BuildToolbar.BuildMode.SMELTER: mode_name = "FUNDICION (Naranja)"
		BuildToolbar.BuildMode.CHEST: mode_name = "COFRE (Verde)"
		BuildToolbar.BuildMode.DEMOLISH: mode_name = "DEMOLER (Rojo)"
		BuildToolbar.BuildMode.SPLITTER: mode_name = "DIVISOR (Cian)"
		BuildToolbar.BuildMode.MERGER: mode_name = "UNION (Magenta)"
		BuildToolbar.BuildMode.ASSEMBLER: mode_name = "ENSAMBLADORA 3x3 (Azul)"
		
	var rot_name = "ARRIBA"
	match current_rotation:
		GridSettings.Direction.UP: rot_name = "ARRIBA"
		GridSettings.Direction.RIGHT: rot_name = "DERECHA"
		GridSettings.Direction.DOWN: rot_name = "ABAJO"
		GridSettings.Direction.LEFT: rot_name = "IZQUIERDA"

	ui_label.text = "Modo: %s\nRotacion: %s\n\n1:Cinta | 2:Extractor | 3:Fundicion | 4:Cofre\n5:Demoler | 6:Divisor | 7:Union | 8:Ensambladora 3x3\nR:Rotar | F9:Guardar | F10:Cargar" % [mode_name, rot_name]

func _handle_build_click(mouse_pos: Vector2) -> void:
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	
	match current_mode:
		BuildToolbar.BuildMode.BELT:
			var belt = BeltCell.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, belt):
				simulation.register_belt(belt)
				belts.append(belt)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				
		BuildToolbar.BuildMode.DRILL:
			var drill = MiningDrill.new(grid_pos, current_rotation, resource_map)
			if grid_manager.occupy_cell(grid_pos, drill):
				drills.append(drill)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				
		BuildToolbar.BuildMode.SMELTER:
			var smelter = Smelter.new(grid_pos, current_rotation)
			smelter.active_recipe = debug_recipe
			if grid_manager.occupy_cell(grid_pos, smelter):
				smelters.append(smelter)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				
		BuildToolbar.BuildMode.CHEST:
			var chest = StorageChest.new(grid_pos)
			if grid_manager.occupy_cell(grid_pos, chest):
				chests.append(chest)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				
		BuildToolbar.BuildMode.SPLITTER:
			var splitter = Splitter.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, splitter):
				splitters.append(splitter)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				
		BuildToolbar.BuildMode.MERGER:
			var merger = Merger.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, merger):
				mergers.append(merger)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				
		BuildToolbar.BuildMode.ASSEMBLER:
			var size = GridSettings.get_rotated_size(Vector2i(3,3), current_rotation)
			var assembler = Assembler.new(grid_pos, current_rotation)
			assembler.active_recipe = debug_recipe
			if grid_manager.occupy_area(grid_pos, size, assembler):
				assemblers.append(assembler)
				_reconnect_adjacent_area(grid_pos, size)
				
		BuildToolbar.BuildMode.DEMOLISH:
			var entity = grid_manager.get_entity_at(grid_pos)
			if entity == null: return
			
			var base_pos = grid_pos
			var size = Vector2i(1,1)
			if entity is Assembler:
				base_pos = entity.grid_position
				size = entity.current_size
				
			grid_manager.free_cell(grid_pos) # Esto borra todas las celdas ocupadas por la entidad
			
			if entity is BeltCell:
				simulation.unregister_belt(entity)
				belts.erase(entity)
			elif entity is MiningDrill: drills.erase(entity)
			elif entity is Smelter: smelters.erase(entity)
			elif entity is StorageChest: chests.erase(entity)
			elif entity is Splitter: splitters.erase(entity)
			elif entity is Merger: mergers.erase(entity)
			elif entity is Assembler: assemblers.erase(entity)
			
			_reconnect_adjacent_area(base_pos, size)
			
	machine_renderer.queue_redraw()
	belt_renderer.queue_redraw()

## Actualización Delta expandida para soportar áreas (como 3x3)
func _reconnect_adjacent_area(base_pos: Vector2i, size: Vector2i) -> void:
	var positions_to_update: Dictionary = {}
	
	# Añadimos el área central
	for x in range(size.x):
		for y in range(size.y):
			var p = base_pos + Vector2i(x, y)
			positions_to_update[p] = true
			# Añadimos perímetro (vecinos inmediatos)
			positions_to_update[p + Vector2i.UP] = true
			positions_to_update[p + Vector2i.DOWN] = true
			positions_to_update[p + Vector2i.LEFT] = true
			positions_to_update[p + Vector2i.RIGHT] = true
	
	for pos in positions_to_update.keys():
		var ent = grid_manager.get_entity_at(pos)
		if ent == null: continue
		
		# Limpiar enlaces
		if ent is BeltCell: ent.next_cell = null
		elif ent is MiningDrill: ent.output_belt = null
		elif ent is Splitter: ent.output_belts = [null, null, null]
		elif ent is Smelter:
			ent.input_belt = null; ent.output_belt = null
		elif ent is Merger:
			ent.input_belts = [null, null, null]; ent.output_belt = null
		elif ent is StorageChest:
			ent.input_belt = null
		elif ent is Assembler:
			ent.input_belts.clear(); ent.output_belts.clear()
	
	# Recalcular
	for pos in positions_to_update.keys():
		var ent = grid_manager.get_entity_at(pos)
		if ent == null: continue
		
		if ent is BeltCell:
			var target_pos = ent.grid_position + GridSettings.get_direction_vector(ent.direction)
			var target = grid_manager.get_entity_at(target_pos)
			
			if target is BeltCell: ent.next_cell = target
			elif target is StorageChest: target.input_belt = ent
			elif target is Smelter and target.input_port_pos == target_pos: target.input_belt = ent
			elif target is Splitter: target.input_belt = ent
			elif target is Merger:
				var m_dir = GridSettings.get_direction_vector(target.direction)
				var relative = ent.grid_position - target.grid_position
				if relative == -m_dir: target.input_belts[0] = ent
				elif relative.x == -m_dir.y and relative.y == m_dir.x: target.input_belts[1] = ent
				else: target.input_belts[2] = ent
			elif target is Assembler:
				if target.global_input_ports.has(target_pos):
					target.input_belts.append(ent)
				
		elif ent is MiningDrill:
			var target_pos = ent.grid_position + GridSettings.get_direction_vector(ent.direction)
			var target = grid_manager.get_entity_at(target_pos)
			if target is BeltCell: ent.output_belt = target
			
		elif ent is Splitter:
			var s_dir = GridSettings.get_direction_vector(ent.direction)
			var fronts = [s_dir, Vector2i(-s_dir.y, s_dir.x), Vector2i(s_dir.y, -s_dir.x)]
			for i in range(3):
				var target_pos = ent.grid_position + fronts[i]
				var target = grid_manager.get_entity_at(target_pos)
				if target is BeltCell: ent.output_belts[i] = target
				
		elif ent is Merger:
			var target_pos = ent.grid_position + GridSettings.get_direction_vector(ent.direction)
			var target = grid_manager.get_entity_at(target_pos)
			if target is BeltCell: ent.output_belt = target
			
		elif ent is Smelter:
			var target = grid_manager.get_entity_at(ent.output_port_pos)
			if target is BeltCell: ent.output_belt = target
			
		elif ent is Assembler:
			for out_port in ent.global_output_ports:
				var target = grid_manager.get_entity_at(out_port)
				if target is BeltCell:
					ent.output_belts.append(target)

	simulation._sort_belts_topologically()

func _reconnect_all() -> void:
	for x in range(-50, 50):
		for y in range(-50, 50):
			if not grid_manager.is_empty(Vector2i(x, y)):
				_reconnect_adjacent_area(Vector2i(x, y), Vector2i(1,1))
