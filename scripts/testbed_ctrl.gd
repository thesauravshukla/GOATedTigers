extends Sprite2D

class_name TestbedCtrl

var bot = mcts.new()
var board = self._make_fresh_board()

var goat = mcts.new()
var tiger = mcts.new()
var flipflop = true

var pick_from = -1
var drop_at = -1
signal human_chose_move
signal next_turn


func _make_fresh_board() -> mcts_node:

	var board = mcts_node.new()
	board.game_state_array = ["t", "b", "b", "t", "t", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b"] as Array[String]
	board.player_role = 'g'
	board.UCB1 = INF
	board.children = [] as Array[mcts_node]
	board.parent = null
	board.move_count = 0
	board.dead_goat_count = 0
	board.n = 0
	board.t = 0
	
	return board	

func _ready():
	for i in range(23):
		var b = self.get_node("pos_%d/Button" % i) as PosButton
		b.button_pressed_at.connect(position_input)
	pass
	
func _process(_delta):
	'''
	#BOT vs BOT
	#goat and tiger share tree and the rewards backprop is messed up
	match flipflop:
		true: board = goat.MCTS_SIM(board, 1000)
		false: board = tiger.MCTS_SIM(board, 100)
	flipflop  = !flipflop
	'''
	
	show_game_state(board.game_state_array)

	match flipflop:
		true:
			board = tiger.MCTS_SIM(board, 1000)
			flipflop = !flipflop
			print("goat moved")
		false:
			if (drop_at != -1 and pick_from != -1):
				if (board_utils.is_valid_move(board, pick_from, drop_at)):
					board = board_utils.make_next_board(board, pick_from, drop_at)
					flipflop = !flipflop
					print("tiger moved")



			
func position_input(pos_idx):
	if pick_from ==  -1:
		pick_from = pos_idx
	elif drop_at ==  -1: 
		drop_at = pos_idx
	else:
		pick_from = pos_idx
		drop_at =  -1		
		
	print("[%d, %d]" % [pick_from, drop_at])	

	
	
		

func show_game_state(game_state: Array[String]):
	
	for index in range(23):

		var tiger = self.get_node("pos_%d/TigerFace" % index) as Node2D
		var goat = self.get_node("pos_%d/GoatSprite" % index) as Node2D		
		
		match game_state[index]:
			't':
				tiger.show()
				goat.hide()
			'g':
				goat.show()
				tiger.hide()
			'b':
				tiger.hide()
				goat.hide()


func explode_string(s: String) -> Array[String]:
	var a: Array[String] = []
	for i in range(23):
		a.append(s[i])

	return a
