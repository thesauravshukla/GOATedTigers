extends Sprite2D

class_name TestbedCtrl

var bot = mcts.new()
var board_state = self._make_fresh_board()



func _make_fresh_board() -> mcts.mcts_node:

	var board = mcts.mcts_node.new()
	board.game_state_array = ["t", "b", "b", "t", "t", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b", "b"] as Array[String]
	board.player_role = 'g'
	board.UCB1 = INF
	board.children = [] as Array[mcts.mcts_node]
	board.parent = null
	board.move_count = 0
	board.dead_goat_count = 0
	board.n = 0
	board.t = 0
	
	return board	

func _ready():
	
	pass
	
func _process(_delta):
	board_state = bot.MCTS_SIM(board_state,500)
	show_game_state(board_state.game_state_array)
	

	

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
