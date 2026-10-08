class_name RecipeData
extends Resource

## Tiempo requerido para transformar los insumos en productos (en pasos de simulación/ticks)
@export var processing_ticks: int = 15

## Diccionario de insumos requeridos.
## Key: ItemData (El material)
## Value: int (Cantidad requerida)
@export var inputs: Dictionary[ItemData, int] = {}

## Diccionario de productos generados.
## Key: ItemData (El producto final)
## Value: int (Cantidad generada por ciclo)
@export var outputs: Dictionary[ItemData, int] = {}
