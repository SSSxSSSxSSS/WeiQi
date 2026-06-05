# test/unit/test_board.gd
extends GutTest

const Board = preload("res://src/core/board.gd")

# ============================================================
# 任务 1.2 — Board 棋盘类 行为规格
# ============================================================
#
# Board 是 19×19 围棋棋盘的数据结构。它只管棋子的存取和边界判断，
# 不管围棋规则（提子、劫、自杀等）——那些是 GoRules（阶段 2）的职责。
#
# 核心能力：
#   1. 初始化一个全空的 19×19 棋盘
#   2. 在任意位置放置/读取棋子
#   3. 判断坐标是否在棋盘范围内
#   4. 深拷贝（AI 模拟和劫检测的基础，浅拷贝会导致严重 bug）
#   5. 获取某个位置的四方向邻居坐标
# ============================================================

# ------------------------------------------------------------
# 测试 1: 初始化——新棋盘全部为空
#
# 场景：Given  创建一个全新的 19×19 Board
#        When   遍历所有 361 个交叉点
#        Then   每个位置都返回 Stone.Type.EMPTY
#
# 这是棋盘最基本的保证——不能让任何位置有初始脏数据。
# ------------------------------------------------------------
func test_board_init_all_empty():
    var board = Board.new()
    for row in Board.SIZE:
        for col in Board.SIZE:
            assert_eq(board.get_stone(row, col), Stone.Type.EMPTY,
                "位置 (%d,%d) 应为空" % [row, col])

# ------------------------------------------------------------
# 测试 2: 放置与读取棋子
#
# 场景：Given  空棋盘
#        When   在 (3,3) 放置 BLACK
#        Then   get_stone(3,3) 返回 BLACK，其余位置仍为 EMPTY
#
# 验证 set/get 正确性——放哪读哪，不污染其他位置。
# ------------------------------------------------------------
func test_set_and_get_stone():
    var board = Board.new()
    board.set_stone(3, 3, Stone.Type.BLACK)
    assert_eq(board.get_stone(3, 3), Stone.Type.BLACK)
    # 其他位置不受影响
    assert_eq(board.get_stone(0, 0), Stone.Type.EMPTY)
    assert_eq(board.get_stone(18, 18), Stone.Type.EMPTY)

# ------------------------------------------------------------
# 测试 3: 越界检测
#
# 场景：Given  19×19 棋盘，有效范围 (0,0)~(18,18)
#        When   检查 (-1,0)、(19,0)、(0,-1)、(0,19) 四个越界坐标
#        Then   is_on_board 全部返回 false
#
# 边界判断是防崩溃的第一道防线——所有涉及坐标的方法都会用到它。
# ------------------------------------------------------------
func test_is_on_board_rejects_out_of_bounds():
    var board = Board.new()
    assert_false(board.is_on_board(-1, 0), "(-1,0) 越界")
    assert_false(board.is_on_board(19, 0), "(19,0) 越界")
    assert_false(board.is_on_board(0, -1), "(0,-1) 越界")
    assert_false(board.is_on_board(0, 19), "(0,19) 越界")
    # 边界内应该通过
    assert_true(board.is_on_board(0, 0), "(0,0) 在界内")
    assert_true(board.is_on_board(18, 18), "(18,18) 在界内")

# ------------------------------------------------------------
# 测试 4: 角落坐标只有两个邻居
#
# 场景：Given  坐标 (0,0) 是棋盘左上角
#        When   调用 get_neighbors(0,0)
#        Then   返回 [(1,0), (0,1)]，只有右下两个方向
#
# 邻居坐标不包括越界方向——这是棋组 BFS 的基础。
# ------------------------------------------------------------
func test_get_neighbors_corner_only_two():
    var board = Board.new()
    var neighbors = board.get_neighbors(0, 0)
    assert_eq(neighbors.size(), 2, "角落应只有 2 个邻居")
    # 包含 (1,0) 和 (0,1)，不包含越界的 (-1,0) 和 (0,-1)
    var has_down = false
    var has_right = false
    for n in neighbors:
        if n == Vector2i(1, 0): has_down = true
        if n == Vector2i(0, 1): has_right = true
    assert_true(has_down, "应包含 (1,0)")
    assert_true(has_right, "应包含 (0,1)")

# ------------------------------------------------------------
# 测试 5: 深拷贝——修改副本不影响原棋盘
#
# 场景：Given  Board A 在 (5,5) 有 BLACK
#        When   调用 A.clone() 得到 Board B，然后修改 B 的 (5,5) 为 WHITE
#        Then   A.get_stone(5,5) 仍然是 BLACK
#
# ⚠️ 这是最容易出 bug 的地方！
# GDScript 的 Array.duplicate() 默认只浅拷贝一层，
# 必须对每一行都做 duplicate(true) 才是真正的深拷贝。
# 如果浅拷贝了，AI 模拟和劫检测都会静默出错。
# ------------------------------------------------------------
func test_clone_is_deep_copy():
    var board_a = Board.new()
    board_a.set_stone(5, 5, Stone.Type.BLACK)
    var board_b = board_a.clone()
    # 克隆的值相同
    assert_eq(board_b.get_stone(5, 5), Stone.Type.BLACK)
    # 修改克隆不影响原棋盘
    board_b.set_stone(5, 5, Stone.Type.WHITE)
    assert_eq(board_a.get_stone(5, 5), Stone.Type.BLACK,
        "深拷贝：修改副本不应影响原棋盘")
    assert_eq(board_b.get_stone(5, 5), Stone.Type.WHITE)
