# test/unit/test_rules.gd
extends GutTest

# ============================================================
# 任务 2.1 — GoRules 占位检测 行为规格
# ============================================================
#
# GoRules 是围棋规则引擎，play_move() 是所有落子操作的唯一入口。
# 阶段 2.1 实现第一条规则：不能往已经有棋子的位置落子。
# 同时验证棋盘边界外的坐标也会被拒绝。
# ============================================================

# ------------------------------------------------------------
# 测试 1: 空位落子合法——在空交叉点落子应该成功
#
# 场景：Given  空棋盘，目标位置 (3,3) 是空位
#        When   黑方调用 play_move(board, 3, 3, BLACK)
#        Then   返回 valid=true，captured 为空
#
# 这是最正常的落子——空位、界内、无冲突。
# ------------------------------------------------------------
func test_play_on_empty_intersection_is_valid():
    var board = Board.new()
    var rules = GoRules.new()
    var result = rules.play_move(board, 3, 3, Stone.Type.BLACK)
    assert_true(result.valid)
    assert_eq(result.captured.size(), 0)

# ------------------------------------------------------------
# 测试 2: 占位检测——已有棋子的位置不能再落子
#
# 场景：Given  棋盘 (3,3) 已经有黑子
#        When   白方尝试在同一个位置 (3,3) 落子
#        Then   返回 valid=false，reason="occupied"
#
# 围棋基本规则：一个交叉点只能放一颗棋子。
# ------------------------------------------------------------
func test_play_on_occupied_intersection_is_invalid():
    var board = Board.new()
    board.set_stone(3, 3, Stone.Type.BLACK)
    var rules = GoRules.new()
    var result = rules.play_move(board, 3, 3, Stone.Type.WHITE)
    assert_false(result.valid)
    assert_eq(result.reason, "occupied")

# ------------------------------------------------------------
# 测试 3: 边界外落子——棋盘外的坐标直接拒绝
#
# 场景：Given  19×19 棋盘
#        When   尝试在 (-1, 0) 落子（row 为负，超出棋盘）
#        Then   返回 valid=false
#
# 边界检测是第一道防线——后面的提子/劫检测都假设坐标在界内。
# ------------------------------------------------------------
func test_play_out_of_bounds_is_invalid():
    var board = Board.new()
    var rules = GoRules.new()
    var result = rules.play_move(board, -1, 0, Stone.Type.BLACK)
    assert_false(result.valid)

# ------------------------------------------------------------
# 测试 4: 单子被提——堵住对方最后一口气，对方棋子被移除
#
# 场景：Given  白子 (2,3) 只剩一口气在 (1,3)，其余三面被黑子包围
#        When   黑方在 (1,3) 落子堵住最后一口气
#        Then   返回 valid=true，白子 (2,3) 从棋盘移除，captured 包含 [(2,3)]
# ------------------------------------------------------------
func test_capture_single_stone():
    var board = Board.new()
    board.set_stone(2, 3, Stone.Type.WHITE)
    board.set_stone(2, 2, Stone.Type.BLACK)
    board.set_stone(2, 4, Stone.Type.BLACK)
    board.set_stone(3, 3, Stone.Type.BLACK)
    var rules = GoRules.new()
    var result = rules.play_move(board, 1, 3, Stone.Type.BLACK)
    assert_true(result.valid)
    assert_eq(result.captured.size(), 1)
    assert_eq(board.get_stone(2, 3), Stone.Type.EMPTY, "白子应被移除")

# ------------------------------------------------------------
# 测试 5: 同时提掉多组——一次落子让对方多个棋组同时无气
#
# 场景：Given  两枚白子分别在 (2,3) 和 (4,3)，各自只剩一口气
#        When   黑方落子同时堵住两口气
#        Then   captured 包含两枚白子坐标
# ------------------------------------------------------------
func test_capture_multiple_groups():
    var board = Board.new()
    # 白子 (2,1)：被 (1,1)(3,1)(2,0) 三黑包围，只剩一口气在 (2,2)
    board.set_stone(2, 1, Stone.Type.WHITE)
    board.set_stone(1, 1, Stone.Type.BLACK)
    board.set_stone(3, 1, Stone.Type.BLACK)
    board.set_stone(2, 0, Stone.Type.BLACK)
    # 白子 (2,3)：被 (1,3)(3,3)(2,4) 三黑包围，只剩一口气在 (2,2)
    board.set_stone(2, 3, Stone.Type.WHITE)
    board.set_stone(1, 3, Stone.Type.BLACK)
    board.set_stone(3, 3, Stone.Type.BLACK)
    board.set_stone(2, 4, Stone.Type.BLACK)
    # 两个白子共享仅剩的气 (2,2)
    var rules = GoRules.new()
    var result = rules.play_move(board, 2, 2, Stone.Type.BLACK)
    assert_true(result.valid)
    assert_eq(result.captured.size(), 2)
