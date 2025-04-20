extends Control
class_name WidgetTest

@onready var character_name: Label = $CharacterName
var character_name_text: String

func _ready() -> void:
	character_name.text = character_name_text
