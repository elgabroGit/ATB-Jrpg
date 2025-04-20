extends Control
class_name CharacterInfo

@onready var character_name: Label = $CharacterName
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var hp_label: Label = $HpLabel
@onready var hp_max_label: Label = $HpMaxLabel
var character_name_text: String
var hp_label_text: String
var hp_max_label_text: String
var progress_bar_value: float

func _ready() -> void:
	character_name.text = character_name_text
	hp_label.text = hp_label_text
	hp_max_label.text = hp_max_label_text
	progress_bar.value = progress_bar_value
	print(progress_bar_value)
