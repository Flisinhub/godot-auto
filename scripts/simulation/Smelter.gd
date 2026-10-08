class_name Smelter
extends RefCounted

var grid_position: Vector2i
var direction: GridSettings.Direction

## Puertos lógicos de conexión para el GridManager
var input_port_pos: Vector2i
var output_port_pos: Vector2i

## Referencias a las cintas de las cuales absorberá e inyectará
var input_belt: BeltCell = null
var output_belt: BeltCell = null

var active_recipe: RecipeData = null

## Búferes internos desacoplados
var input_inventory: Dictionary[ItemData, int] = {}
var output_inventory: Dictionary[ItemData, int] = {}

var max_input_capacity: int = 10
var max_output_capacity: int = 10

var is_working: bool = false
var _current_ticks: int = 0

func _init(pos: Vector2i, dir: GridSettings.Direction) -> void:
	self.grid_position = pos
	self.direction = dir
	
	# Por convención (Microtarea 4.4):
	# El puerto de entrada está en la celda trasera, el de salida en la frontal.
	var dir_vec: Vector2i = GridSettings.get_direction_vector(dir)
	self.output_port_pos = pos + dir_vec
	self.input_port_pos = pos - dir_vec

## Llamado por FactorySimulation. Bucle central de transformación (Microtarea 4.3).
func process_tick() -> void:
	_absorb_inputs()
	
	if _can_process_recipe():
		is_working = true
		_current_ticks += 1
		
		# Descuenta insumos y añade productos al cumplir el ciclo
		if _current_ticks >= active_recipe.processing_ticks:
			_current_ticks = 0
			_complete_recipe()
	else:
		is_working = false
		_current_ticks = 0
		
	_expel_outputs()

## Absorbe activamente de la cinta de entrada (Microtarea 4.4)
func _absorb_inputs() -> void:
	if input_belt == null or active_recipe == null:
		return
		
	# Absorbe de la ranura FRONTAL (Slot 0) de la cinta que apunta a la fundición
	if not input_belt.is_slot_empty(0):
		var item: ItemData = input_belt.get_item(0)
		
		# Validar compatibilidad estricta con la receta
		if active_recipe.inputs.has(item):
			var current_qty: int = input_inventory.get(item, 0)
			if current_qty < max_input_capacity:
				input_inventory[item] = current_qty + 1
				input_belt.extract_item(0) # Lo remueve de la cinta

## Expulsa los productos manufacturados hacia la cinta de salida (Microtarea 4.4)
func _expel_outputs() -> void:
	if output_belt == null or output_inventory.is_empty():
		return
		
	# Expulsa hacia la ranura TRASERA (Slot 1) de la cinta siguiente
	if output_belt.is_slot_empty(1):
		for item: ItemData in output_inventory.keys():
			var qty: int = output_inventory[item]
			if qty > 0:
				output_inventory[item] = qty - 1
				output_belt.put_item(1, item)
				
				# Limpieza de memoria para no arrastrar claves vacías
				if output_inventory[item] == 0:
					output_inventory.erase(item)
				break # Límite de expulsión atómica: 1 por tick

## Lógica booleana de seguridad para buffers (Microtarea 4.2)
func _can_process_recipe() -> bool:
	if active_recipe == null:
		return false
		
	# Verificar disponibilidad exacta de insumos
	for item: ItemData in active_recipe.inputs.keys():
		if input_inventory.get(item, 0) < active_recipe.inputs[item]:
			return false
			
	# Verificar que el búfer de salida no se desborde
	for item: ItemData in active_recipe.outputs.keys():
		if output_inventory.get(item, 0) >= max_output_capacity:
			return false
			
	return true

## Transacción atómica de manufactura
func _complete_recipe() -> void:
	for item: ItemData in active_recipe.inputs.keys():
		input_inventory[item] -= active_recipe.inputs[item]
		
	for item: ItemData in active_recipe.outputs.keys():
		var generated_qty: int = active_recipe.outputs[item]
		output_inventory[item] = output_inventory.get(item, 0) + generated_qty
