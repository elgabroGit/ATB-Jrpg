extends Node3D

# === Variabili di stato battaglia ===
var PARTY_DOWN: bool = false
var ENEMIES_DOWN: bool = false

# === Code per gestione ATB e azioni ===
var readyQueue: Array
var actionPlayerSelectionQueue: Array
var sequentialQueue: Array
var executeQueue: Array

# === Collegamenti UI ===
@onready var attack_button: Button = $CanvasLayer/Control/Panel/ChoiceBox/AttackButton
@onready var defend_button: Button = $CanvasLayer/Control/Panel/ChoiceBox/DefendButton
@onready var skill_button: Button = $CanvasLayer/Control/Panel/ChoiceBox/SkillButton
@onready var item_button: Button = $CanvasLayer/Control/Panel/ChoiceBox/ItemButton
@onready var flee_button: Button = $CanvasLayer/Control/Panel/ChoiceBox/FleeButton
@onready var choice_box: VBoxContainer = $CanvasLayer/Control/Panel/ChoiceBox
@onready var target_box: ItemList = $CanvasLayer/Control/Panel/TargetBox
@onready var skill_box = $CanvasLayer/Control/Panel/SkillBox
@onready var character_panel: Panel = $CanvasLayer/Control/Panel/CharacterPanel
@onready var character_name: Label = $CanvasLayer/Control/Panel/CharacterPanel/CharacterName
@onready var party_hud: VBoxContainer = $CanvasLayer/Control/Panel/PartyHUD/VBoxContainer
var character_info = preload("res://UI/character_info.tscn")

# === Segnali ===
signal execute_queue_ready
signal execute_queue_locked
signal atb_reset_for(actor)
signal action_type_selected
signal aps_input_ready(action_type)

# === Gruppi personaggi ===
@onready var party: Array
@onready var enemies: Array

var party_alive: Array
var enemies_alive: Array
var selected_target: Unit
var selected_actor: Unit
var selected_values


# === Funzione iniziale ===
func _ready():
	party = get_party()
	enemies = get_enemies()
	choice_box.hide()
	target_box.hide()
	skill_box.hide()
	character_panel.hide()
	connect("execute_queue_ready", Callable(self, "_on_execute_queue_ready"))
	connect("atb_reset_for", Callable(self, "_on_atb_reset_for"))
	target_box.item_clicked.connect(Callable(self, "_on_target_box_item_clicked"))
	skill_box.item_clicked.connect(Callable(self, "_on_skill_box_item_clicked"))
	attack_button.pressed.connect(Callable(self, "_on_attack_button_pressed"))
	defend_button.pressed.connect(Callable(self, "_on_defend_button_pressed"))
	skill_button.pressed.connect(Callable(self, "_on_skill_button_pressed"))
	item_button.pressed.connect(Callable(self, "_on_item_button_pressed"))
	flee_button.pressed.connect(Callable(self, "_on_flee_button_pressed"))
	call_deferred("loop_ready_queue")
	call_deferred("loop_aps_queue")
	call_deferred("loop_sequential_queue")
	call_deferred("loop_execute_queue")

# === Ciclo di gioco ===
func _process(delta: float) -> void:
	check_dead_unit()
	check_win_condition()
	update_party_hud()
	loop_atb(delta)

# === Gestione ATB ===
func loop_atb(delta: float) -> void:
	for unit in party + enemies:
		if unit.atb_lock == false and !unit.is_dead():
			unit.atb += unit.haste * delta
			if unit.atb >= 100.0:
				add_in_ready_queue(unit)
				unit.atb_lock = true

# === Loop code principali ===

# Coda dei personaggi pronti ad agire
func loop_ready_queue() -> void:
	while true:
		await get_tree().create_timer(1.0).timeout
		if !readyQueue.is_empty():
			var actor = readyQueue.pop_front()
			var actor_type = "party" if actor.is_in_group("party") else "enemies"
			match(actor_type):
				"party":
					add_in_aps_queue(actor)
				"enemies":
					add_in_sequential_queue({"actor": actor, "target": enemy_pick_target(), "type": "attack", "values": selected_values})

# Coda per la selezione dell'azione del giocatore
func loop_aps_queue() -> void:
	while true:
		await get_tree().create_timer(1.0).timeout
		if actionPlayerSelectionQueue.size() >= 1:
			var actor: Unit = actionPlayerSelectionQueue[0]
			selected_actor = actor
			choice_box.show()
			character_panel.show()
			character_name.text = actor.unit_name
			var choice = await action_type_selected;
			await aps_input_ready
			actionPlayerSelectionQueue.pop_front()
			add_in_sequential_queue({"actor": actor, "target": selected_target, "type": choice, "values": selected_values})
			choice_box.hide()
			target_box.hide()
			character_panel.hide()

# Mostra i bersagli selezionabili per il giocatore
func show_targets() -> void:
	target_box.clear()
	skill_box.hide()
	
	for enemy: Unit in enemies:
		if !enemy.is_dead():
			target_box.add_item(enemy.unit_name)
	target_box.show()

func show_skills() -> void:
	skill_box.clear()
	target_box.hide()
	
	for move: Skill in selected_actor.moveset:
		var can_use: bool = true
		if move.mp_cost > selected_actor.mp:
			can_use = false
		var new_skill_index = skill_box.add_item(move.skill_name, move.icon, can_use)
		skill_box.set_item_disabled(new_skill_index, !can_use)
	skill_box.show()

# Coda delle azioni da eseguire in ordine
func loop_sequential_queue() -> void:
	while true:
		await get_tree().create_timer(0.1).timeout
		if sequentialQueue.size() >= 1 and executeQueue.size() == 0:
			var action = sequentialQueue.pop_front()
			if action["actor"].is_dead():
				continue
			if !is_instance_valid(action["target"]) or action["target"].is_dead():
				add_in_ready_queue(action["actor"])
			else:
				add_in_execute_queue(action)

# Esecuzione finale dell'azione
func loop_execute_queue() -> void:
	while true:
		await get_tree().create_timer(1.0).timeout

# === Aggiunta alle code ===
func add_in_ready_queue(element):
	readyQueue.append(element)

func add_in_aps_queue(element):
	actionPlayerSelectionQueue.append(element)

func add_in_sequential_queue(element):
	sequentialQueue.append(element)

func add_in_execute_queue(element):
	if executeQueue.size() == 0:
		executeQueue.append(element)
		execute_queue_ready.emit()
	else:
		execute_queue_locked.emit()
		return

# === Gestione esecuzione azione ===
func _on_execute_queue_ready() -> void:
	var action = executeQueue[0]
	var actor: Unit = action["actor"]
	var target: Unit = action["target"]
	var action_type: String = action["type"]
	var values = action["values"]

	if !is_instance_valid(target):
		executeQueue.pop_front()
		add_in_ready_queue(actor)
		return

	match action_type:
		"attack":
			await _handle_attack_action(actor, target)
		"defence":
			_handle_defence_action(actor)
		"skill":
			await _handle_skill_action(actor, target, values)
		_:
			print("Tipo azione sconosciuta: ", action_type)

	executeQueue.pop_front()
	atb_reset_for.emit(actor)

# Gestione dell'azione difesa
func _handle_defence_action(actor: Unit) -> void:
	actor.stop_idle()
	actor.start_defend()

# Gestione dell'azione di skill
func _handle_skill_action(actor: Unit, target: Unit, values) -> void:
	var skill: Skill = values
	var _damage: float = skill.damage + actor.spell_power
	actor.mp = max(actor.mp - skill.mp_cost, 0.0)
	actor.stop_idle()
	actor.play_animation(skill.animation)
	actor.target_hitted.connect(Callable(target, "react_to_magic_hit").bind(_damage, skill.react_animation))
	await actor.animation_player.animation_finished
	actor.target_hitted.disconnect(Callable(target, "react_to_magic_hit"))
	actor.start_battle_idle()

# Gestione dell'azione di attacco
func _handle_attack_action(actor: Unit, target: Unit) -> void:
	actor.stop_idle()
	actor.start_run()
	actor.target_hitted.connect(Callable(target, "react_to_hit").bind(actor.strength))
	await actor.move_to(target.attack_spot.global_position)
	await actor.start_attack()
	actor.start_run()
	await actor.return_to_original_position()
	actor.stop_run()
	actor.start_battle_idle()
	actor.target_hitted.disconnect(Callable(target, "react_to_hit"))

# Reset dell’ATB dopo un’azione
func _on_atb_reset_for(actor: Unit) -> void:
	actor.reset_atb()
	actor.unlock_atb()

# === Utility ===

# Recupera i nemici dalla scena
func get_enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")

# Recupera gli alleati dalla scena
func get_party() -> Array:
	return get_tree().get_nodes_in_group("party")

# Rimuove unità morte dalle code
func check_dead_unit() -> void:
	for unit: Unit in enemies + party:
		if unit.is_dead():
			readyQueue.erase(unit)
			actionPlayerSelectionQueue.erase(unit)

# Verifica condizioni di vittoria/sconfitta
func check_win_condition() -> void:
	PARTY_DOWN = true
	ENEMIES_DOWN = true

	for unit: Unit in party:
		if not unit.is_dead():
			PARTY_DOWN = false
			break

	for unit: Unit in enemies:
		if not unit.is_dead():
			ENEMIES_DOWN = false
			break

	if ENEMIES_DOWN:
		print("Il party ha vinto!")
	elif PARTY_DOWN:
		print("I nemici hanno vinto!")

# Selezione casuale di un bersaglio valido da parte dei nemici
func enemy_pick_target() -> Unit:
	var possible_choises: Array[Unit] = []
	for unit: Unit in party:
		if !unit.is_dead():
			possible_choises.append(unit)
	if possible_choises.is_empty():
		return null
	return possible_choises.pick_random()

# Gestione clic su bersaglio dalla lista
func _on_target_box_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	var alive_enemies: Array[Unit]
	for unit in enemies:
		if !unit.is_dead():
			alive_enemies.append(unit)
	selected_target = alive_enemies[index]
	aps_input_ready.emit()
	
func _on_skill_box_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	selected_values = selected_actor.moveset[index]
	show_targets()
	
func _on_attack_button_pressed() -> void:
	action_type_selected.emit("attack")
	show_targets()
	
func _on_defend_button_pressed() -> void:
	target_box.hide()
	action_type_selected.emit("defence")
	selected_target = selected_actor
	aps_input_ready.emit()

func _on_skill_button_pressed() -> void:
	action_type_selected.emit("skill")
	show_skills()
	
func _on_item_button_pressed() -> void:
	action_type_selected.emit("item")
	show_targets()
	
func _on_flee_button_pressed() -> void:
	action_type_selected.emit("flee")
	show_targets()
	
func update_party_hud() -> void:
	for child in party_hud.get_children():
		child.queue_free()
	
	for unit:Unit in party:
		var unit_info: CharacterInfo = character_info.instantiate()
		
		unit_info.character_name_text = unit.unit_name
		unit_info.hp_label_text = str(unit.hp)
		unit_info.hp_max_label_text = str(unit.max_hp)
		unit_info.progress_bar_value = unit.atb
		
		party_hud.add_child(unit_info)

func update_values(new_values):
	selected_values = new_values
