extends Node3D
class_name Unit
## Unità base

## --- COSTANTI E VARIABILI ---
var MOVEMENT_SPEED: float = 1.0
var CHARACTER_STATE: String = "OK"
var DEFENDING: bool = false:
	get:
		return _defending
	set(value):
		if value and !_defending:
			haste *= 0.5
			defense *= 2.0
		elif not value and !_defending:
			haste = max_haste
			defense = max_defense
		_defending = value
var _defending: bool = false

@export var unit_name: String = "Base"
@export var max_haste: float = 10.0
@export var max_strength: float = 10.0
@export var max_defense: float = 10.0
@export var max_hp: float = 100.0
@export var max_mp: float = 50.0

var haste: float
var strength: float
var defense: float
var mp: float
var hp: float:
	get:
		return _hp
	set(value):
		_hp = max(value, 0.0)
		if _hp == 0.0:
			CHARACTER_STATE = "KO"
			unit_died.emit()
var _hp: float

@export var moveset: Array[Skill]

## --- ATB ---
@export var atb: float:
	get:
		return _atb
	set(value):
		_atb = clamp(value, 0.0, 100.0)
		if _atb == 100.0:
			DEFENDING = false

var _atb: float = 0.0
var atb_lock: bool = false

var original_position: Vector3
var original_rotation: Vector3

## --- SEGNALI ---
signal target_hitted
signal unit_died

## --- NODI E VARIABILI ANIMAZIONE ---
@onready var model: Node3D = $Model
@onready var attack_spot: Node3D = $AttackSpot
var animation_player: AnimationPlayer
var current: String

## --- FUNZIONI GODOT ---
func _ready() -> void:
	connect("target_hitted", Callable(self, "_on_target_hitted"))
	connect("unit_died", Callable(self, "_on_unit_died"))
	animation_player = %AnimationPlayer
	current = animation_player.current_animation
	original_position = global_position
	original_rotation = global_rotation
	setup_statistics()
	setup_unit()

func _process(_delta: float) -> void:
	current = animation_player.current_animation

func setup_statistics() -> void:
	haste = max_haste
	strength = max_strength
	defense = max_defense
	hp = max_hp
	mp = max_mp

## --- METODI ASTRATTI ---
func setup_unit() -> void:
	# Metodo da sovrascrivere nelle sottoclassi
	pass

## --- ANIMAZIONI ---
func play_animation(anim_name: String) -> void:
	if current != anim_name:
		animation_player.play(anim_name)

func stop_animation_if(name_list: Array[String]) -> void:
	if name_list.has(current):
		animation_player.stop()

func stop_idle() -> void:
	stop_animation_if(["battle_idle", "idle"])

func start_run() -> void:
	play_animation("run")

func stop_run() -> void:
	stop_animation_if(["run"])

func start_battle_idle() -> void:
	if DEFENDING:
		play_animation("battle_defence")
	else:
		play_animation("battle_idle")

func start_idle() -> void:
	play_animation("idle")

func start_die() -> void:
	play_animation("battle_die")

func start_magic() -> void:
	play_animation("battle_cast_magic")

func start_attack() -> void:
	play_animation("battle_hit")
	await animation_player.animation_finished

func start_defend() -> void:
	DEFENDING = true
	play_animation("battle_defence")

func react_to_hit(damage: float) -> void:
	play_animation("battle_react_hit")
	await animation_player.animation_finished
	start_battle_idle()
	hp -= max(damage - defense, 1.0)

func react_to_magic_hit(damage: float, animation: String) -> void:
	play_animation(animation)
	await animation_player.animation_finished
	start_battle_idle()
	hp -= max(damage - defense, 1.0)

## --- MOVIMENTO ---
func move_to(target: Vector3) -> void:
	var tween: Tween = get_tree().create_tween()
	original_position = self.global_position
	look_at(target, Vector3.UP)
	rotate_y(PI)
	tween.tween_property(self, "global_position", target, MOVEMENT_SPEED)	
	await tween.finished

func return_to_original_position() -> void:
	var tween: Tween = get_tree().create_tween()
	look_at(original_position, Vector3.UP)
	rotate_y(PI)
	tween.tween_property(self, "global_position", original_position, MOVEMENT_SPEED)
	await tween.finished
	global_rotation = original_rotation

## --- ATB UTILS ---
func reset_atb():
	atb = 0.0

func lock_atb():
	atb_lock = true
	
func unlock_atb():
	atb_lock = false
	
func toggle_atb():
	atb_lock = !atb_lock

## --- SEGNALI ---
func trigger_target_hitted() -> void:
	target_hitted.emit()

func _on_target_hitted() -> void:
	pass

func _on_unit_died() -> void:
	start_die()
	
## --- UTILITÀ
func is_dead() -> bool:
	return CHARACTER_STATE == "KO"
