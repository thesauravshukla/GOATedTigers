extends Node2D
# Called when the node enters the scene tree for the first time.
class_name mcts



#constants
var epsilon: float = 0.001
var win_weight: float = 1		#reward for a win result
var loss_weight: float = -1	#reward for a loss result
var draw_weight: float = -1	#reward for a draw result


func MCTS_SIM(board_state: mcts_node,iteration_count: int) -> mcts_node:
	#if game terminated then return board_state
	if(board_utils.is_game_terminated(board_state)):
		breakpoint
	
	var player_type = board_state.player_role
	for iteration in iteration_count :
		var leaf = board_state
		
		#checking if current node is a leaf node
		if(leaf.children.is_empty()):
			
			if(leaf.n != 0 and not board_utils.is_game_terminated(leaf)):
				node_expansion(leaf)
				
				#rollout will be carried out on the first children of the current node
				leaf = leaf.children[randi() % leaf.children.size()]
			
		else:
			#when current node is not a leaf node 
			while(not leaf.children.is_empty()):
				
				#finding the child node with maximum UCB1 value
				var max_UCB1: float = -INF
				var max_UCB1_index_list: Array = []
				for i in range(0,leaf.children.size()):
					if(leaf.children[i].UCB1 > max_UCB1):
						max_UCB1 = leaf.children[i].UCB1
					
				for i in range(0,leaf.children.size()):
					if(abs(max_UCB1 - leaf.children[i].UCB1) <= epsilon):
						max_UCB1_index_list.push_back(i)
				
				#choosing a random child from all the children having max_t value		
				var random_max_UCB1_index = randi() % max_UCB1_index_list.size()
				
				#exploring the child node randomly that maximizes the UCB1 value
				leaf = leaf.children[max_UCB1_index_list[random_max_UCB1_index]]
			
			#performing node expansion when n_i of current node is not 0
			if(leaf.n != 0):
				node_expansion(leaf)
				
				#rollout will be carried out on first children of current node
				leaf = leaf.children[randi() % leaf.children.size()]
		
		#backpropagation for storing reward values obtained from rollout		
		backpropagation(board_state,leaf,rollout(leaf,player_type))
		
	#looking for the next action that maximizes t_i 
	var max_t_index_list: Array = []
	var max_t_val = -INF

	for i in range(0,board_state.children.size()):
		if(board_state.children[i].t > max_t_val):
			max_t_val = board_state.children[i].t
	
	for i in range (0,board_state.children.size()):
		if(abs(board_state.children[i].t - max_t_val) <= epsilon):
			max_t_index_list.push_back(i)
	
	#choosing a random child from all the children having max_t value		
	var random_max_t_index = randi() % max_t_index_list.size()
		
	#returning the next board state 
	return board_state.children[max_t_index_list[random_max_t_index]]
	
func backpropagation(root_node: mcts_node, leaf_node: mcts_node, rollout_reward: float) -> void:
	var curr_node = leaf_node
	while(1):
		curr_node.t += rollout_reward
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
			var valid_goat_moves: Array[Array] = []
			for i in range(23):
				if(board_state.game_state_array[i] == 'g'):
					for j in board_utils.board_connectivity[i]:
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
				for jump in board_utils.tiger_jumps[i]:
					if(board_state.game_state_array[jump[0]] == 'g' && board_state.game_state_array[jump[1]] == 'b'):
						valid_tiger_moves.push_back([i,jump[1],1,jump[0]])
				for neighbour in board_utils.board_connectivity[i]:
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
	if(board_utils.is_game_terminated(board_state)):
		return reward(board_state, player_type)
		
	var copied_board_state = board_utils.deepcopy(board_state)
	
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
					for j in board_utils.board_connectivity[i]:
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
				for jump in board_utils.tiger_jumps[i]:
					if(copied_board_state.game_state_array[jump[0]] == 'g' && copied_board_state.game_state_array[jump[1]] == 'b'):
						valid_tiger_moves.push_back([i,jump[1],1,jump[0]])
				for neighbour in board_utils.board_connectivity[i]:
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


	#Reward function
func reward(board_state: mcts_node, player_type: String) -> float:
	if(player_type == 'g'):
		if(board_state.dead_goat_count >= 5):
			return loss_weight
		elif(board_state.move_count > board_utils.max_moves):
			return draw_weight
		elif(board_utils.all_tigers_trapped(board_state)):
			return win_weight
	
	elif(player_type == 't'):
		if(board_state.dead_goat_count >= 5):
			return 0
		elif(board_state.move_count > board_utils.max_moves):
			return 0
		elif(board_utils.all_tigers_trapped(board_state)):
			return 1
			
	push_error("reward() called on a non-terminal state")
	return 0
	

	
# Calculates UCB1 value
func UCB1(board_state: mcts_node) -> float:
	return (board_state.t)/(board_state.n) + 2*sqrt((log(board_state.parent.n)/board_state.n))

