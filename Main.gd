extends Node2D

# global variables
var card:PackedScene = preload("res://cards/Card.tscn")
var CARDS_JSON : Dictionary = JSON.parse_string(FileAccess.open("cards.json", FileAccess.READ).get_as_text())
var DAMAGE_DECODER : Dictionary = CARDS_JSON.values

# signals
signal reset_player
signal change_player_life(amount: int, type: String)

var board_state : Dictionary = {
	"deck": [],
	"dungeon" : [],
	"weapon" : [],
	"discard": []
}

var game_state : Dictionary = {
	"state": "idle",
	"potion_used": false,
}

func on_death() -> void:
	game_state.state = "game_over"

func _on_restart_button_pressed() -> void:
	reset_game()

func instantiate_new_card(suite:String, number: String) -> Card:
	var new_card_instance = card.instantiate()
	new_card_instance.suite = suite
	new_card_instance.value = number
	
	new_card_instance.got_clicked.connect(handle_card_click)
	return new_card_instance

func handle_weapon(clicked_card) -> void:
	if board_state.weapon.size() == 0:
		board_state.weapon.append(clicked_card)

	else:
		for entry in board_state.weapon:
			move_to_discard(entry)
	board_state.weapon = [clicked_card]
	sort_weapon()

func move_to_discard(clicked_card) -> void:
	board_state.discard.append(clicked_card)
	clicked_card.position = self.get_node("Discard").get_global_position()
	clicked_card.get_node("CardArea2D").input_pickable = false
	sort_discard()
	
func sort_discard() -> void:
	for index in range(1,board_state.discard.size()):
		board_state.discard[index].z_index = index

func handle_potion(clicked_card) -> void:
	if !game_state.potion_used:
		change_player_life.emit(DAMAGE_DECODER[clicked_card.value], "gain")
		game_state.potion_used = true
	move_to_discard(clicked_card)

func handle_enemy(clicked_card) -> void:

	var damage : int = DAMAGE_DECODER[clicked_card.value]
	var weapon_strength : int
	var differential : int
	
	if board_state.weapon.size() == 0:
		change_player_life.emit(damage, "lose")
		move_to_discard(clicked_card)
		return

	if board_state.weapon.size() == 1:
		weapon_strength = DAMAGE_DECODER[board_state.weapon[0].value]
		differential = damage - weapon_strength
		if differential < 0: differential = 0
	
	if board_state.weapon.size() > 1:
		weapon_strength = DAMAGE_DECODER[board_state.weapon[0].value]
		var latest_enemy_strength = DAMAGE_DECODER[board_state.weapon[-1].value]
		if latest_enemy_strength <= damage:
			change_player_life.emit(damage, "lose")
			move_to_discard(clicked_card)
			return
		differential = damage - weapon_strength
		if differential < 0: differential = 0

	change_player_life.emit(differential, "lose")
	board_state.weapon.append(clicked_card)
	sort_weapon()

func sort_weapon() -> void:
	var counter : int = 0
	while counter < board_state.weapon.size():
		var current_card : Card = board_state.weapon[counter]
		current_card.position = self.get_node("PlayerInfo/Weapon").get_global_position()
		current_card.position.x += counter*30
		current_card.z_index = counter + 1
		counter += 1

func handle_card_click(clicked_card) -> void:
	self.get_node("RunButton").disabled = true
	board_state.dungeon.erase(clicked_card)
	if clicked_card.suite == "Diamonds":
		handle_weapon(clicked_card)
	if clicked_card.suite == "Hearts":
		handle_potion(clicked_card)
	if clicked_card.suite == "Clubs" or clicked_card.suite == "Spades":
		handle_enemy(clicked_card)
	if board_state.dungeon.size() == 1:
		populate_dungeon()

func initialize_board_state() -> void:
	var all_cards : Array = CARDS_JSON.cards
	all_cards.shuffle()
	for c in all_cards:
		var card_info : Array = c.split(",")
		var new_card : Card = instantiate_new_card(card_info[0], card_info[1])
		self.add_child(new_card)
		new_card.position = self.get_node("Deck").get_global_position()
		board_state.deck.append(new_card)

func free_all_cards() -> void:
	for c in board_state.dungeon:
		c.free()
	for c in board_state.weapon:
		c.free()
	for c in board_state.discard:
		c.free()
	board_state.deck = []
	board_state.dungeon = []
	board_state.weapon = []
	board_state.discard = []

func flip_card(active_card):
	var sprite : Sprite2D = active_card.get_node("Sprite2D")
	if sprite:
		sprite.texture = load(
			"res://assets/card{suite}{number}.png".format(
				{"suite": active_card.suite, "number": active_card.value}))

func unflip_card(active_card):
	var sprite : Sprite2D = active_card.get_node("Sprite2D")
	if sprite:
		sprite.texture = load("res://assets/cardBack_blue1.png")

func populate_dungeon() -> void:
	while board_state.dungeon.size() < 4:
		var moving_card : Card = board_state.deck.pop_front()
		board_state.dungeon.append(moving_card)
		flip_card(moving_card)
	for index in range(0,board_state.dungeon.size()):
		board_state.dungeon[index].position = self.get_node(
			"Dungeon/DungeonCard{index}".format({"index": index})).get_global_position()
	self.get_node("RunButton").disabled = false
	game_state.potion_used = false

func reset_game() -> void:
	free_all_cards()
	initialize_board_state()
	reset_player.emit()
	populate_dungeon()
	self.get_node("RunButton").disabled = false

func _on_run_button_pressed() -> void:
	self.get_node("RunButton").disabled = true
	for c : Card in board_state.dungeon:
		board_state.deck.append(c)
		board_state.dungeon.erase(c)
		unflip_card(c)
		c.position = self.get_node("Deck").position
		c.get_node("CardArea2D").input_pickable = false
	populate_dungeon()

func _on_player_info_player_dead() -> void:
	on_death()
