class_name Card extends Node2D

@export var suite: String
@export var value: String

func report_self():
	print(self.suite)
	print(self.value)
	
func _ready() -> void:
	# make it so that the dungeon placeholders are not clickable
	if "Dungeon" in self.name:
		self.get_node("CardArea2D").input_pickable = false
