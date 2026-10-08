class_name FactorySimulation
extends Node

signal simulation_ticked

## Frecuencia de los pasos lógicos discretos (en segundos). Ejemplo: 0.2s (5 ticks por segundo)
const TICK_RATE: float = 0.2
var _time_accumulator: float = 0.0

## Lista de todas las cintas activas. Se mantendrá ordenada topológicamente 
## para garantizar que las cintas al final de la línea se procesen primero.
var _belts: Array[BeltCell] = []

func _process(delta: float) -> void:
	_time_accumulator += delta
	# El bucle while asegura que si hay lag, el determinismo matemático no se rompa, 
	# compensando con la ejecución de los ticks pendientes.
	while _time_accumulator >= TICK_RATE:
		_time_accumulator -= TICK_RATE
		_tick()

func _tick() -> void:
	_simulate_belts_backwards()
	simulation_ticked.emit()

## Registra una cinta y recalcula el orden lógico
func register_belt(belt: BeltCell) -> void:
	if not _belts.has(belt):
		_belts.append(belt)
		_sort_belts_topologically()

## Elimina una cinta y actualiza el grafo
func unregister_belt(belt: BeltCell) -> void:
	_belts.erase(belt)
	_sort_belts_topologically()

## MICROTAREA 2.4: Algoritmo de Avance Inverso (Backwards Traversal).
func _simulate_belts_backwards() -> void:
	# Al estar el arreglo ordenado de sumideros a fuentes, iteramos normalmente
	for belt in _belts:
		# 1. Empujar el ítem de la ranura FRONTAL (0) hacia la ranura TRASERA (1) de la celda conectada
		if not belt.is_slot_empty(0):
			if belt.next_cell != null and belt.next_cell.is_slot_empty(1):
				var item: ItemData = belt.extract_item(0)
				belt.next_cell.put_item(1, item)
		
		# 2. Desplazar el ítem de la ranura TRASERA (1) a la FRONTAL (0) dentro de la misma celda
		if not belt.is_slot_empty(1):
			if belt.is_slot_empty(0):
				var item: ItemData = belt.extract_item(1)
				belt.put_item(0, item)

## Aplica Búsqueda en Profundidad (DFS) para ordenar topológicamente el grafo.
## Como insertamos en el arreglo a la salida de la recursión, los sumideros (nodos finales)
## quedarán en el índice 0, garantizando el "backwards traversal".
func _sort_belts_topologically() -> void:
	var sorted: Array[BeltCell] = []
	var visited: Dictionary = {}
	
	for belt in _belts:
		if not visited.has(belt):
			_visit_node(belt, visited, sorted)
	
	_belts = sorted

func _visit_node(node: BeltCell, visited: Dictionary, sorted: Array[BeltCell]) -> void:
	visited[node] = true
	
	if node.next_cell != null and _belts.has(node.next_cell) and not visited.has(node.next_cell):
		_visit_node(node.next_cell, visited, sorted)
		
	# Al no tener más dependencias (o estar ya visitadas), es un extremo de la línea.
	sorted.append(node)
