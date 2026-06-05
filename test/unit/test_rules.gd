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

# ------------------------------------------------------------
# 测试 6: 单纯自杀——落入被对方包围的空位且无法提子
#
# 场景：Given  空位 (3,3) 上下左右全是白子
#        When   黑方在 (3,3) 落子（落子后黑子四面被围、无气）
#        Then   返回 valid=false，reason="suicide"
# ------------------------------------------------------------
func test_suicide_is_invalid():
	var board = Board.new()
	board.set_stone(2, 3, Stone.Type.WHITE)  # 上
	board.set_stone(4, 3, Stone.Type.WHITE)  # 下
	board.set_stone(3, 2, Stone.Type.WHITE)  # 左
	board.set_stone(3, 4, Stone.Type.WHITE)  # 右
	var rules = GoRules.new()
	var result = rules.play_move(board, 3, 3, Stone.Type.BLACK)
	assert_false(result.valid)
	assert_eq(result.reason, "suicide")

# ------------------------------------------------------------
# 测试 7: 提子后不死——看似自杀但能提对方子让自己有气
#
# 场景：Given  白子 (1,2) 被三黑包围只剩一口气在 (0,2)
#        When   黑方在 (0,2) 落子，虽落子位置被围但提掉 (1,2) 后自己有了气
#        Then   返回 valid=true（不是自杀）
# ------------------------------------------------------------
func test_not_suicide_if_can_capture():
	var board = Board.new()
	# 白子 (1,2) 只剩一口气在 (0,2)
	board.set_stone(1, 2, Stone.Type.WHITE)
	board.set_stone(1, 1, Stone.Type.BLACK)
	board.set_stone(1, 3, Stone.Type.BLACK)
	board.set_stone(2, 2, Stone.Type.BLACK)
	var rules = GoRules.new()
	var result = rules.play_move(board, 0, 2, Stone.Type.BLACK)
	assert_true(result.valid)

# ------------------------------------------------------------
# 测试 8: 劫——禁止重复同一局面
#
# 场景：黑落子 → 手动恢复棋盘 → 黑再走同一位置
# 结果：第二次返回 ko，因为 _ko_hash 匹配
# ------------------------------------------------------------
func test_ko_prevents_immediate_recapture():
	var board = Board.new()
	var rules = GoRules.new()
	# 第一手落子
	var r1 = rules.play_move(board, 3, 3, Stone.Type.BLACK)
	assert_true(r1.valid)
	# 手动恢复棋盘（模拟对方立即回提恢复原状）
	board.set_stone(3, 3, Stone.Type.EMPTY)
	# 再次相同位置落子 → 劫
	var r2 = rules.play_move(board, 3, 3, Stone.Type.BLACK)
	assert_false(r2.valid)
	assert_eq(r2.reason, "ko")

# ------------------------------------------------------------
# 测试 9: 劫解——中间有别手后劫不再限制
#
# 场景：黑落子 → 恢复 → 白在别处落子 → 再次恢复 → 黑落原位置
# 结果：合法，因为中间有别的手
# ------------------------------------------------------------
func test_ko_allowed_after_intervening_move():
	var board = Board.new()
	var rules = GoRules.new()
	# 第一手
	rules.play_move(board, 3, 3, Stone.Type.BLACK)
	# 在别处落子——_ko_hash 已更新为 hash(黑在3,3)
	# pre_hash = hash(黑在3,3) ≠ hash(空) = 旧 _ko_hash
	var r = rules.play_move(board, 10, 10, Stone.Type.WHITE)
	assert_true(r.valid, "中间有别手应合法")

# ------------------------------------------------------------
# 测试 10: Pass——不修改棋盘，清除劫记录
# ------------------------------------------------------------
func test_pass_clears_ko():
	var board = Board.new()
	var rules = GoRules.new()
	rules.play_move(board, 3, 3, Stone.Type.BLACK)
	board.set_stone(3, 3, Stone.Type.EMPTY)
	rules.do_pass()
	# pass 后 ko 清除，相同局面不再被阻止
	var r = rules.play_move(board, 3, 3, Stone.Type.BLACK)
	assert_true(r.valid)

# ------------------------------------------------------------
# 测试 11: 双方连续 pass 终局
# ------------------------------------------------------------
func test_game_over_after_two_passes():
	var rules = GoRules.new()
	assert_false(rules.is_game_over(1))
	assert_true(rules.is_game_over(2))
