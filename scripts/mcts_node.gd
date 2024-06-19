extends Node2D

class_name mcts_node
#MCTS node declaration
var game_state_array: Array[String]  = [] #indices:0-22(game state) 
var t: float 
var n: int
var dead_goat_count: int
var move_count: int
var parent: mcts_node
var children: Array [mcts_node] 
var UCB1: float:
			get:
				if(n == 0 || !parent || parent.n):
					return 0
				else:
					return t/n + 2*sqrt(log(parent.n if parent else 0) / n)
var player_role: String
