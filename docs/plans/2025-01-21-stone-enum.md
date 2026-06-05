# Stone 枚举 实现计划

> **目标：** 创建 Stone.Type 枚举 + opponent() 静态方法，围棋核心数据结构第一步

> **架构：** 纯数据类 `Stone`（`RefCounted`），内嵌三值枚举，零 Godot 节点依赖

> **技术栈：** Godot 4.6 / GDScript / GUT 测试框架

---

### 任务 1: Stone 枚举 — BDD 规格确认 → TDD 红绿循环

**文件:**
- 创建: `src/core/stone.gd`
- 创建: `test/unit/test_stone.gd`

---

- [ ] **步骤 1: 创建 BDD 行为注释测试文件（空函数体）**

> ⚠️ 按 TDD/BDD 规则，必须先创建 Gherkin 注释 + 空测试函数，用 AskUserQuestion 确认后才继续。

```gdscript
# test/unit/test_stone.gd
extends GutTest

# ============================================================
# 任务 1.1 — Stone 枚举 行为规格
# ============================================================

# ------------------------------------------------------------
# 测试: test_opponent_black_returns_white
#
# Given Stone.Type.BLACK
# When  调用 Stone.opponent(Type.BLACK)
# Then  返回 Stone.Type.WHITE
# ------------------------------------------------------------
func test_opponent_black_returns_white():
    pass

# ------------------------------------------------------------
# 测试: test_opponent_white_returns_black
#
# Given Stone.Type.WHITE
# When  调用 Stone.opponent(Type.WHITE)
# Then  返回 Stone.Type.BLACK
# ------------------------------------------------------------
func test_opponent_white_returns_black():
    pass

# ------------------------------------------------------------
# 测试: test_opponent_empty_returns_empty
#
# Given Stone.Type.EMPTY
# When  调用 Stone.opponent(Type.EMPTY)
# Then  返回 Stone.Type.EMPTY
# ------------------------------------------------------------
func test_opponent_empty_returns_empty():
    pass
```

✅ **此步后 → 用 AskUserQuestion 确认，批准后继续。**

---

- [ ] **步骤 2: 填充测试代码（红阶段 — Write Failing Tests）**

> 用户批准 BDD 规格后，填充测试断言。

```gdscript
# test/unit/test_stone.gd
extends GutTest

# Given Stone.Type.BLACK
# When  调用 Stone.opponent(Type.BLACK)
# Then  返回 Stone.Type.WHITE
func test_opponent_black_returns_white():
    assert_eq(Stone.opponent(Stone.Type.BLACK), Stone.Type.WHITE)

# Given Stone.Type.WHITE
# When  调用 Stone.opponent(Type.WHITE)
# Then  返回 Stone.Type.BLACK
func test_opponent_white_returns_black():
    assert_eq(Stone.opponent(Stone.Type.WHITE), Stone.Type.BLACK)

# Given Stone.Type.EMPTY
# When  调用 Stone.opponent(Type.EMPTY)
# Then  返回 Stone.Type.EMPTY
func test_opponent_empty_returns_empty():
    assert_eq(Stone.opponent(Stone.Type.EMPTY), Stone.Type.EMPTY)
```

---

- [ ] **步骤 3: 运行测试 — 确认全部失败（红）**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gtest=test_stone
```

预期: ❌ 3 failing — `Stone` 类不存在，脚本加载错误

---

- [ ] **步骤 4: 写最小实现（绿阶段）**

```gdscript
# src/core/stone.gd
class_name Stone
extends RefCounted

enum Type {
    EMPTY = 0,
    BLACK = 1,
    WHITE = 2,
}

## 返回对手颜色，EMPTY 返回 EMPTY
static func opponent(s: Type) -> Type:
    match s:
        Type.BLACK:
            return Type.WHITE
        Type.WHITE:
            return Type.BLACK
        _:
            return Type.EMPTY
```

---

- [ ] **步骤 5: 运行测试 — 确认全部通过（绿）**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gtest=test_stone
```

预期: ✅ 3 passing, 0 failing

---

- [ ] **步骤 6: 运行全量回归测试**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit
```

预期: ✅ 所有测试通过（含 test_smoke + 3 个 Stone 测试）

---

- [ ] **步骤 7: 提交**

```bash
git add src/core/stone.gd test/unit/test_stone.gd docs/plans/2025-01-21-stone-enum.md
git commit -m "feat(core): 添加 Stone 枚举和 opponent() 方法 (#1.1)"
```
