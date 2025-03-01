extends Node2D

var card:PackedScene = preload("res://cards/Card.tscn")
@onready var playerInfo:Node2D = self.get_node("PlayerInfo")
signal reset_player

var cards = FileAccess.open("cards.json", FileAccess.READ).get_as_text()
var cardArray =  JSON.parse_string(cards).cards # all of the cards



func _on_restart_button_pressed() -> void:
	reset_game()

func instantiate_new_card(suite:String, number: String, dungeonNumber: int) -> void:
	var newCardInstance = card.instantiate()
	var sprite = newCardInstance.get_node("Sprite2D")
	if sprite:
		sprite.texture = load(
			"res://assets/card{suite}{number}.png".format({"suite": suite, "number": number}))

	newCardInstance.position = self.get_node(
		"Dungeon/DungeonCard{dungeonNumber}".format({"dungeonNumber": dungeonNumber})
		).get_global_position()
	
	newCardInstance.suite = suite
	newCardInstance.value = number
	newCardInstance.report_self()
	
	self.add_child(newCardInstance)

func reset_game() -> void:
	cardArray.shuffle()
	reset_player.emit()
	
	# set up the dungeon
	for index in range(0, 4):
		var cardInfo = cardArray[index].split(",")
		instantiate_new_card(cardInfo[0], cardInfo[1], index)
