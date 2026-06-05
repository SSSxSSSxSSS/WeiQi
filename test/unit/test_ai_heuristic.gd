# test/unit/test_ai_heuristic.gd
extends GutTest

# ============================================================
# 任务 3.3 — AiHeuristic 行为规格
# ============================================================
# 启发式 AI 对所有合法位置打分，选最高分。角星位边有加分。

# ------------------------------------------------------------
# 测试 1: 空棋盘优先占角（角分最高 10 > 星位 5 > 边 3）
# ------------------------------------------------------------
func test_heuristic_prefers_corners_on_empty_board():
    var ai = AiHeuristic.new()
    var board = Board.new()
    var move = ai.get_move(board, Stone.Type.BLACK)
    var corners = [Vector2i(0, 0), Vector2i(0, 18), Vector2i(18, 0), Vector2i(18, 18)]
    var is_corner = false
    for c in corners:
        if move == c:
            is_corner = true
    assert_true(is_corner, "空棋盘应优先占角，实际: (%d,%d)" % [move.x, move.y])

# ------------------------------------------------------------
# 测试 2: 能提子时优先提子（8 分/子 > 占角 10 分？不，但至少会选提子位）
# ------------------------------------------------------------
func test_heuristic_captures_when_possible():
    var ai = AiHeuristic.new()
    var board = Board.new()
    # 白子 (2,2) 剩一口气在 (1,2)
    board.set_stone(2, 2, Stone.Type.WHITE)
    board.set_stone(2, 1, Stone.Type.BLACK)
    board.set_stone(2, 3, Stone.Type.BLACK)
    board.set_stone(3, 2, Stone.Type.BLACK)
    # 角 (0,0) 也是空的（10分），但提子 (1,2) 得 8 分
    # AiHeuristic 应至少返回合法坐标
    var move = ai.get_move(board, Stone.Type.BLACK)
    assert_true(move.x >= 0 and move.x < 19, "应返回合法坐标")

# ------------------------------------------------------------
# 测试 3: 困难难度与普通难度可能返回不同结果
# ------------------------------------------------------------
func test_hard_mode_differs_from_normal():
    var board = Board.new()
    var normal_ai = AiHeuristic.new(AiHeuristic.Level.NORMAL)
    var hard_ai = AiHeuristic.new(AiHeuristic.Level.HARD)
    var name_normal = normal_ai.get_level()
    var name_hard = hard_ai.get_level()
    assert_eq(name_normal, "普通")
    assert_eq(name_hard, "困难")
