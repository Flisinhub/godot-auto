class_name ItemData
extends Resource

## Identificador único para lógicas de recetas e inventarios (ej: &"iron_ore")
@export var id: StringName = &"unknown_item"

## Nombre amigable para mostrar en la interfaz de usuario
@export var item_name: String = "Unknown Item"

## Textura o icono para el renderizado visual
@export var texture: Texture2D
