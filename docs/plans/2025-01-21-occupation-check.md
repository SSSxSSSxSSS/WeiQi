# 占位检测 + GoRules 框架 实现计划

> **目标：** 创建 MoveResult 数据类 + GoRules 规则引擎骨架，实现占位检测

> **架构：** MoveResult 为纯数据 RefCounted，GoRules 持有 _ko_hash，play_move 为落子入口

> **技术栈：** Godot 4.6 / GDScript / GUT

---

### 任务 1: MoveResult + GoRules 占位检测

**文件:**
- 创建: `src/core/move_result.gd`
- 创建: `src/core/rules.gd`
- 创建: `test/unit/test_rules.gd`

---

- [ ] **步骤 1: 创建 BDD 行为注释测试文件**

```gdscript
# test/unit/test_rules.gd
extends GutTest

# ------------------------------------------------------------
# 测试 1: 空位落子合法——在空交叉点落子应该成功
# ------------------------------------------------------------
func test_play_on_empty_intersection_is_valid():
    pass

# ------------------------------------------------------------
# 测试 2: 占位检测——已有棋子的位置不能再落子
# ------------------------------------------------------------
func test_play_on_occupied_intersection_is_invalid():
    pass

# ------------------------------------------------------------
# 测试 3: 边界外落子——棋盘外的坐标直接拒绝
# ------------------------------------------------------------
func test_play_out_of_bounds_is_invalid():
    pass
```

✅ **AskUserQuestion 确认后继续。**

---

- [ ] **步骤 2: 填充测试断言（红阶段）**

```gdscript
func test_play_on_empty_intersection_is_valid():
    var board = Board.new()
    var rules = GoRules.new()
    var result = rules.play_move(board, 3, 3, Stone.Type.BLACK)
    assert_true(result.valid)
    assert_eq(result.captured.size(), 0)

func test_play_on_occupied_intersection_is_invalid():
    var board = Board.new()
    board.set_stone(3, 3, Stone.Type.BLACK)
    var rules = GoRules.new()
    var result = rules.play_move(board, 3, 3, Stone.Type.WHITE)
    assert_false(result.valid)
    assert_eq(result.reason, "occupied")

func test_play_out_of_bounds_is_invalid():
    var board = Board.new()
    var rules = GoRules.new()
    var result = rules.play_move(board, -1, 0, Stone.Type.BLACK)
    assert_false(result.valid)
```

---

- [ ] **步骤 3: 运行确认失败**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gtest=test_rules
```
预期: Parse Error — MoveResult / GoRules 不存在

---

- [ ] **步骤 4: 写最小实现**

```gdscript
# src/core/move_result.gd
class_name MoveResult
extends RefCounted

var valid: bool = false
var captured: Array[Vector2i] = []
var reason: String = ""

func _init(p_valid: bool = false, p_captured: Array[Vector2i] = [], p_reason: String = "") -> void:
    valid = p_valid
    captured = p_captured
    reason = p_reason
```

```gdscript
# src/core/rules.gd
class_name GoRules
extends RefCounted

var _ko_hash: int = -1

func play_move(board: Board, row: int, col: int, color: Stone.Type) -> MoveResult:
    if not board.is_on_board(row, col):
        return MoveResult.new(false, [], "out_of_bounds")
    if board.get_stone(row, col) != Stone.Type.EMPTY:
        return MoveResult.new(false, [], "occupied")
    board.set_stone(row, col, color)
    return MoveResult.new(true, [], "")
```

---

- [ ] **步骤 5: 运行确认通过**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit
```
预期: ✅ 16 passing (3 rules + 4 group + 5 board + 3 stone + 1 smoke)

---

- [ ] **步骤 6: 提交**

```bash
git add src/core/move_result.gd src/core/rules.gd test/unit/test_rules.gd docs/plans/2025-01-21-occupation-check.md
git commit -m "feat(core): 添加 GoRules 占位检测 + MoveResult (#2.1)"
```
