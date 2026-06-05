# StoneGroup 棋组类 实现计划

> **目标：** 创建 StoneGroup.build_group() 静态方法 — BFS 收集同色棋子和气

> **架构：** 纯算法类（RefCounted），静态方法，输入 Board + 种子坐标，输出 Dictionary

> **技术栈：** Godot 4.6 / GDScript / GUT

---

### 任务 1: StoneGroup BFS 棋组查找

**文件:**
- 创建: `src/core/group.gd`
- 创建: `test/unit/test_group.gd`

---

- [ ] **步骤 1: 创建 BDD 行为注释测试文件（空函数体）**

```gdscript
# test/unit/test_group.gd
extends GutTest

# ============================================================
# 任务 1.3 — StoneGroup 棋组类 行为规格
# ============================================================
#
# StoneGroup 用 BFS 算法从一颗棋子出发，找到所有和它同色相连的棋子
# 以及这些棋子共有的气（空位）。这是提子规则和计分的基础。
# ============================================================

# ------------------------------------------------------------
# 测试 1: 单子四气——孤立棋子有四个方向的空位
# ------------------------------------------------------------
func test_single_stone_has_four_liberties():
    pass

# ------------------------------------------------------------
# 测试 2: 相连棋组共享气——两个同色相连棋子共 6 口气
# ------------------------------------------------------------
func test_connected_stones_share_liberties():
    pass

# ------------------------------------------------------------
# 测试 3: 被围无气——棋子被对方完全包围
# ------------------------------------------------------------
func test_surrounded_stone_has_no_liberties():
    pass

# ------------------------------------------------------------
# 测试 4: 异色不连通——BFS 不跨越对方棋子
# ------------------------------------------------------------
func test_bfs_does_not_cross_opponent():
    pass
```

✅ **此步后 → AskUserQuestion 确认，批准后继续。**

---

- [ ] **步骤 2: 填充测试断言（红阶段）**

```gdscript
func test_single_stone_has_four_liberties():
    var board = Board.new()
    board.set_stone(3, 3, Stone.Type.BLACK)
    var result = StoneGroup.build_group(board, Vector2i(3, 3))
    assert_eq(result["stones"].size(), 1)
    assert_eq(result["liberties"].size(), 4)

func test_connected_stones_share_liberties():
    var board = Board.new()
    board.set_stone(3, 3, Stone.Type.BLACK)
    board.set_stone(3, 4, Stone.Type.BLACK)
    var result = StoneGroup.build_group(board, Vector2i(3, 3))
    assert_eq(result["stones"].size(), 2)
    assert_eq(result["liberties"].size(), 6)

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

func test_bfs_does_not_cross_opponent():
    var board = Board.new()
    board.set_stone(3, 3, Stone.Type.BLACK)
    board.set_stone(3, 4, Stone.Type.WHITE)  # 右边是白子
    var result = StoneGroup.build_group(board, Vector2i(3, 3))
    assert_eq(result["stones"].size(), 1, "只包含种子自身")
```

---

- [ ] **步骤 3: 运行测试确认失败（验证红）**

```bash
D:\godot\Godot_v4.6.2-stable_win64.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gtest=test_group
```
预期: Parse Error — StoneGroup 类不存在

---

- [ ] **步骤 4: 写最小实现（绿阶段）**

```gdscript
# src/core/group.gd
class_name StoneGroup
extends RefCounted

static func build_group(board: Board, seed: Vector2i) -> Dictionary:
    var color := board.get_stone(seed.x, seed.y)
    if color == Stone.Type.EMPTY:
        return { "stones": [], "liberties": [] }
    
    var visited: Array[Array] = []
    for row in Board.SIZE:
        visited.append([])
        for _col in Board.SIZE:
            visited[row].append(false)
    
    var queue: Array[Vector2i] = [seed]
    visited[seed.x][seed.y] = true
    
    var stones: Array[Vector2i] = []
    var liberties: Dictionary = {}  # 用 Dictionary 做 Set 去重
    
    while not queue.is_empty():
        var cur := queue.pop_front()
        stones.append(cur)
        
        for nb in board.get_neighbors(cur.x, cur.y):
            var nb_color := board.get_stone(nb.x, nb.y)
            if nb_color == color and not visited[nb.x][nb.y]:
                visited[nb.x][nb.y] = true
                queue.append(nb)
            elif nb_color == Stone.Type.EMPTY:
                var key := "%d,%d" % [nb.x, nb.y]
                if not liberties.has(key):
                    liberties[key] = nb
    
    var liberties_arr: Array[Vector2i] = []
    for key in liberties:
        liberties_arr.append(liberties[key])
    
    return { "stones": stones, "liberties": liberties_arr }
```

---

- [ ] **步骤 5: 运行测试确认通过（验证绿）**

```bash
D:\godot\Godot_v4.6.2-stable_win64.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit
```
预期: ✅ 13 passing (4 group + 5 board + 3 stone + 1 smoke)

---

- [ ] **步骤 6: 重构检查**

- visited 的二维布尔数组有优化空间（可用 Dictionary 代替）
- 保持简洁，V1.0 不需要优化

---

- [ ] **步骤 7: 提交**

```bash
git add src/core/group.gd test/unit/test_group.gd docs/plans/2025-01-21-stonegroup.md
git commit -m "feat(core): 添加 StoneGroup BFS 棋组查找 (#1.3)"
```
