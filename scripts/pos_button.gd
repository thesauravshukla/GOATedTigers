extends Button
class_name PosButton

signal button_pressed_at(pos)

var _pos_idx: int

func _ready():
	self.pressed.connect(_on_button_pressed)
	_pos_idx = int(self.get_parent().name.c_escape().substr(4))

func _on_button_pressed():
	button_pressed_at.emit(_pos_idx)
