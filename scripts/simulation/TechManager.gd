class_name TechManager
extends RefCounted

var techs: Dictionary = {}
var unlocked_techs: Array[String] = []
var active_research: String = ""

# Guardamos el progreso referenciando el ID del ítem (StringName) a su cantidad
var research_progress: Dictionary = {}

func register_tech(id: String, name: String, desc: String, cost: Dictionary) -> void:
	var t = TechData.new()
	t.id = id
	t.tech_name = name
	t.description = desc
	t.cost = cost
	techs[id] = t

func start_research(id: String) -> void:
	if unlocked_techs.has(id): return
	active_research = id
	research_progress.clear()

func is_unlocked(id: String) -> bool:
	return unlocked_techs.has(id)

func needs_item(item: ItemData) -> bool:
	if active_research == "": return false
	var tech = techs[active_research]
	if not tech.cost.has(item): return false
	var current = research_progress.get(item.id, 0)
	return current < tech.cost[item]

func add_progress(item: ItemData, amount: int) -> void:
	var current = research_progress.get(item.id, 0)
	research_progress[item.id] = current + amount
	_check_completion()

func _check_completion() -> void:
	if active_research == "": return
	var tech = techs[active_research]
	var complete = true
	
	for req_item in tech.cost.keys():
		if research_progress.get(req_item.id, 0) < tech.cost[req_item]:
			complete = false
			break
			
	if complete:
		unlocked_techs.append(active_research)
		active_research = ""
		research_progress.clear()
