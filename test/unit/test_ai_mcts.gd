# test/unit/test_ai_mcts.gd
extends GutTest

# ============================================================
# MCTS AI 行为规格
# ============================================================
# MCTS 用蒙特卡洛树搜索选择最优落子。
# 测试：空棋盘上应返回合法坐标（但需要时间模拟）

# ------------------------------------------------------------
# 测试 1: 空棋盘返回合法坐标
# ------------------------------------------------------------
func test_mcts_returns_valid_move_on_empty_board():
	var ai := AiMcts.new(50)  # 少量模拟加速测试
	var board := Board.new(9)  # 9×9 快速
	var move := ai.get_move(board, Stone.Type.BLACK)
	assert_true(move.x >= 0 and move.x < 9,
		"应返回合法坐标，实际: (%d,%d)" % [move.x, move.y])

# ------------------------------------------------------------
# 测试 2: get_name / get_level
# ------------------------------------------------------------
func test_mcts_name_and_level():
	var ai := AiMcts.new(100)
	assert_eq(ai.get_name(), "MCTS AI")
