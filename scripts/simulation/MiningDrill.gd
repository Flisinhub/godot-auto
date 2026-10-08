class_name MiningDrill
extends RefCounted

var grid_position: Vector2i
var direction: GridSettings.Direction

## Referencia a la cinta receptora (BeltCell) adyacente a su salida
var output_belt: BeltCell = null

## Referencia al mapa geológico
var resource_map: ResourceMap = null
var current_ore: ItemData = null

## Velocidad en pasos lógicos (ticks) para extraer un mineral
var mining_speed_ticks: int = 5
var _current_ticks: int = 0

## Búfer de egreso: solo retiene un mineral ya extraído esperando salir
var output_buffer: ItemData = null

## Indicador de estado para el nodo de renderizado visual
var is_working: bool = false

func _init(pos: Vector2i, dir: GridSettings.Direction, map: ResourceMap) -> void:
	self.grid_position = pos
	self.direction = dir
	self.resource_map = map
	self.current_ore = map.get_resource_at(pos)

## Este método debe ser invocado por FactorySimulation en cada _tick()
func process_tick() -> void:
	if current_ore == null:
		is_working = false
		return
		
	# 1. Intentar inyectar el mineral si ya hay uno terminado en el búfer
	if output_buffer != null:
		_try_inject_to_belt()
		
	# 2. Si el búfer está libre, la perforadora trabaja
	if output_buffer == null:
		is_working = true
		_current_ticks += 1
		
		# Si cumple su ciclo, extrae físicamente el material al búfer
		if _current_ticks >= mining_speed_ticks:
			_current_ticks = 0
			output_buffer = resource_map.extract_resource(grid_position)
	else:
		# El búfer sigue lleno (la cinta está atascada). Nos detenemos por completo.
		is_working = false

## Intenta depositar el mineral en la ranura de entrada (Slot 1) de la cinta conectada
func _try_inject_to_belt() -> void:
	if output_belt != null:
		# Nota: Acorde a nuestra arquitectura, la ranura TRASERA (entrada) es slot 1.
		if output_belt.is_slot_empty(1):
			output_belt.put_item(1, output_buffer)
			output_buffer = null
