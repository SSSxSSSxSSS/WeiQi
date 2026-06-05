# src/ai/ai_heuristic.gd
class_name AiHeuristic
extends AiBase

enum Level { NORMAL, HARD }

var _level: Level

func _init(level: Level = Level.NORMAL) -> void:
	_level = level

func get_move(board: Board, color: Stone.Type) -> Vector2i:
	var opponent: Stone.Type = Stone.opponent(color)
	var candidates: Array[Dictionary] = []

	# 局势评估：统计双方棋子分布
	var my_count: int = 0
	for row in board.size:
		for col in board.size:
			if board.get_stone(row, col) == color:
				my_count += 1
	var is_opening: bool = my_count < 4  # 开局阶段

	for row in board.size:
		for col in board.size:
			var test_board: Board = board.clone()
			var rules: GoRules = GoRules.new()
			var result: MoveResult = rules.play_move(test_board, row, col, color)
			if not result.valid:
				continue

			var score: float = 0.0
			var sz := board.size

			# ===== 基础位置分 =====
			# 角
			if (row == 0 or row == sz - 1) and (col == 0 or col == sz - 1):
				score += 25.0 if is_opening else 15.0
			# 星位（仅 19 路）
			elif sz == 19 and row in [3, 9, 15] and col in [3, 9, 15]:
				score += 10.0 if is_opening else 6.0
			# 边上
			elif row == 0 or row == sz - 1 or col == 0 or col == sz - 1:
				score += 5.0
			# 邻近角（挂角好点）
			elif is_opening and sz == 19:
				if row in [2, 3] and col in [2, 3]:
					score += 8.0

			# ===== 提子 =====
			score += result.captured.size() * 12.0

			# ===== 接近己方棋子 =====
			var near_friend: int = 0
			var near_enemy: int = 0
			for nb in board.get_neighbors(row, col):
				var ns: Stone.Type = board.get_stone(nb.x, nb.y)
				if ns == color:
					near_friend += 1
				elif ns == opponent:
					near_enemy += 1
			score += near_friend * 3.0

			# ===== 简单前瞻：对方能否提掉我 =====
			var my_group: Dictionary = StoneGroup.build_group(test_board, Vector2i(row, col))
			var can_be_captured: bool = my_group["liberties"].size() == 1
			if can_be_captured:
				# 检查唯一的气是否会被对方堵住
				var lib: Vector2i = my_group["liberties"][0]
				var capture_rules := GoRules.new()
				var capture_board := test_board.clone()
				var capture_result := capture_rules.play_move(capture_board, lib.x, lib.y, opponent)
				if capture_result.valid and capture_result.captured.size() > 0:
					score -= 30.0  # 会被立刻提掉

			# ===== 随机扰动 =====
			score += randf_range(0.0, 1.5)

			# ===== 困难难度额外评估 =====
			if _level == Level.HARD:
				# 己方危险
				if my_group["liberties"].size() <= 1 and not can_be_captured:
					score -= 25.0

				# 逼迫对方
				for nb in test_board.get_neighbors(row, col):
					var ns: Stone.Type = test_board.get_stone(nb.x, nb.y)
					if ns == opponent:
						var og: Dictionary = StoneGroup.build_group(test_board, nb)
						if og["liberties"].size() == 1:
							score += 18.0

				# 避开对方厚势（对方棋子密集区）
				if near_enemy >= 3 and near_friend < 2:
					score -= near_enemy * 4.0

			candidates.append({ "pos": Vector2i(row, col), "score": score })

	if candidates.is_empty():
		return Vector2i(-1, -1)

	var best: Dictionary = candidates[0]
	for c in candidates:
		if c["score"] > best["score"]:
			best = c
	return best["pos"]

func get_name() -> String:
	return "启发式 AI"

func get_level() -> String:
	return "普通" if _level == Level.NORMAL else "困难"
