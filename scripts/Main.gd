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

var debug_iron_ore: ItemData
var debug_iron_ingot: ItemData
var debug_recipe: RecipeData

func _ready() -> void:
	# Vincular referencias UI
	cursor.main_node = self
	machine_renderer.main_node = self
	
	simulation.simulation_ticked.connect(_on_simulation_ticked)
	_setup_debug_data()
	_generate_ore_veins()
	_update_ui_text()

func _setup_debug_data() -> void:
	debug_iron_ore = ItemData.new()
	debug_iron_ore.id = &"iron_ore"
	var tex_ore = GradientTexture2D.new()
	tex_ore.width = 16; tex_ore.height = 16
	var grad_ore = Gradient.new()
	grad_ore.colors = PackedColorArray([Color.SLATE_GRAY, Color.LIGHT_SLATE_GRAY])
	tex_ore.gradient = grad_ore
	debug_iron_ore.texture = tex_ore
	
	debug_iron_ingot = ItemData.new()
	debug_iron_ingot.id = &"iron_ingot"
	var tex_ingot = GradientTexture2D.new()
	tex_ingot.width = 16; tex_ingot.height = 16
	var grad_ingot = Gradient.new()
	grad_ingot.colors = PackedColorArray([Color.DARK_ORANGE, Color.ORANGE])
	tex_ingot.gradient = grad_ingot
	debug_iron_ingot.texture = tex_ingot
	
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
		
	var rot_name = "ARRIBA"
	match current_rotation:
		GridSettings.Direction.UP: rot_name = "ARRIBA"
		GridSettings.Direction.RIGHT: rot_name = "DERECHA"
		GridSettings.Direction.DOWN: rot_name = "ABAJO"
		GridSettings.Direction.LEFT: rot_name = "IZQUIERDA"

	ui_label.text = "Modo: %s\nRotacion: %s\n\n1:Cinta | 2:Extractor | 3:Fundicion | 4:Cofre\n5:Demoler | 6:Divisor | 7:Union\nR:Rotar | F9:Guardar | F10:Cargar" % [mode_name, rot_name]

func _handle_build_click(mouse_pos: Vector2) -> void:
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	
	match current_mode:
		BuildToolbar.BuildMode.BELT:
			var belt = BeltCell.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, belt):
				simulation.register_belt(belt)
				belts.append(belt)
				_reconnect_adjacent(grid_pos)
				
		BuildToolbar.BuildMode.DRILL:
			var drill = MiningDrill.new(grid_pos, current_rotation, resource_map)
			if grid_manager.occupy_cell(grid_pos, drill):
				drills.append(drill)
				_reconnect_adjacent(grid_pos)
				
		BuildToolbar.BuildMode.SMELTER:
			var smelter = Smelter.new(grid_pos, current_rotation)
			smelter.active_recipe = debug_recipe
			if grid_manager.occupy_cell(grid_pos, smelter):
				smelters.append(smelter)
				_reconnect_adjacent(grid_pos)
				
		BuildToolbar.BuildMode.CHEST:
			var chest = StorageChest.new(grid_pos)
			if grid_manager.occupy_cell(grid_pos, chest):
				chests.append(chest)
				_reconnect_adjacent(grid_pos)
				
		BuildToolbar.BuildMode.SPLITTER:
			var splitter = Splitter.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, splitter):
				splitters.append(splitter)
				_reconnect_adjacent(grid_pos)
				
		BuildToolbar.BuildMode.MERGER:
			var merger = Merger.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, merger):
				mergers.append(merger)
				_reconnect_adjacent(grid_pos)
				
		BuildToolbar.BuildMode.DEMOLISH:
			var entity = grid_manager.free_cell(grid_pos)
			if entity is BeltCell:
				simulation.unregister_belt(entity)
				belts.erase(entity)
			elif entity is MiningDrill: drills.erase(entity)
			elif entity is Smelter: smelters.erase(entity)
			elif entity is StorageChest: chests.erase(entity)
			elif entity is Splitter: splitters.erase(entity)
			elif entity is Merger: mergers.erase(entity)
			_reconnect_adjacent(grid_pos)
			
	machine_renderer.queue_redraw()
	belt_renderer.queue_redraw()

## OPTIMIZACIÓN (Bloque 2): Actualización Delta. Solo reconecta la celda afectada y sus vecinos.
func _reconnect_adjacent(center_pos: Vector2i) -> void:
	var positions_to_update = [
		center_pos,
		center_pos + Vector2i.UP,
		center_pos + Vector2i.DOWN,
		center_pos + Vector2i.LEFT,
		center_pos + Vector2i.RIGHT
	]
	
	for pos in positions_to_update:
		var ent = grid_manager.get_entity_at(pos)
		if ent == null: continue
		
		# Limpiar enlaces salientes de esta entidad para recalcular
		if ent is BeltCell: ent.next_cell = null
		elif ent is MiningDrill: ent.output_belt = null
		elif ent is Splitter: ent.output_belts = [null, null, null]
		# Cofres, Fundiciones y Mergers tienen sus "inputs" gestionados desde la perspectiva del Belt, pero los outputs de Fundiciones/Mergers sí deben limpiarse
		elif ent is Smelter:
			ent.input_belt = null
			ent.output_belt = null
		elif ent is Merger:
			ent.input_belts = [null, null, null]
			ent.output_belt = null
		elif ent is StorageChest:
			ent.input_belt = null
	
	# Recalcular todos los enlaces para las entidades afectadas
	for pos in positions_to_update:
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
				elif relative.x == -m_dir.y and relative.y == m_dir.x: target.input_belts[1] = ent # Derecha local
				else: target.input_belts[2] = ent # Izquierda local
				
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
			var target_pos = ent.output_port_pos
			var target = grid_manager.get_entity_at(target_pos)
			if target is BeltCell: ent.output_belt = target

	simulation._sort_belts_topologically()

## Fallback público para cuando se carga el juego completo
func _reconnect_all() -> void:
	for x in range(-100, 100):
		for y in range(-100, 100):
			if not grid_manager.is_empty(Vector2i(x, y)):
				_reconnect_adjacent(Vector2i(x, y))
