class_name Splitter
extends RefCounted

var grid_position: Vector2i
var direction: GridSettings.Direction

var input_belt: BeltCell = null
## Salidas posibles: 0=Frente, 1=Izquierda, 2=Derecha (Relativas a la dirección del Splitter)
var output_belts: Array[BeltCell] = [null, null, null]

var _last_output_index: int = -1

func _init(pos: Vector2i, dir: GridSettings.Direction) -> void:
	self.grid_position = pos
	self.direction = dir

func process_tick() -> void:
	if input_belt == null or input_belt.is_slot_empty(0):
		return
		
	# Identificamos qué cintas de salida están conectadas y tienen espacio (Slot 1 libre)
	var valid_outputs: Array[BeltCell] = []
	for belt in output_belts:
		if belt != null and belt.is_slot_empty(1):
			valid_outputs.append(belt)
			
	if valid_outputs.is_empty():
		return # Atasco
		
	# Round-Robin: repartir equitativamente
	_last_output_index = (_last_output_index + 1) % valid_outputs.size()
	var chosen_belt: BeltCell = valid_outputs[_last_output_index]
	
	# Extraer e inyectar atómicamente
	var item: ItemData = input_belt.extract_item(0)
	chosen_belt.put_item(1, item)
