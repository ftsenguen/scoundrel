class_name PlayerInfo extends Node2D

@export var life_total: int = 20

func updateHealthTotal(new_life_total): 
	self.life_total = new_life_total
	self.get_node("LifeTotalLabel").text = "Health: {lifeTotal}".format({"lifeTotal": life_total})

func _on_main_player_takes_damage(damage_amount: int) -> void:
	self.life_total = life_total - damage_amount

func _on_main_reset_player() -> void:
	self.updateHealthTotal(20)

func _on_main_change_player_life(amount: int, type: String) -> void:
	if type == "gain":
		life_total = life_total + amount
		if life_total > 20: life_total = 20
		updateHealthTotal(life_total)

	if type == "lose":
		life_total = life_total - amount
		if life_total < 0: life_total = 0
		updateHealthTotal(life_total)
