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

var drills: Array[MiningDrill] = []
var smelters: Array[Smelter] = []
var chests: Array[StorageChest] = []
var belts: Array[BeltCell] = []

var debug_iron_ore: ItemData
var debug_iron_ingot: ItemData
var debug_recipe: RecipeData

func _ready() -> void:
	simulation.simulation_ticked.connect(_on_simulation_ticked)
	_setup_debug_data()
	_generate_ore_veins()
	_update_ui_text()

## Generamos texturas y recursos por código para no requerir assets externos
func _setup_debug_data() -> void:
	debug_iron_ore = ItemData.new()
	debug_iron_ore.id = &"iron_ore"
	
	var tex_ore = GradientTexture2D.new()
	tex_ore.width = 16
	tex_ore.height = 16
	var grad_ore = Gradient.new()
	grad_ore.colors = PackedColorArray([Color.SLATE_GRAY, Color.LIGHT_SLATE_GRAY])
	tex_ore.gradient = grad_ore
	debug_iron_ore.texture = tex_ore
	
	debug_iron_ingot = ItemData.new()
	debug_iron_ingot.id = &"iron_ingot"
	
	var tex_ingot = GradientTexture2D.new()
	tex_ingot.width = 16
	tex_ingot.height = 16
	var grad_ingot = Gradient.new()
	grad_ingot.colors = PackedColorArray([Color.DARK_ORANGE, Color.ORANGE])
	tex_ingot.gradient = grad_ingot
	debug_iron_ingot.texture = tex_ingot
	
	debug_recipe = RecipeData.new()
	debug_recipe.processing_ticks = 10
	debug_recipe.inputs[debug_iron_ore] = 1
	debug_recipe.outputs[debug_iron_ingot] = 1

func _generate_ore_veins() -> void:
	# Simular una enorme veta en el centro (casillas 4,4 a 12,12)
	for x in range(4, 12):
		for y in range(4, 12):
			resource_map.register_vein(Vector2i(x, y), debug_iron_ore)

func _on_simulation_ticked() -> void:
	for drill in drills: drill.process_tick()
	for smelter in smelters: smelter.process_tick()
	for chest in chests: chest.process_tick()
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
			KEY_R: current_rotation = (current_rotation + 1) % 4 as GridSettings.Direction
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
		
	var rot_name = "ARRIBA"
	match current_rotation:
		GridSettings.Direction.UP: rot_name = "ARRIBA"
		GridSettings.Direction.RIGHT: rot_name = "DERECHA"
		GridSettings.Direction.DOWN: rot_name = "ABAJO"
		GridSettings.Direction.LEFT: rot_name = "IZQUIERDA"

	ui_label.text = "Modo: %s\nRotacion: %s\n\n1: Cinta | 2: Extractor | 3: Fundicion | 4: Cofre | 5: Demoler\nR: Rotar | Clic: Construir" % [mode_name, rot_name]

func _handle_build_click(mouse_pos: Vector2) -> void:
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	
	match current_mode:
		BuildToolbar.BuildMode.BELT:
			var belt = BeltCell.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, belt):
				simulation.register_belt(belt)
				belts.append(belt)
				_reconnect_all()
				
		BuildToolbar.BuildMode.DRILL:
			var drill = MiningDrill.new(grid_pos, current_rotation, resource_map)
			if grid_manager.occupy_cell(grid_pos, drill):
				drills.append(drill)
				_reconnect_all()
				
		BuildToolbar.BuildMode.SMELTER:
			var smelter = Smelter.new(grid_pos, current_rotation)
			smelter.active_recipe = debug_recipe
			if grid_manager.occupy_cell(grid_pos, smelter):
				smelters.append(smelter)
				_reconnect_all()
				
		BuildToolbar.BuildMode.CHEST:
			var chest = StorageChest.new(grid_pos)
			if grid_manager.occupy_cell(grid_pos, chest):
				chests.append(chest)
				_reconnect_all()
				
		BuildToolbar.BuildMode.DEMOLISH:
			var entity = grid_manager.free_cell(grid_pos)
			if entity is BeltCell:
				simulation.unregister_belt(entity)
				belts.erase(entity)
			elif entity is MiningDrill: drills.erase(entity)
			elif entity is Smelter: smelters.erase(entity)
			elif entity is StorageChest: chests.erase(entity)
			_reconnect_all()
			
	machine_renderer.queue_redraw()
	belt_renderer.queue_redraw()

## Reconecta matemáticamente todos los nodos al modificar el grafo
func _reconnect_all() -> void:
	for belt in belts: belt.next_cell = null
	for drill in drills: drill.output_belt = null
	for smelter in smelters:
		smelter.input_belt = null
		smelter.output_belt = null
	for chest in chests: chest.input_belt = null
	
	for belt in belts:
		var target_pos = belt.grid_position + GridSettings.get_direction_vector(belt.direction)
		var ent = grid_manager.get_entity_at(target_pos)
		if ent is BeltCell: belt.next_cell = ent
		elif ent is StorageChest: ent.input_belt = belt
	
	for drill in drills:
		var target_pos = drill.grid_position + GridSettings.get_direction_vector(drill.direction)
		var ent = grid_manager.get_entity_at(target_pos)
		if ent is BeltCell: drill.output_belt = ent
		
	for smelter in smelters:
		var input_ent = grid_manager.get_entity_at(smelter.input_port_pos)
		if input_ent is BeltCell: smelter.input_belt = input_ent
		var output_ent = grid_manager.get_entity_at(smelter.output_port_pos)
		if output_ent is BeltCell: smelter.output_belt = output_ent
		
	simulation._sort_belts_topologically()
