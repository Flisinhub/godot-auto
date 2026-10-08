class_name Assembler
extends RefCounted

var grid_position: Vector2i
var direction: GridSettings.Direction

## Tamaño original antes de rotar (3x3)
const BASE_SIZE: Vector2i = Vector2i(3, 3)

## Tamaño rotado real
var current_size: Vector2i

## Puertos locales (relativos al tamaño original 3x3)
## Por ejemplo: 2 entradas a la izquierda, 1 salida a la derecha
const LOCAL_INPUT_PORTS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(-1, 2)]
const LOCAL_OUTPUT_PORTS: Array[Vector2i] = [Vector2i(3, 1)]

## Puertos globales calculados tras la rotación (para el GridManager)
var global_input_ports: Array[Vector2i] = []
var global_output_ports: Array[Vector2i] = []

## Referencias dinámicas a las cintas (conectadas por el Main)
var input_belts: Array[BeltCell] = []
var output_belts: Array[BeltCell] = []

var active_recipe: RecipeData = null
var input_inventory: Dictionary[ItemData, int] = {}
var output_inventory: Dictionary[ItemData, int] = {}

var max_input_capacity: int = 10
var max_output_capacity: int = 10
var is_working: bool = false
var _current_ticks: int = 0

func _init(pos: Vector2i, dir: GridSettings.Direction) -> void:
	self.grid_position = pos
	self.direction = dir
	self.current_size = GridSettings.get_rotated_size(BASE_SIZE, dir)
	
	# Calcular coordenadas globales de los puertos
	for local_in in LOCAL_INPUT_PORTS:
		var rotated = GridSettings.rotate_local_offset(local_in, BASE_SIZE, dir)
		global_input_ports.append(pos + rotated)
		
	for local_out in LOCAL_OUTPUT_PORTS:
		var rotated = GridSettings.rotate_local_offset(local_out, BASE_SIZE, dir)
		global_output_ports.append(pos + rotated)

func process_tick() -> void:
	_absorb_inputs()
	
	if _can_process_recipe():
		is_working = true
		_current_ticks += 1
		
		if _current_ticks >= active_recipe.processing_ticks:
			_current_ticks = 0
			_complete_recipe()
	else:
		is_working = false
		_current_ticks = 0
		
	_expel_outputs()

func _absorb_inputs() -> void:
	if active_recipe == null: return
	
	for belt in input_belts:
		if belt != null and not belt.is_slot_empty(0):
			var item: ItemData = belt.get_item(0)
			if active_recipe.inputs.has(item):
				var qty = input_inventory.get(item, 0)
				if qty < max_input_capacity:
					input_inventory[item] = qty + 1
					belt.extract_item(0)

func _expel_outputs() -> void:
	if output_inventory.is_empty(): return
	
	for belt in output_belts:
		if belt != null and belt.is_slot_empty(1):
			# Intentar sacar un producto
			for item: ItemData in output_inventory.keys():
				var qty = output_inventory[item]
				if qty > 0:
					output_inventory[item] = qty - 1
					belt.put_item(1, item)
					if output_inventory[item] == 0:
						output_inventory.erase(item)
					break # Solo expulsa 1 ítem por tick en esta cinta

func _can_process_recipe() -> bool:
	if active_recipe == null: return false
	for item: ItemData in active_recipe.inputs.keys():
		if input_inventory.get(item, 0) < active_recipe.inputs[item]: return false
	for item: ItemData in active_recipe.outputs.keys():
		if output_inventory.get(item, 0) >= max_output_capacity: return false
	return true

func _complete_recipe() -> void:
	for item: ItemData in active_recipe.inputs.keys():
		input_inventory[item] -= active_recipe.inputs[item]
	for item: ItemData in active_recipe.outputs.keys():
		var gen = active_recipe.outputs[item]
		output_inventory[item] = output_inventory.get(item, 0) + gen
