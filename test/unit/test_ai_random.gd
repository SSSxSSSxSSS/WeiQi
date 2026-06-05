# test/unit/test_ai_random.gd
extends GutTest

# ============================================================
# 任务 3.2 — AiRandom 行为规格
# ============================================================
# AiRandom 从所有合法落子中随机选一个，无合法则 pass。

# ------------------------------------------------------------
# 测试 1: 空棋盘上返回界内合法坐标
# ------------------------------------------------------------
func test_random_returns_valid_move_on_empty_board():
    var ai = AiRandom.new()
    var board = Board.new()
    var move = ai.get_move(board, Stone.Type.BLACK)
    assert_true(move.x >= 0 and move.x < 19 and move.y >= 0 and move.y < 19,
        "空棋盘上应返回合法坐标，实际: (%d,%d)" % [move.x, move.y])

# ------------------------------------------------------------
# 测试 2: 多态——通过 AiBase 类型调用 AiRandom
# ------------------------------------------------------------
func test_polymorphism_ai_random_through_base():
    var ai: AiBase = AiRandom.new()
    var board = Board.new()
    var move = ai.get_move(board, Stone.Type.BLACK)
    assert_eq(ai.get_name(), "随机 AI")
    assert_true(move.x >= 0 and move.x < 19)
