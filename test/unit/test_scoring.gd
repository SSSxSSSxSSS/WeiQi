# test/unit/test_scoring.gd
extends GutTest

# ============================================================
# 阶段 4 — GoScoring 计分系统 行为规格
# ============================================================
#
# 中国规则：黑方得分 = 黑子 + 黑空，白方得分 = 白子 + 白空 + 贴目(7.5)
# 空域归属：只邻黑 → 归黑，只邻白 → 归白，邻双方 → 中立

# ------------------------------------------------------------
# 测试 1: 空棋盘——无子，无空域归属，白得贴目
# ------------------------------------------------------------
func test_empty_board_white_wins_by_komi():
    var board = Board.new()
    var result = GoScoring.score(board, 7.5)
    assert_eq(result["black_score"], 0.0)
    assert_eq(result["white_score"], 7.5)
    assert_eq(result["winner"], Stone.Type.WHITE)

# ------------------------------------------------------------
# 测试 2: 简单终局——黑占角落，空域归黑
# ------------------------------------------------------------
# ------------------------------------------------------------
# 测试 2: 简单终局——黑围住一个空位，归黑
# ------------------------------------------------------------
func test_black_territory_in_corner():
    var board = Board.new()
    board.set_stone(0, 0, Stone.Type.BLACK)
    board.set_stone(0, 1, Stone.Type.BLACK)
    board.set_stone(1, 0, Stone.Type.BLACK)
    # (1,1) 空位只邻黑 → 归黑
    var result = GoScoring.score(board, 0.0)
    assert_eq(result["black_score"], 361.0, "全盘无白子，全部归黑")
    assert_eq(result["white_score"], 0.0)

# ------------------------------------------------------------
# 测试 3: 边界上有双方棋子 → 空域中立
# ------------------------------------------------------------
func test_mixed_border_territory_is_neutral():
    var board = Board.new()
    board.set_stone(0, 0, Stone.Type.BLACK)
    board.set_stone(0, 2, Stone.Type.WHITE)
    # 空域同时邻黑邻白 → 中立不计
    var result = GoScoring.score(board, 0.0)
    assert_eq(result["black_score"], 1.0, "1 黑子，空域中立不计")
    assert_eq(result["white_score"], 1.0, "1 白子")
