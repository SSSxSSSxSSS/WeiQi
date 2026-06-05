# test/unit/test_ai_mcts.gd
extends GutTest

# ============================================================
# MCTS AI 行为规格
# ============================================================
# 用 9×9 棋盘 + 少量模拟验证 MCTS 基本功能

# ------------------------------------------------------------
# 测试 1: 空棋盘 9×9 — 返回合法坐标（50 次模拟）
# ------------------------------------------------------------
func test_mcts_returns_valid_move_9x9():
	var ai := AiMcts.new(50)
	var board := Board.new(9)
	var move := ai.get_move(board, Stone.Type.BLACK)
	assert_true(move.x >= 0 and move.x < 9,
		"应返回合法坐标，实际: (%d,%d)" % [move.x, move.y])
	assert_true(move.y >= 0 and move.y < 9)

# ------------------------------------------------------------
# 测试 2: get_name
# ------------------------------------------------------------
func test_mcts_name():
	var ai := AiMcts.new(100)
	assert_eq(ai.get_name(), "MCTS AI")
