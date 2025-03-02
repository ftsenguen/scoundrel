class_name Card extends Node2D

@export var suite: String
@export var value: String
@export var location: String
signal got_clicked(clicked_card : Node2D)

func report_self() -> Dictionary:
	return{
		"value": self.value,
		"suite": self.suite,
		"location": self.location
	}

func _ready() -> void:
	# make it so that the dungeon placeholders are not clickable
	if "Dungeon" in self.name:
		self.get_node("CardArea2D").input_pickable = false

func on_click_handler() -> void:
	got_clicked.emit(self)
