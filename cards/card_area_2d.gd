extends Area2D



func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Perform actions here
		self.get_parent().on_click_handler()
