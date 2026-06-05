# src/ai/ai_mcts.gd
class_name AiMcts
extends AiBase

const DEFAULT_SIMULATIONS := 200
const UCB_C := 1.4
const ROLLOUT_LIMIT := 80

var _simulations: int

func _init(simulations: int = DEFAULT_SIMULATIONS) -> void:
	_simulations = simulations

func get_move(board: Board, color: Stone.Type) -> Vector2i:
	var root: _MctsNode = _MctsNode.new(board, Vector2i(-1, -1), null)
	var opponent: Stone.Type = Stone.opponent(color)

	for _i in _simulations:
		var node: _MctsNode = root
		var sim_board: Board = board.clone()
		var sim_rules: GoRules = GoRules.new()
		var sim_color: Stone.Type = color

		# 1. Selection: 沿 UCB1 走到叶节点
		while node._untried_moves.is_empty() and not node._children.is_empty():
			node = node._best_child(UCB_C)
			sim_rules.play_move(sim_board, node._move.x, node._move.y, sim_color)
			sim_color = Stone.opponent(sim_color)

		# 2. Expansion
		if not node._untried_moves.is_empty():
			var idx: int = randi() % node._untried_moves.size()
			var move: Vector2i = node._untried_moves[idx]
			node._untried_moves.remove_at(idx)
			var r: MoveResult = sim_rules.play_move(sim_board, move.x, move.y, sim_color)
			if r.valid:
				sim_color = Stone.opponent(sim_color)
				node = node._add_child(sim_board, move)

		# 3. Simulation: 轻量随机下到底
		var winner: Stone.Type = _rollout_light(sim_board, sim_color)

		# 4. Backpropagation
		var result: float = 0.5
		if winner == color:
			result = 1.0
		elif winner == opponent:
			result = 0.0
		while node != null:
			node._visits += 1
			node._wins += result
			result = 1.0 - result
			node = node._parent

	if root._children.is_empty():
		return Vector2i(-1, -1)

	var best: _MctsNode = root._children[0]
	for c in root._children:
		if c._visits > best._visits:
			best = c
	return best._move

## 轻量随机模拟——随机选空位落子
func _rollout_light(board: Board, color: Stone.Type) -> Stone.Type:
	var rules := GoRules.new()
	var spots: Array[Vector2i] = []
	# 收集空位
	for row in board.size:
		for col in board.size:
			if board.get_stone(row, col) == Stone.Type.EMPTY:
				spots.append(Vector2i(row, col))

	var passes := 0
	var tried: int = 0
	var max_tries: int = min(spots.size(), ROLLOUT_LIMIT)

	while spots.size() > 0 and tried < max_tries:
		var idx: int = randi() % spots.size()
		var move: Vector2i = spots[idx]
		# swap-remove: O(1)
		spots[idx] = spots[spots.size() - 1]
		spots.remove_at(spots.size() - 1)
		tried += 1

		var r: MoveResult = rules.play_move(board, move.x, move.y, color)
		if r.valid:
			color = Stone.opponent(color)
			passes = 0
		else:
			passes += 1
			if passes >= 2:
				break

	# 双方 pass 或空位耗尽 → 计分
	var score: Dictionary = GoScoring.score(board, 7.5)
	return score["winner"]

func get_name() -> String:
	return "MCTS AI"

func get_level() -> String:
	return "MCTS (%d次)" % _simulations

# ============================================================
class _MctsNode:
	var _board: Board
	var _move: Vector2i
	var _parent: _MctsNode
	var _children: Array
	var _untried_moves: Array[Vector2i]
	var _visits: int = 0
	var _wins: float = 0.0

	func _init(board: Board, move: Vector2i, parent: _MctsNode) -> void:
		_move = move
		_parent = parent
		_children = []
		_untried_moves = []
		_visits = 0
		_wins = 0.0
		# 只收集空位
		if board != null:
			for row in board.size:
				for col in board.size:
					if board.get_stone(row, col) == Stone.Type.EMPTY:
						_untried_moves.append(Vector2i(row, col))
			_untried_moves.shuffle()

	func _add_child(board: Board, move: Vector2i) -> _MctsNode:
		var child: _MctsNode = _MctsNode.new(board, move, self)
		_children.append(child)
		return child

	func _best_child(c: float) -> _MctsNode:
		var best: _MctsNode = _children[0]
		var best_val: float = -INF
		var ln_total: float = log(float(_visits))
		for child in _children:
			if child._visits == 0:
				return child
			var exploit: float = child._wins / float(child._visits)
			var explore: float = c * sqrt(ln_total / float(child._visits))
			var val: float = exploit + explore
			if val > best_val:
				best_val = val
				best = child
		return best
