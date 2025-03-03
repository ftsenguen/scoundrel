extends Node2D

# global variables
var card:PackedScene = preload("res://cards/Card.tscn")
@onready var splash:VBoxContainer = self.get_node("Splash")
var CARDS_JSON : Dictionary = JSON.parse_string(FileAccess.open("cards.json", FileAccess.READ).get_as_text())
var DAMAGE_DECODER : Dictionary = CARDS_JSON.values

# signals
signal reset_player
signal change_player_life(amount: int, type: String)

var game_state : Dictionary = {
	"deck": [],
	"dungeon" : [],
	"weapon" : [],
	"discard": [],
	"state": "idle",
	"potion_used": false,
	"live_cards": []
}

func reset_game_state() -> void: 
	self.game_state.deck = []
	self.game_state.dungeon = []
	self.game_state.weapon = []
	self.game_state.discard = []
	self.game_state.state = "idle"
	self.game_state.potion_used = false

func reset_game() -> void:
	reset_player.emit()
	self.get_node("RunButton").disabled = false
	reset_game_state()
	initialize_board_state()
	populate_dungeon()
	draw_board()

func free_all_cards() -> void:
	while game_state.live_cards.size() > 0:
		var c : Card = game_state.live_cards.pop_back()
		c.queue_free()


func initialize_board_state() -> void:
	splash.visible = false
	var all_cards : Array = CARDS_JSON.cards
	all_cards.shuffle()
	for c in all_cards:
		var card_info : Array = c.split(",")
		game_state.deck.append({"card_name": c, "suite": card_info[0], "value": card_info[1]})

func populate_dungeon() -> void:
	while game_state.dungeon.size() < 4:
		var moving_card : Dictionary = game_state.deck.pop_front()
		game_state.dungeon.append(moving_card)
	game_state.potion_used = false

func _on_restart_button_pressed() -> void:
	reset_game()

func instantiate_new_card(suite:String, number: String, card_name: String) -> Card:
	var new_card_instance = card.instantiate()
	new_card_instance.suite = suite
	new_card_instance.value = number
	new_card_instance.card_name = card_name
	
	new_card_instance.got_clicked.connect(handle_card_click)
	game_state.live_cards.append(new_card_instance)
	return new_card_instance

func handle_weapon(clicked_card) -> void:
	if game_state.weapon.size() > 0:
		for entry in game_state.weapon:
			game_state.discard.append(entry)
	game_state.weapon = [clicked_card.to_object()]
	game_state.dungeon.erase(clicked_card.to_object())

func handle_potion(clicked_card : Card) -> void:
	if !game_state.potion_used:
		change_player_life.emit(DAMAGE_DECODER[clicked_card.value], "gain")
		game_state.potion_used = true
	game_state.discard.append(clicked_card.to_object())
	game_state.dungeon.erase(clicked_card.to_object())

func handle_enemy(clicked_card) -> void:

	var damage : int = DAMAGE_DECODER[clicked_card.value]
	var weapon_strength : int
	var differential : int
	
	if game_state.weapon.size() == 0:
		change_player_life.emit(damage, "lose")
		game_state.discard.append(clicked_card.to_object())
		game_state.dungeon.erase(clicked_card.to_object())
		return

	if game_state.weapon.size() == 1:
		weapon_strength = DAMAGE_DECODER[game_state.weapon[0].value]
		differential = damage - weapon_strength
		if differential < 0: differential = 0
		
	if game_state.weapon.size() > 1:
		weapon_strength = DAMAGE_DECODER[game_state.weapon[0].value]
		var latest_enemy_strength = DAMAGE_DECODER[game_state.weapon[-1].value]
		if latest_enemy_strength <= damage:
			change_player_life.emit(damage, "lose")
			game_state.discard.append(clicked_card.to_object())
			game_state.dungeon.erase(clicked_card.to_object())
			return
		differential = damage - weapon_strength
		if differential < 0: differential = 0
	change_player_life.emit(differential, "lose")
	game_state.dungeon.erase(clicked_card.to_object())
	game_state.weapon.append(clicked_card.to_object())

func handle_card_click(clicked_card) -> void:
	self.get_node("RunButton").disabled = true
	game_state.dungeon.erase(clicked_card)
	if clicked_card.suite == "Diamonds":
		handle_weapon(clicked_card)
	if clicked_card.suite == "Hearts":
		handle_potion(clicked_card)
	if clicked_card.suite == "Clubs" or clicked_card.suite == "Spades":
		handle_enemy(clicked_card)
	if game_state.dungeon.size() == 1:
		populate_dungeon()
		self.get_node("RunButton").disabled = false
	draw_board()

func draw_board() -> void:
	free_all_cards()
	
	# draw the dungeon cards
	for index in range(0, game_state.dungeon.size()):
		var new_card : Card = instantiate_new_card(
			game_state.dungeon[index].suite, game_state.dungeon[index].value,
			game_state.dungeon[index].card_name)
		self.add_child(new_card)
		new_card.position = self.get_node(
			"Dungeon/DungeonCard{index}".format({"index": index})).get_global_position()
		flip_card(new_card)

	# draw weapon cards
	var counter : int = 0
	while counter < game_state.weapon.size():
		var new_card : Card = instantiate_new_card(game_state.weapon[counter].suite, 
			game_state.weapon[counter].value, game_state.weapon[counter].card_name)
		new_card.position = self.get_node("PlayerInfo/Weapon").get_global_position()
		new_card.position.x += counter*30
		new_card.z_index = counter + 1
		new_card.get_node("CardArea2D").input_pickable = false
		self.add_child(new_card)
		flip_card(new_card)
		counter += 1
	
	# draw discard
	if game_state.discard.size() > 0:
		var last_card_index = game_state.discard.size()-1
		var top_discard = instantiate_new_card(game_state.discard[last_card_index].suite,
			game_state.discard[last_card_index].value,
			game_state.discard[last_card_index].card_name
		)
		top_discard.position = self.get_node("Discard").position
		self.add_child(top_discard)
		flip_card(top_discard)
		self.get_node("Discard/Label").text = "Discard: {number}".format({"number": game_state.discard.size()})

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

func _on_run_button_pressed() -> void:
	self.get_node("RunButton").disabled = true
	for c : Dictionary in game_state.dungeon:
		game_state.deck.append(c)
	game_state.dungeon = []
	populate_dungeon()
	draw_board()

func _on_player_info_player_dead() -> void:
	end_game("death")

func end_game(outcome : String):
	if outcome == "death":
		print("Got here")
		splash.get_node("Label").text = "You're Dead"
		splash.visible = true

	if outcome == "victory":
		splash.get_node("Label").text = "You've Won"
		splash.visible = true

func _on_button_pressed() -> void:
	initialize_board_state()
	
