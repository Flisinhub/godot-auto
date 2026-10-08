class_name Main
extends Node2D

var current_mode: BuildToolbar.BuildMode = BuildToolbar.BuildMode.NONE
var current_rotation: GridSettings.Direction = GridSettings.Direction.UP

## Instancias lógicas base
var grid_manager: GridManager = GridManager.new()

## Referencias a nodos en el SceneTree
@onready var simulation: FactorySimulation = $FactorySimulation
@onready var resource_map: ResourceMap = $ResourceMap
@onready var cursor: GridCursor = $GridCursor

## Contenedores para las máquinas registradas que requieren tick
var drills: Array[MiningDrill] = []
var smelters: Array[Smelter] = []
var chests: Array[StorageChest] = []

func _ready() -> void:
	simulation.simulation_ticked.connect(_on_simulation_ticked)

## El bucle de ejecución maestro. Desacopla la lógica de las máquinas del _process visual
func _on_simulation_ticked() -> void:
	for drill in drills:
		drill.process_tick()
	for smelter in smelters:
		smelter.process_tick()
	for chest in chests:
		chest.process_tick()

func _input(event: InputEvent) -> void:
	# Rotación con tecla R
	if event is InputEventKey and event.keycode == KEY_R and event.is_pressed() and not event.is_echo():
		current_rotation = (current_rotation + 1) % 4 as GridSettings.Direction
		# Aquí podríamos rotar visualmente el cursor
		
	# Colocación con Clic Izquierdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_handle_build_click(get_global_mouse_position())

func _handle_build_click(mouse_pos: Vector2) -> void:
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	
	match current_mode:
		BuildToolbar.BuildMode.BELT:
			var belt = BeltCell.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, belt):
				simulation.register_belt(belt)
				# Aquí iría el código para enlazar _reconnect_belts()
				
		BuildToolbar.BuildMode.DRILL:
			var drill = MiningDrill.new(grid_pos, current_rotation, resource_map)
			if grid_manager.occupy_cell(grid_pos, drill):
				drills.append(drill)
				
		BuildToolbar.BuildMode.SMELTER:
			var smelter = Smelter.new(grid_pos, current_rotation)
			if grid_manager.occupy_cell(grid_pos, smelter):
				smelters.append(smelter)
				
		BuildToolbar.BuildMode.CHEST:
			var chest = StorageChest.new(grid_pos)
			if grid_manager.occupy_cell(grid_pos, chest):
				chests.append(chest)
				
		BuildToolbar.BuildMode.DEMOLISH:
			var entity = grid_manager.free_cell(grid_pos)
			if entity is BeltCell:
				simulation.unregister_belt(entity)
			elif entity is MiningDrill:
				drills.erase(entity)
			elif entity is Smelter:
				smelters.erase(entity)
			elif entity is StorageChest:
				chests.erase(entity)
