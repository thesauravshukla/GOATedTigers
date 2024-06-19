
# Called when the node enters the scene tree for the first time.
class_name mcts

extends Node

#constants
const max_moves: int = 100
const EPSILON = 0.001
#rewards
const win: float = 1	
const loss: float = -1	
const draw: float = 0	

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

func MCTS_SIM(board_state: mcts_node,iteration_count: int) -> mcts_node:
	var player_type = board_state.player_role
	
	for iteration in iteration_count :
		
		
		var leaf = _tree_traversal(board_state)
		if(not leaf.children.is_empty() or leaf.n > 1):
			push_error("tree traversal ended at non-leaf/invalid node")
		if(leaf.n == 1 and not is_game_terminated(leaf)):
			node_expansion(leaf)
			leaf = leaf.children.pick_random() 

		#backpropagation for storing reward values obtained from rollout
		backpropagation(board_state,leaf,rollout(leaf,player_type))
		
	#looking for the next action that maximizes t_i 
	var f_max_t = func(acc: float, ele: mcts_node) -> float: return max(acc,ele.t) 
	var max_t = board_state.children.reduce(f_max_t, -INF)
	var next_board_state = board_state.children.filter(func(x: mcts_node): return x.t > max_t - EPSILON).pick_random()
	
	if(next_board_state == null):
		#game must be in a valid terminal state, inspect
		breakpoint		
	
	return next_board_state
	
func _tree_traversal(root: mcts_node):
	var runner = root		
	while(not runner.children.is_empty()):
		var f_max_ucb1 = func(acc: float, e: mcts_node) -> float: return max(acc,e.UCB1) 
		var max_ucb1 = runner.children.reduce(f_max_ucb1, -INF)
		runner = runner.children.filter(func(x: mcts_node): return x.UCB1 > max_ucb1 - EPSILON).pick_random()
	
	var leaf = runner
	assert(leaf.children.is_empty())
	return runner
	
func backpropagation(root_node: mcts_node, leaf_node: mcts_node, reward_value: float) -> void:
	var curr_node = leaf_node
	while(1):
		curr_node.t += reward_value
		curr_node.n += 1
		if(curr_node == root_node):
			break
		curr_node = curr_node.parent
	
			
#Node Expansion Function	
func node_expansion(board_state: mcts_node) -> void:
	if(board_state.player_role == 'g'):
		var goats_on_board = 0
		for i in range(23):
			if(board_state.game_state_array[i] == 'g'):
				goats_on_board += 1
		var total_goats_placed = goats_on_board + board_state.dead_goat_count
		
		if(total_goats_placed < 15):
			for i in range(23):
				if(board_state.game_state_array[i] == 'b'):
					var child_board_state = mcts_node.new()
					child_board_state.dead_goat_count = board_state.dead_goat_count
					child_board_state.parent = board_state
					child_board_state.move_count = board_state.move_count + 1
					child_board_state.game_state_array = board_state.game_state_array.duplicate()
					child_board_state.game_state_array[i] = 'g'
					child_board_state.n = 0
					child_board_state.t = 0
					child_board_state.children = [] as Array[mcts_node]
					child_board_state.UCB1 = INF
					child_board_state.player_role = 't'
					board_state.children.push_back(child_board_state)
					
		#case for when all goats have been placed	
		else:
			var valid_goat_moves: Array[Array] =[]
			for i in range(23):
				if(board_state.game_state_array[i] == 'g'):
					for j in board_connectivity[i]:
						if(board_state.game_state_array[j] == 'b'):
							valid_goat_moves.push_back([i,j])	#goat can move position i to j
			for i in range(valid_goat_moves.size()):
				var child_board_state = mcts_node.new()
				child_board_state.dead_goat_count = board_state.dead_goat_count
				child_board_state.parent = board_state
				child_board_state.move_count = board_state.move_count + 1
				child_board_state.game_state_array = board_state.game_state_array.duplicate()
				child_board_state.game_state_array[valid_goat_moves[i][0]] = 'b'
				child_board_state.game_state_array[valid_goat_moves[i][1]] = 'g'
				child_board_state.n = 0
				child_board_state.t = 0
				child_board_state.children = [] as Array[mcts_node]
				child_board_state.UCB1 = INF
				child_board_state.player_role = 't'
				board_state.children.push_back(child_board_state)
				
	else:
		var valid_tiger_moves: Array[Array] = []
		for i in range(23):
			if(board_state.game_state_array[i] == 't'):
				for jump in tiger_jumps[i]:
					if(board_state.game_state_array[jump[0]] == 'g' && board_state.game_state_array[jump[1]] == 'b'):
						valid_tiger_moves.push_back([i,jump[1],1,jump[0]])
				for neighbour in board_connectivity[i]:
					if(board_state.game_state_array[neighbour] == 'b'):
						valid_tiger_moves.push_back([i,neighbour,0])
		for i in range(valid_tiger_moves.size()):
			var child_board_state = mcts_node.new()
			child_board_state.parent = board_state
			child_board_state.move_count = board_state.move_count + 1
			child_board_state.game_state_array = board_state.game_state_array.duplicate()
			child_board_state.game_state_array[valid_tiger_moves[i][0]] = 'b'
			child_board_state.game_state_array[valid_tiger_moves[i][1]] = 't'			
			child_board_state.n = 0
			child_board_state.t = 0
			child_board_state.children = [] as Array[mcts_node]
			child_board_state.UCB1 = INF
			child_board_state.dead_goat_count = board_state.dead_goat_count + valid_tiger_moves[i][2]
			if(valid_tiger_moves[i][2] == 1):
				child_board_state.game_state_array[valid_tiger_moves[i][3]] = 'b'
			child_board_state.player_role = 'g'
			board_state.children.push_back(child_board_state)
				
			

#Rollout function
func rollout(board_state: mcts_node, player_type: String) -> float:
	if(is_game_terminated(board_state)):
		return reward(board_state, player_type)
		
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
	
	if(copied_board_state.player_role == 'g'):
		var goats_on_board = 0
		for i in range(23):
			if(copied_board_state.game_state_array[i] == 'g'):
				goats_on_board += 1
		var total_goats_placed = goats_on_board + copied_board_state.dead_goat_count
		
		if(total_goats_placed < 15):
			var blank_indices: Array = []
			for i in range(23):
				if(copied_board_state.game_state_array[i] == 'b'):
					blank_indices.push_back(i)
			var random_index = randi() % (blank_indices.size())
			copied_board_state.game_state_array[blank_indices[random_index]] = 'g'
			copied_board_state.move_count += 1
			copied_board_state.player_role = 't'
			return rollout(copied_board_state, player_type)
				
		#case for when all goats have been placed	
		else:
			var valid_goat_moves: Array[Array] = []
			for i in range(23):
				if(copied_board_state.game_state_array[i] == 'g'):
					for j in board_connectivity[i]:
						if(copied_board_state.game_state_array[j] == 'b'):
							valid_goat_moves.push_back([i,j])	#goat can move position i to j
			var random_move_index = randi() % (valid_goat_moves.size())
			copied_board_state.game_state_array[valid_goat_moves[random_move_index][0]] =  'b'
			copied_board_state.game_state_array[valid_goat_moves[random_move_index][1]] =  'g'
			copied_board_state.move_count += 1
			copied_board_state.player_role = 't'
			return rollout(copied_board_state, player_type)
				
	else:
		var valid_tiger_moves: Array[Array] = []
		for i in range(23):
			if(copied_board_state.game_state_array[i] == 't'):
				for jump in tiger_jumps[i]:
					if(copied_board_state.game_state_array[jump[0]] == 'g' && copied_board_state.game_state_array[jump[1]] == 'b'):
						valid_tiger_moves.push_back([i,jump[1],1,jump[0]])
				for neighbour in board_connectivity[i]:
					if(copied_board_state.game_state_array[neighbour] == 'b'):
						valid_tiger_moves.push_back([i,neighbour,0])
		var random_move_index = randi() % (valid_tiger_moves.size())
		copied_board_state.game_state_array[valid_tiger_moves[random_move_index][0]] = 'b'
		copied_board_state.game_state_array[valid_tiger_moves[random_move_index][1]] = 't'
		if(valid_tiger_moves[random_move_index][2] == 1):
			copied_board_state.game_state_array[valid_tiger_moves[random_move_index][3]] = 'b'
			copied_board_state.dead_goat_count += 1
		copied_board_state.move_count += 1
		copied_board_state.player_role = 'g'
		return rollout(copied_board_state, player_type)
	

#Returns true if game is terminated
func is_game_terminated(board_state: mcts_node) -> bool:
	if(board_state.dead_goat_count >= 5 || board_state.move_count > max_moves || all_tigers_trapped(board_state)):
		return true
		
	return false
		
	
func all_tigers_trapped(board_state: mcts_node) -> bool:
	for i in range(23):
		if(board_state.game_state_array[i] == 't'):
			if(not this_tiger_trapped(board_state,i)):
				return false;
	return true

func this_tiger_trapped(board_state: mcts_node, index: int) -> bool:
	for j in board_connectivity[index]:
		if(board_state.game_state_array[j] == 'b'):
			return false
	for jump in tiger_jumps[index]:
		if(board_state.game_state_array[jump[1]] == 'b'):
			return false
	return true
	
	
#Reward function
func reward(board_state: mcts_node, player_type: String) -> float:
	if(player_type == 'g'):
		if(board_state.dead_goat_count >= 5):
			return loss
		elif(board_state.move_count > max_moves):
			return draw
		elif(all_tigers_trapped(board_state)):
			return win
	
	elif(player_type == 't'):
		if(board_state.dead_goat_count >= 5):
			return win
		elif(board_state.move_count > max_moves):
			return draw
		elif(all_tigers_trapped(board_state)):
			return loss
			
	push_error("reward() called on non-terminal state")
	return 0
	
#MCTS node declaration
class mcts_node:
	var game_state_array: Array[String]  = []#indices:0-22(game state), 23(dead goat count), 24(number of moves) 
	var t: float 
	var n: int
	var dead_goat_count: int
	var move_count: int
	var parent: mcts_node
	var children: Array [mcts_node] 
	var UCB1: float:
		get:
			return t/n + 2*sqrt(log(parent.n if parent else 0) / n)
		set(v):
			UCB1 = v
	var player_role: String
