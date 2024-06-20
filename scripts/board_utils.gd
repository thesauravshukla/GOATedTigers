extends Node2D

# Called when the node enters the scene tree for the first time.
class_name board_utils

const max_moves: int = 500
const tiger_jumps: Array[Array] = \
[
	[[2,8],[3,9],[4,10],[5,11]],    #0
	[[2,3],[7,13]],                #1 
	[[3,4],[8,14]],            #2
	[[2,1],[9,15],[4,5]],        #3
	[[3,2],[5,6],[10,16]],        #4
	[[4,3],[11,17]],        #5
	[[5,4],[12,18]],            #6
	[[8,9]],                #7
	[[14,19],[9,10],[2,0]],     #8
	[[8,7],[15,20],[10,11],[3,0]],    #9
	[[9,8],[16,21],[11,12],[4,0]],    #10
	[[5,0],[17,22],[10,9]],    #11
	[[11,10]],            #12
	[[7,1],[14,15]],            #13
	[[8,2],[15,16]],        #14
	[[14,13],[16,17],[9,3]],    #15
	[[15,14],[17,18],[10,4]],    #16
	[[16,15],[11,5]],        #17
	[[17,16],[12,6]],            #18
	[[14,8],[20,21]],            #19
	[[15,9],[21,22]],        #20
	[[20,19],[16,10]],        #21
	[[21,20],[17,11]]            #22
]

const board_connectivity: Array[Array] = \
[
	[2,3,4,5],        
	[2,7],            
	[0,1,3,8],       
	[0,2,4,9],       
	[0,3,5,10],        
	[0,4,6,11],        
	[5,12],            
	[1,8,13],        
	[2,7,9,14],     
	[3,8,10,15],    
	[4,9,11,16],    
	[5,10,12,17],    
	[6,11,18],        
	[7,14],            
	[8,13,15,19],    
	[9,14,16,20],    
	[10,15,17,21],    
	[11,16,18,22],    
	[12,17],        
	[14,20],        
	[15,19,21],        
	[16,20,22],        
	[17,21]            
]


#if game terminated then return board_state
static func is_game_terminated(board_state: mcts_node) -> bool:
	if(board_state.dead_goat_count >= 5 || board_state.move_count > max_moves || all_tigers_trapped(board_state)):
		return true
		
	return false
		
static func all_tigers_trapped(board_state: mcts_node) -> bool:
	for i in range(23):
		if(board_state.game_state_array[i] == 't'):
			if(not this_tiger_trapped(board_state,i)):
				return false;
	return true	

static func this_tiger_trapped(board_state: mcts_node, index: int) -> bool:
	for j in board_connectivity[index]:
		if(board_state.game_state_array[j] == 'b'):
			return false
	for jump in tiger_jumps[index]:
		if(board_state.game_state_array[jump[1]] == 'b'):
			return false
	return true

static func is_valid_move(board_state: mcts_node, initial_position: int, final_position: int):
	var player_role = board_state.player_role
	if(player_role == 'g'):
		var goats_on_board = board_state.game_state_array.count('g')
		var total_goats_placed = goats_on_board + board_state.dead_goat_count
		if(total_goats_placed < 15):
			if(initial_position == final_position && board_state.game_state_array[initial_position] == 'b'):
					return true
		else:
			if(board_state.game_state_array[initial_position] == 'g' && board_state.game_state_array[final_position] == 'b' && board_connectivity[initial_position].find(final_position) != -1):
				return true
	if(player_role == 't'):
		if(board_state.game_state_array[initial_position] == 't' && board_connectivity[initial_position].find(final_position) != -1 && board_state.game_state_array[final_position] == 'b'):
			return true
		else:
			if(board_state.game_state_array[initial_position] == 't'):
				for jumps in tiger_jumps[initial_position]:
					if(jumps[1] == final_position && board_state.game_state_array[jumps[0]] == 'g' && board_state.game_state_array[jumps[1]] == 'b'):
						return true
	else:
		return false
	
static func deepcopy(board_state: mcts_node):
	var copied_board_state = mcts_node.new()
	copied_board_state.children = board_state.children.duplicate()
	copied_board_state.dead_goat_count = board_state.dead_goat_count
	copied_board_state.game_state_array = board_state.game_state_array.duplicate()
	copied_board_state.move_count = board_state.move_count
	copied_board_state.n = board_state.n
	copied_board_state.parent = board_state.parent
	copied_board_state.player_role = board_state.player_role
	copied_board_state.t = board_state.t
	copied_board_state.UCB1 = board_state.UCB1
	return copied_board_state
	
static func make_next_board(board_state: mcts_node, initial_position: int, final_position: int):
	assert(is_valid_move(board_state,initial_position,final_position))
	var player_role = board_state.player_role
	var copied_board = deepcopy(board_state)
	copied_board.children = [] as Array[mcts_node]
	copied_board.parent = board_state
	copied_board.n = 0
	copied_board.t = 0
	copied_board.UCB1 = 0
	if(player_role == 'g'):
		var goats_on_board = copied_board.game_state_array.count('g')
		var total_goats_placed = goats_on_board + copied_board.dead_goat_count
		if(total_goats_placed < 15):
			if(initial_position == final_position && 
			 copied_board.game_state_array[initial_position] == 'b'):
				copied_board.game_state_array[final_position] = 'g'
				copied_board.move_count += 1
				copied_board.player_role = 't'
		else:
			if(copied_board.game_state_array[initial_position] == 'g' && 
			copied_board.game_state_array[final_position] == 'b' && 
			board_connectivity[initial_position].find(final_position) != -1):
				copied_board.game_state_array[final_position] =  'g'
				copied_board.game_state_array[initial_position] =  'b'
				copied_board.move_count += 1
				copied_board.player_role = 't'	
	else:
		if(board_state.game_state_array[initial_position] == 't' &&
		 board_connectivity[initial_position].find(final_position) != -1 &&
		 board_state.game_state_array[final_position] == 'b'):		
				copied_board.game_state_array[final_position] =  't'
				copied_board.game_state_array[initial_position] =  'b'
				copied_board.move_count += 1
				copied_board.player_role = 'g'
		else:
			if(board_state.game_state_array[initial_position] == 't'):
				for jumps in tiger_jumps[initial_position]:
					if(jumps[1] == final_position &&
					 board_state.game_state_array[jumps[0]] == 'g' &&
					 board_state.game_state_array[jumps[1]] == 'b'):
						copied_board.game_state_array[final_position] =  't'
						copied_board.game_state_array[initial_position] =  'b'
						copied_board.game_state_array[jumps[0]] = 'b'
						copied_board.dead_goat_count += 1
						copied_board.move_count += 1
						copied_board.player_role = 'g'
	return copied_board
	
static func get_next_board(board_state: mcts_node, initial_position: int, final_position: int):
	assert(is_valid_move(board_state,initial_position,final_position))
	var player_role = board_state.player_role
	var final_game_state_array = board_state.game_state_array
	if(player_role == 'g'):
		var goats_on_board = board_state.game_state_array.count('g')
		var total_goats_placed = goats_on_board + board_state.dead_goat_count
		if(total_goats_placed < 15):
			if(initial_position == final_position && 
			 board_state.game_state_array[initial_position] == 'b'):
				final_game_state_array[final_position] = 'g'
		else:
			if(board_state.game_state_array[initial_position] == 'g' && 
			board_state.game_state_array[final_position] == 'b' && 
			board_connectivity[initial_position].find(final_position) != -1):
				final_game_state_array[final_position] =  'g'
				final_game_state_array[initial_position] =  'b'
	else:
		if(board_state.game_state_array[initial_position] == 't' &&
		 board_connectivity[initial_position].find(final_position) != -1 &&
		 board_state.game_state_array[final_position] == 'b'):		
				final_game_state_array[final_position] =  't'
				final_game_state_array[initial_position] =  'b'
		else:
			if(board_state.game_state_array[initial_position] == 't'):
				for jumps in tiger_jumps[initial_position]:
					if(jumps[1] == final_position &&
					 board_state.game_state_array[jumps[0]] == 'g' &&
					 board_state.game_state_array[jumps[1]] == 'b'):
						final_game_state_array[final_position] =  't'
						final_game_state_array[initial_position] =  'b'
						final_game_state_array[jumps[0]] = 'b'
	for i in range(board_state.children.size()):
		var flag = 0
		for j in range(board_state.children[i].game_state_array.size()):
			if(board_state.children[i].game_state_array[j] != final_game_state_array[j]):
				flag = 1
				break;
		if(flag == 0):
			return board_state.children[i]
	return make_next_board(board_state,initial_position,final_position)
	
	
