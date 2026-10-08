class_name Main
extends Node2D

var current_mode: BuildToolbar.BuildMode = BuildToolbar.BuildMode.NONE
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
var laboratories: Array[Laboratory] = []
var inserters: Array[Inserter] = []

var all_recipes: Array[RecipeData] = []
var machine_ui: MachineUI
var tech_ui: TechUI
var tech_manager: TechManager

var iron_ore: ItemData
var iron_ingot: ItemData
var copper_ore: ItemData
var copper_ingot: ItemData
var iron_gear: ItemData

# --- NUEVO: Sistema de Inventario y Costes ---
var player_inventory: Dictionary = {}
var build_costs: Dictionary = {}

func _ready() -> void:
	var ground = GroundRenderer.new()
	add_child(ground)
	
	cursor.main_node = self
	machine_renderer.main_node = self
	
	tech_manager = TechManager.new()
	
	machine_ui = MachineUI.new()
	add_child(machine_ui)
	
	tech_ui = TechUI.new()
	add_child(tech_ui)
	tech_ui.setup(tech_manager)
	
	simulation.simulation_ticked.connect(_on_simulation_ticked)
	_setup_materials_and_recipes()
	_generate_ore_veins()
	_update_ui_text()

func _create_item(id_name: String, human_name: String, c1: Color, c2: Color) -> ItemData:
	var item = ItemData.new(); item.id = id_name; item.item_name = human_name
	var tex = GradientTexture2D.new(); tex.width = 16; tex.height = 16
	var grad = Gradient.new(); grad.colors = PackedColorArray([c1, c2])
	tex.gradient = grad; item.texture = tex
	return item

func _setup_materials_and_recipes() -> void:
	iron_ore = _create_item("iron_ore", "Mena de Hierro", Color.SLATE_GRAY, Color.LIGHT_SLATE_GRAY)
	iron_ingot = _create_item("iron_ingot", "Lingote de Hierro", Color.DARK_ORANGE, Color.ORANGE)
	copper_ore = _create_item("copper_ore", "Mena de Cobre", Color.SADDLE_BROWN, Color.PERU)
	copper_ingot = _create_item("copper_ingot", "Lingote de Cobre", Color.CORAL, Color.LIGHT_CORAL)
	iron_gear = _create_item("iron_gear", "Engranaje", Color.DARK_GRAY, Color.GRAY)
	
	var r_iron = RecipeData.new(); r_iron.id = "smelt_iron"; r_iron.processing_ticks = 5
	r_iron.inputs[iron_ore] = 1; r_iron.outputs[iron_ingot] = 1
	all_recipes.append(r_iron)
	
	var r_copper = RecipeData.new(); r_copper.id = "smelt_copper"; r_copper.processing_ticks = 5
	r_copper.inputs[copper_ore] = 1; r_copper.outputs[copper_ingot] = 1
	all_recipes.append(r_copper)
	
	var r_gear = RecipeData.new(); r_gear.id = "craft_gear"; r_gear.processing_ticks = 10
	r_gear.inputs[iron_ingot] = 2; r_gear.outputs[iron_gear] = 1
	all_recipes.append(r_gear)
	
	machine_ui.setup_recipes(all_recipes)
	
	# === INVENTARIO INICIAL ===
	player_inventory[iron_ingot] = 100
	player_inventory[iron_gear] = 50
	
	# === COSTES DE CONSTRUCCIÓN ===
	build_costs[BuildToolbar.BuildMode.BELT] = {iron_ingot: 1}
	build_costs[BuildToolbar.BuildMode.DRILL] = {iron_ingot: 5, iron_gear: 5}
	build_costs[BuildToolbar.BuildMode.SMELTER] = {iron_ingot: 10}
	build_costs[BuildToolbar.BuildMode.CHEST] = {iron_ingot: 2}
	build_costs[BuildToolbar.BuildMode.SPLITTER] = {iron_ingot: 3, iron_gear: 2}
	build_costs[BuildToolbar.BuildMode.MERGER] = {iron_ingot: 3, iron_gear: 2}
	build_costs[BuildToolbar.BuildMode.ASSEMBLER] = {iron_ingot: 15, iron_gear: 10}
	build_costs[BuildToolbar.BuildMode.LABORATORY] = {iron_ingot: 20, copper_ingot: 10, iron_gear: 15}
	build_costs[BuildToolbar.BuildMode.INSERTER] = {iron_ingot: 5, iron_gear: 5}
	
	# === ÁRBOL DE TECNOLOGÍAS ===
	tech_manager.register_tech("logistics_1", "Logistica Básica", "Desbloquea Divisores y Uniones.", {iron_gear: 10})
	tech_manager.register_tech("advanced_processing", "Procesamiento Avanzado", "Permite mejores recetas.", {copper_ingot: 20})
	tech_manager.register_tech("fast_belts", "Cintas Rápidas", "Desbloquea Cintas Rojas (Nivel 2).", {iron_gear: 50, copper_ingot: 50})

func _generate_ore_veins() -> void:
	for x in range(4, 10):
		for y in range(4, 10):
			resource_map.register_vein(Vector2i(x, y), iron_ore)
	for x in range(4, 10):
		for y in range(12, 18):
			resource_map.register_vein(Vector2i(x, y), copper_ore)

func _on_simulation_ticked() -> void:
	for drill in drills: drill.process_tick()
	for smelter in smelters: smelter.process_tick()
	for chest in chests: chest.process_tick()
	for splitter in splitters: splitter.process_tick()
	for merger in mergers: merger.process_tick()
	for assembler in assemblers: assembler.process_tick()
	for lab in laboratories: lab.process_tick()
	for ins in inserters: ins.process_tick()
	
	machine_renderer.queue_redraw()
	belt_renderer.queue_redraw()
	
	# Refrescar UI ocasionalmente si el jugador interactúa con cofres o similar
	# pero es mejor solo cuando construye o cambia para optimizar.

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_ESCAPE: current_mode = BuildToolbar.BuildMode.NONE
			KEY_1: current_mode = BuildToolbar.BuildMode.BELT
			KEY_2: current_mode = BuildToolbar.BuildMode.DRILL
			KEY_3: current_mode = BuildToolbar.BuildMode.SMELTER
			KEY_4: current_mode = BuildToolbar.BuildMode.CHEST
			KEY_5: current_mode = BuildToolbar.BuildMode.DEMOLISH
			KEY_6: current_mode = BuildToolbar.BuildMode.SPLITTER
			KEY_7: current_mode = BuildToolbar.BuildMode.MERGER
			KEY_8: current_mode = BuildToolbar.BuildMode.ASSEMBLER
			KEY_9: current_mode = BuildToolbar.BuildMode.LABORATORY
			KEY_0: current_mode = BuildToolbar.BuildMode.INSERTER
			KEY_T: tech_ui.toggle_ui()
			KEY_R: current_rotation = (current_rotation + 1) % 4 as GridSettings.Direction
			KEY_F9: SaveLoadSystem.save_game(self)
			KEY_F10: SaveLoadSystem.load_game(self)
		_update_ui_text()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_handle_click(get_global_mouse_position())

func _get_item_by_id(item_id: StringName) -> ItemData:
	if item_id == &"iron_ore": return iron_ore
	if item_id == &"iron_ingot": return iron_ingot
	if item_id == &"copper_ore": return copper_ore
	if item_id == &"copper_ingot": return copper_ingot
	if item_id == &"iron_gear": return iron_gear
	return null

func _get_recipe_by_id(recipe_id: StringName) -> RecipeData:
	for r in all_recipes:
		if r.id == recipe_id: return r
	return null

func _update_ui_text() -> void:
	var mode_name = "SELECCIONAR / INSPECCIONAR"
	match current_mode:
		BuildToolbar.BuildMode.BELT: mode_name = "CINTA"
		BuildToolbar.BuildMode.DRILL: mode_name = "EXTRACTOR"
		BuildToolbar.BuildMode.SMELTER: mode_name = "FUNDICION"
		BuildToolbar.BuildMode.CHEST: mode_name = "COFRE"
		BuildToolbar.BuildMode.DEMOLISH: mode_name = "DEMOLER"
		BuildToolbar.BuildMode.SPLITTER: mode_name = "DIVISOR"
		BuildToolbar.BuildMode.MERGER: mode_name = "UNION"
		BuildToolbar.BuildMode.ASSEMBLER: mode_name = "ENSAMBLADORA 3x3"
		BuildToolbar.BuildMode.LABORATORY: mode_name = "LABORATORIO 2x2"
		BuildToolbar.BuildMode.INSERTER: mode_name = "BRAZO ROBOTICO (Inserter)"
		
	var cost_text = "Coste: Gratis"
	if build_costs.has(current_mode):
		cost_text = "Coste:\n"
		for item in build_costs[current_mode].keys():
			cost_text += "- " + item.item_name + ": " + str(build_costs[current_mode][item]) + "\n"

	var inv_text = "--- INVENTARIO JUGADOR ---\n"
	for item in player_inventory.keys():
		inv_text += item.item_name + ": " + str(player_inventory[item]) + "\n"

	ui_label.text = "Modo: %s\n\n%s\n%s\nCONTROLES:\nESC: Select/Loot | 1-0: Construir\nT: Arbol Tecnología | 5: Demoler\nR: Rotar | F9/F10: Guardar" % [mode_name, cost_text, inv_text]

func _can_afford(mode: BuildToolbar.BuildMode) -> bool:
	if mode == BuildToolbar.BuildMode.SPLITTER or mode == BuildToolbar.BuildMode.MERGER:
		if not tech_manager.is_unlocked("logistics_1"):
			return false
			
	if not build_costs.has(mode): return true
	var cost = build_costs[mode]
	for item in cost.keys():
		if player_inventory.get(item, 0) < cost[item]: return false
	return true

func _pay_cost(mode: BuildToolbar.BuildMode) -> void:
	if not build_costs.has(mode): return
	var cost = build_costs[mode]
	for item in cost.keys():
		player_inventory[item] -= cost[item]
	_update_ui_text()

func _refund_cost_for_entity(entity: Variant) -> void:
	var mode = BuildToolbar.BuildMode.NONE
	if entity is BeltCell: mode = BuildToolbar.BuildMode.BELT
	elif entity is MiningDrill: mode = BuildToolbar.BuildMode.DRILL
	elif entity is Smelter: mode = BuildToolbar.BuildMode.SMELTER
	elif entity is StorageChest: mode = BuildToolbar.BuildMode.CHEST
	elif entity is Splitter: mode = BuildToolbar.BuildMode.SPLITTER
	elif entity is Merger: mode = BuildToolbar.BuildMode.MERGER
	elif entity is Assembler: mode = BuildToolbar.BuildMode.ASSEMBLER
	elif entity is Laboratory: mode = BuildToolbar.BuildMode.LABORATORY
	elif entity is Inserter: mode = BuildToolbar.BuildMode.INSERTER
	
	if build_costs.has(mode):
		var cost = build_costs[mode]
		for item in cost.keys():
			player_inventory[item] = player_inventory.get(item, 0) + cost[item]

func _handle_click(mouse_pos: Vector2) -> void:
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	
	if current_mode == BuildToolbar.BuildMode.NONE:
		var entity = grid_manager.get_entity_at(grid_pos)
		
		# SAQUEAR COFRE
		if entity is StorageChest:
			var something_looted = false
			for item in entity.inventory.keys():
				player_inventory[item] = player_inventory.get(item, 0) + entity.inventory[item]
				something_looted = true
			if something_looted:
				entity.inventory.clear()
				entity.current_total = 0
				_update_ui_text()
			return
			
		if entity != null and not (entity is BeltCell):
			machine_ui.open_for_machine(entity)
		else:
			machine_ui.panel.visible = false
		return
		
	if current_mode != BuildToolbar.BuildMode.DEMOLISH:
		if not _can_afford(current_mode):
			return # No tenemos recursos, no hace nada (se podría añadir parpadeo rojo)
			
	match current_mode:
		BuildToolbar.BuildMode.BELT:
			var belt = BeltCell.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, belt):
				simulation.register_belt(belt); belts.append(belt)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.DRILL:
			var drill = MiningDrill.new(grid_pos, current_rotation, resource_map)
			if grid_manager.occupy_cell(grid_pos, drill):
				drills.append(drill)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.SMELTER:
			var smelter = Smelter.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, smelter):
				smelters.append(smelter)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.CHEST:
			var chest = StorageChest.new(grid_pos)
			if grid_manager.occupy_cell(grid_pos, chest):
				chests.append(chest)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.SPLITTER:
			var splitter = Splitter.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, splitter):
				splitters.append(splitter)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.MERGER:
			var merger = Merger.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, merger):
				mergers.append(merger)
				_reconnect_adjacent_area(grid_pos, Vector2i(1,1))
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.ASSEMBLER:
			var size = GridSettings.get_rotated_size(Vector2i(3,3), current_rotation)
			var assembler = Assembler.new(grid_pos, current_rotation)
			if grid_manager.occupy_area(grid_pos, size, assembler):
				assemblers.append(assembler)
				_reconnect_adjacent_area(grid_pos, size)
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.LABORATORY:
			var size = GridSettings.get_rotated_size(Vector2i(2,2), current_rotation)
			var lab = Laboratory.new(grid_pos, tech_manager)
			if grid_manager.occupy_area(grid_pos, size, lab):
				laboratories.append(lab)
				_reconnect_adjacent_area(grid_pos, size)
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.INSERTER:
			var ins = Inserter.new(grid_pos, current_rotation, self)
			if grid_manager.occupy_cell(grid_pos, ins):
				inserters.append(ins)
				# No necesitamos re-conectar nada porque el inserter busca en tiempo real
				_pay_cost(current_mode)
				
		BuildToolbar.BuildMode.DEMOLISH:
			var entity = grid_manager.get_entity_at(grid_pos)
			if entity == null: return
			
			var base_pos = grid_pos
			var size = Vector2i(1,1)
			if entity is Assembler:
				base_pos = entity.grid_position
				size = entity.current_size
			elif entity is Laboratory:
				base_pos = entity.grid_position
				size = entity.current_size
				
			grid_manager.free_cell(grid_pos)
			
			if entity is BeltCell:
				simulation.unregister_belt(entity); belts.erase(entity)
			elif entity is MiningDrill: drills.erase(entity)
			elif entity is Smelter: smelters.erase(entity)
			elif entity is StorageChest:
				for item in entity.inventory.keys():
					player_inventory[item] = player_inventory.get(item, 0) + entity.inventory[item]
				chests.erase(entity)
			elif entity is Splitter: splitters.erase(entity)
			elif entity is Merger: mergers.erase(entity)
			elif entity is Assembler: assemblers.erase(entity)
			elif entity is Laboratory: laboratories.erase(entity)
			elif entity is Inserter:
				if entity.held_item != null:
					player_inventory[entity.held_item] = player_inventory.get(entity.held_item, 0) + 1
				inserters.erase(entity)
			
			_refund_cost_for_entity(entity)
			_update_ui_text()
			_reconnect_adjacent_area(base_pos, size)
			
	machine_renderer.queue_redraw()
	belt_renderer.queue_redraw()

func _reconnect_adjacent_area(base_pos: Vector2i, size: Vector2i) -> void:
	var positions_to_update: Dictionary = {}
	for x in range(size.x):
		for y in range(size.y):
			var p = base_pos + Vector2i(x, y)
			positions_to_update[p] = true
			positions_to_update[p + Vector2i.UP] = true
			positions_to_update[p + Vector2i.DOWN] = true
			positions_to_update[p + Vector2i.LEFT] = true
			positions_to_update[p + Vector2i.RIGHT] = true
	
	for pos in positions_to_update.keys():
		var ent = grid_manager.get_entity_at(pos)
		if ent == null: continue
		if ent is BeltCell: ent.next_cell = null
		elif ent is MiningDrill: ent.output_belt = null
		elif ent is Splitter: ent.output_belts = [null, null, null]
		elif ent is Smelter: ent.input_belt = null; ent.output_belt = null
		elif ent is Merger: ent.input_belts = [null, null, null]; ent.output_belt = null
		elif ent is StorageChest: ent.input_belt = null
		elif ent is Assembler: ent.input_belts.clear(); ent.output_belts.clear()
		elif ent is Laboratory: ent.input_belts.clear()
	
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
			elif target is Laboratory: target.input_belts.append(ent)
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
	# Iterar sobre las celdas ocupadas reales en lugar de un rango fijo quemado en código
	for pos in grid_manager._cells.keys():
		_reconnect_adjacent_area(pos, Vector2i(1,1))
