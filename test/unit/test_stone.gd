# test/unit/test_stone.gd
extends GutTest

# ============================================================
# 任务 1.1 — Stone 枚举 行为规格
# ============================================================
#
# Stone 是一个纯数据类，只做一件事：定义棋子的三种状态（空/黑/白），
# 并提供 opponent() 方法快速切换黑白双方。
#
# 围棋中"对手颜色"这个概念到处都要用：
#   - 提子时需要检查「邻居是不是对方棋子」
#   - 棋组 BFS 时碰到对方棋子要停下
#   - AI 评估时需要知道对方是谁
#
# 所以这个方法虽然只有 6 行，但整个项目都会依赖它。
# ============================================================

# ------------------------------------------------------------
# 测试 1: 黑棋的对手是白棋
#
# 场景：Given  当前有一方是黑棋 (Stone.Type.BLACK)
#        When   问「黑棋的对手是谁」
#        Then   应该回答「白棋」(Stone.Type.WHITE)
#
# 这是 opponent() 最基本的功能——黑白互转。
# ------------------------------------------------------------
func test_opponent_black_returns_white():
	assert_eq(Stone.opponent(Stone.Type.BLACK), Stone.Type.WHITE)

# ------------------------------------------------------------
# 测试 2: 白棋的对手是黑棋
#
# 场景：Given  当前有一方是白棋 (Stone.Type.WHITE)
#        When   问「白棋的对手是谁」
#        Then   应该回答「黑棋」(Stone.Type.BLACK)
#
# 对称验证——两个方向都要对。
# ------------------------------------------------------------
func test_opponent_white_returns_black():
	assert_eq(Stone.opponent(Stone.Type.WHITE), Stone.Type.BLACK)

# ------------------------------------------------------------
# 测试 3: 空位的对手还是空位
#
# 场景：Given  当前位置为空 (Stone.Type.EMPTY)，没有棋子
#        When   问「空位的对手是谁」
#        Then   应该回答「还是空位」(Stone.Type.EMPTY)
#
# 边界情况——空位置没有对手，返回自身，避免下游代码出错。
# ------------------------------------------------------------
func test_opponent_empty_returns_empty():
	assert_eq(Stone.opponent(Stone.Type.EMPTY), Stone.Type.EMPTY)
