# src/ai/ai_mcts.gd
class_name AiMcts
extends AiBase

const DEFAULT_SIMULATIONS := 300
const UCB_C := 1.4

var _simulations: int
var _rules: GoRules
var _my_color: Stone.Type

func _init(simulations: int = DEFAULT_SIMULATIONS) -> void:
	_simulations = simulations
	_rules = GoRules.new()

func get_move(board: Board, color: Stone.Type) -> Vector2i:
	_my_color = color
	var root: _MctsNode = _MctsNode.new(board, Vector2i(-1, -1), null)

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

		# 2. Expansion: 展开一个未尝试的走法
		if not node._untried_moves.is_empty():
			var idx: int = randi() % node._untried_moves.size()
			var move: Vector2i = node._untried_moves[idx]
			node._untried_moves.remove_at(idx)
			sim_rules.play_move(sim_board, move.x, move.y, sim_color)
			sim_color = Stone.opponent(sim_color)
			node = node._add_child(sim_board, move)

		# 3. Simulation: 随机下到底
		sim_color = _rollout(sim_board, sim_rules, sim_color)

		# 4. Backpropagation: 回传结果
		var result: float = 0.0
		if sim_color == color:
			result = 1.0  # 我方胜利
		elif sim_color == Stone.opponent(color):
			result = 0.0  # 对方胜利
		else:
			result = 0.5  # 平局
		while node != null:
			node._visits += 1
			node._wins += result
			result = 1.0 - result
			node = node._parent

	if root._children.is_empty():
		return Vector2i(-1, -1)

	# 选访问次数最多的子节点
	var best: _MctsNode = root._children[0]
	for c in root._children:
		if c._visits > best._visits:
			best = c
	return best._move

## 随机模拟到终局（最多 step_limit 步）
func _rollout(board: Board, rules: GoRules, color: Stone.Type, step_limit: int = 200) -> Stone.Type:
	var steps: int = 0
	var opponent: Stone.Type = Stone.opponent(color)
	# 先用启发式策略收集合法走法（比纯随机快）
	while steps < step_limit:
		var candidates: Array[Vector2i] = []
		for row in board.size:
			for col in board.size:
				var test_board: Board = board.clone()
				var test_rules: GoRules = GoRules.new()
				var r: MoveResult = test_rules.play_move(test_board, row, col, color)
				if r.valid:
					candidates.append(Vector2i(row, col))
		if candidates.is_empty():
			rules.do_pass()
			opponent = Stone.opponent(opponent)
			color = opponent
			# 连续的 pass
			if steps > 0 and candidates.is_empty():
				break
		else:
			var move: Vector2i = candidates[randi() % candidates.size()]
			rules.play_move(board, move.x, move.y, color)
			color = opponent
			opponent = Stone.opponent(opponent)
		steps += 1
		if steps > step_limit - 1:
			break
	# 用中国规则判定胜负
	var score: Dictionary = GoScoring.score(board, 7.5)
	if score["winner"] == Stone.Type.BLACK:
		return Stone.Type.BLACK
	elif score["winner"] == Stone.Type.WHITE:
		return Stone.Type.WHITE
	return Stone.Type.EMPTY

func get_name() -> String:
	return "MCTS AI"

func get_level() -> String:
	return "困难+ (%d)" % _simulations

# ============================================================
# 内部类：MCTS 节点
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
		_board = board.clone() if board else null
		_move = move
		_parent = parent
		_children = []
		_untried_moves = _collect_moves(board)
		_visits = 0
		_wins = 0.0

	func _collect_moves(board: Board) -> Array[Vector2i]:
		var moves: Array[Vector2i] = []
		if board == null:
			return moves
		for row in board.size:
			for col in board.size:
				moves.append(Vector2i(row, col))
		moves.shuffle()
		return moves

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
