extends Node2D

@export var main_menu: PanelContainer
@export var rules_panel: PanelContainer

@export var QuitButton: Button
@export var PlayTigerButton: Button
@export var PlayGoatButton: Button
@export var _game: Game

var show_main_menu = true
var show_rules = false
# Called when the node enters the scene tree for the first time.
func _ready():
	QuitButton.button_up.connect(quit_game)
	PlayTigerButton.button_up.connect(human_tiger_game)
	PlayGoatButton.button_up.connect(human_goat_game)
	
	pass # Replace with function body.

func quit_game():
	get_tree().quit()
	
func human_tiger_game():
	_game.flipflop = true
	_game.new_game()
	show_main_menu = false
	_game.show()
	
func human_goat_game():
	_game.flipflop = false
	_game.new_game()
	show_main_menu = false
	_game.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_focus_next"):
		show_rules = !show_rules
	
	if Input.is_action_pressed("ui_cancel"):
		show_main_menu = true
		_game.hide()


	if show_rules:
		rules_panel.show()
	else: 
		rules_panel.hide()
		
	if show_main_menu:
		main_menu.show()
	else:
		main_menu.hide()
