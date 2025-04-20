@icon("res://Assets/fire-svgrepo-com.svg")
extends Resource
class_name Skill

@export var skill_name: String = "New move"
@export var icon: Texture2D
@export var damage: float = 10.0
@export var mp_cost: float = 10.0

@export var animation: String = "battle_cast_magic"
@export var react_animation: String = "battle_react_magic"
