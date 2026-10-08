class_name Merger
extends RefCounted

var grid_position: Vector2i
var direction: GridSettings.Direction

## Entradas posibles: 0=Frente, 1=Izquierda, 2=Derecha (Relativas a la dirección opuesta)
var input_belts: Array[BeltCell] = [null, null, null]
var output_belt: BeltCell = null

var _last_input_index: int = -1

func _init(pos: Vector2i, dir: GridSettings.Direction) -> void:
	self.grid_position = pos
	self.direction = dir

func process_tick() -> void:
	if output_belt == null or not output_belt.is_slot_empty(1):
		return # Atasco en la salida
		
	# Identificamos qué cintas de entrada tienen ítems listos para entregar (Slot 0)
	var valid_inputs: Array[BeltCell] = []
	for belt in input_belts:
		if belt != null and not belt.is_slot_empty(0):
			valid_inputs.append(belt)
			
	if valid_inputs.is_empty():
		return
		
	# Round-Robin para dar prioridad equitativa a todas las cintas que convergen
	_last_input_index = (_last_input_index + 1) % valid_inputs.size()
	var chosen_input: BeltCell = valid_inputs[_last_input_index]
	
	# Extraer de la entrada e inyectar a la salida atómicamente
	var item: ItemData = chosen_input.extract_item(0)
	output_belt.put_item(1, item)
