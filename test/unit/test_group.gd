# test/unit/test_group.gd
extends GutTest

# ============================================================
# 任务 1.3 — StoneGroup 棋组类 行为规格
# ============================================================
#
# StoneGroup 用 BFS（广度优先搜索）算法从一个棋子出发，
# 找到所有和它同色相连的棋子以及这些棋子共有的气（空位）。
#
# 这个类是提子规则和计分系统的基础：
#   - 提子：对方的棋组没气了 → 全部提掉
#   - 自杀：自己落下后棋组没气了且没提掉对方子 → 不合法
#   - 计分：计算每块棋围住的空域
# ============================================================

# ------------------------------------------------------------
# 测试 1: 单子四气——孤立棋子有四个方向的空位
#
# 场景：Given  棋盘上只有 (3,3) 一枚黑子，周围全是空位
#        When   从 (3,3) 出发调用 build_group
#        Then   stones 包含 [(3,3)]（1个），liberties 包含 [(2,3),(4,3),(3,2),(3,4)]（4个）
#
# 这是最简单的棋组——一个子四个方向都是气。
# ------------------------------------------------------------
func test_single_stone_has_four_liberties():
	var board = Board.new()
	board.set_stone(3, 3, Stone.Type.BLACK)
	var result = StoneGroup.build_group(board, Vector2i(3, 3))
	assert_eq(result["stones"].size(), 1)
	assert_eq(result["liberties"].size(), 4)

# ------------------------------------------------------------
# 测试 2: 相连棋组共享气——两个同色相连棋子共 6 口气
#
# 场景：Given  (3,3) 和 (3,4) 各有一枚黑子，它们水平相邻
#        When   从 (3,3) 出发调用 build_group
#        Then   stones 包含 2 个坐标，liberties 包含 6 个坐标
#
# 注意：不是 8 个！因为两子共享的边不再是气，
# 而且各自有 3 个独立方向 + 共享 = 总共 6 个。
# ------------------------------------------------------------
func test_connected_stones_share_liberties():
	var board = Board.new()
	board.set_stone(3, 3, Stone.Type.BLACK)
	board.set_stone(3, 4, Stone.Type.BLACK)
	var result = StoneGroup.build_group(board, Vector2i(3, 3))
	assert_eq(result["stones"].size(), 2)
	assert_eq(result["liberties"].size(), 6)

# ------------------------------------------------------------
# 测试 3: 被围无气——棋子被对方完全包围
#
# 场景：Given  黑子 (3,3) 的上下左右紧邻位置全是白子
#        When   从 (3,3) 出发调用 build_group
#        Then   stones 包含 1 个，liberties 为空
#
# 这颗黑子马上就会被提掉——这是围棋最基本规则。
# ------------------------------------------------------------
func test_surrounded_stone_has_no_liberties():
	var board = Board.new()
	board.set_stone(3, 3, Stone.Type.BLACK)
	board.set_stone(2, 3, Stone.Type.WHITE)  # 上
	board.set_stone(4, 3, Stone.Type.WHITE)  # 下
	board.set_stone(3, 2, Stone.Type.WHITE)  # 左
	board.set_stone(3, 4, Stone.Type.WHITE)  # 右
	var result = StoneGroup.build_group(board, Vector2i(3, 3))
	assert_eq(result["stones"].size(), 1)
	assert_eq(result["liberties"].size(), 0)

# ------------------------------------------------------------
# 测试 4: 异色不连通——BFS 不跨越对方棋子
#
# 场景：Given  黑子 (3,3)，右边 (3,4) 是白子
#        When   从 (3,3) 出发调用 build_group
#        Then   stones 只包含 [(3,3)]，不包含白子
#
# BFS 碰到异色棋子要停下，不能穿越过去。
# ------------------------------------------------------------
func test_bfs_does_not_cross_opponent():
	var board = Board.new()
	board.set_stone(3, 3, Stone.Type.BLACK)
	board.set_stone(3, 4, Stone.Type.WHITE)  # 右边是白子
	var result = StoneGroup.build_group(board, Vector2i(3, 3))
	assert_eq(result["stones"].size(), 1, "只包含种子自身")
