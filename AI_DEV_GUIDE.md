# 围棋游戏 — AI 开发指导手册

> **给 AI 开发者的话**：这份文档是你唯一的开发依据。按阶段顺序执行，每个任务必须通过 GUT 测试才能标记完成。不要跳步，不要自由发挥超出规格的功能。

---

## §0 快速启动（首次开发必读）

> 拿到这份文档后，不要从头读到尾。按以下 4 步走：

1. **装 GUT** → 任务 0.1（Godot Asset Library 搜「GUT」安装）
2. **跑冒烟测试** → 任务 0.4（确认 `test_smoke.gd` 通过，环境就绪）
3. **创建目录** → 任务 0.2（建好 `src/core/`, `src/ai/`, `src/ui/`, `src/game/`, `src/scenes/`, `test/unit/`）
4. **从阶段 1.1 开始** → 严格按拓扑图顺序，不要跳步，不要并行开发有依赖的阶段

**最重要的规则**：当前阶段全部 GUT 测试绿了，才能进入下一阶段。

---

## §1 项目约定

| 项目 | 值 |
| --- | --- |
| 引擎 | Godot 4.6 |
| 语言 | GDScript |
| 对战类型 | **人机对战**（玩家 vs AI） |
| AI 架构 | **策略模式**：`AiBase` 抽象基类定义 `get_move(board, color) → Vector2i` 接口，GameController 依赖接口而非具体 AI。V1.0 实现 `AiRandom` + `AiHeuristic`，V1.1 切换为 `AiMcts` 时 GameController 不改一行代码 |
| 测试框架 | GUT (Godot Unit Test)，测试目录 `test/unit/` |
| 开发流程 | **TDD/BDD**：先写 Given-When-Then 行为注释 + 空测试函数 → 用户确认 → 红 → 绿 → 重构 |
| 坐标系统 | `(row, col)`，`(0,0)` = 左上角星位。row 向下增长（0-18），col 向右增长（0-18） |
| 棋盘常量 | `BOARD_SIZE = 19`，坐标范围 `[0, BOARD_SIZE-1]` |
| 棋子值 | `EMPTY = 0`，`BLACK = 1`，`WHITE = 2` |
| 命名规范 | 文件名 `snake_case.gd`，类名 `PascalCase`，函数/变量 `snake_case` |
| 核心层原则 | `src/core/` 下所有文件 **不 `extends` 任何 Godot 节点**，纯 GDScript 数据+算法 |
| 中文交流 | 所有注释、测试描述、Given-When-Then 使用中文 |

---

## §2 依赖拓扑图（执行顺序不可乱）

```
阶段 0: 环境搭建
  ↓
阶段 1: 核心数据结构
  1.1 Stone 枚举
   ↓
  1.2 Board 类 ──────────────┐
   ↓                          ↓
  1.3 StoneGroup 类        2.1 占位检测
  ↓                          ↓
阶段 2: 规则引擎            2.2 提子逻辑
  2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6 → 2.7
  ↓
阶段 3: AI 模块（依赖 Board + RulesEngine）
  3.1 AiBase 抽象接口
   ↓
  3.2 AiRandom（简单难度）
   ↓
  3.3 AiHeuristic（普通/困难难度）
  ↓
阶段 4: 计分系统（可并行于阶段 3，依赖 1.2+1.3）
  4.1 → 4.2 → 4.3
  ↓
阶段 5: 棋盘渲染（可并行于阶段 3-4，依赖 1.2）
  5.1 → 5.2 → 5.3 → 5.4 → 5.5
  ↓
阶段 6: 人机对战流程
  6.1 颜色选择 → 6.2 难度选择 → 6.3 状态机 → 6.4 UI连线 → 6.5 HUD
  ↓
阶段 7: 扩展功能
  7.1 棋盘尺寸切换 → 7.2 悔棋 → 7.3 SGF → 7.4 MCTS 升级
```

### ⛔ 阶段间硬性关卡

**当前阶段所有 GUT 测试绿了（0 failing），才能进入下一阶段。** 不允许任何跳步或"后面再补测试"。违反此规则会导致后期调试成本爆炸——围棋规则环环相扣（气→提子→自杀→劫），前段一个 bug 会让后续阶段全部白做。

---

## §3 阶段 0：环境搭建

### 任务 0.1 — 安装 GUT 测试框架

- 从 Godot Asset Library 搜索「GUT」安装
- 或者在项目根目录执行：`git clone https://github.com/bitwes/Gut.git addons/gut`
- 在 `project.godot` 中注册 GUT 插件

### 任务 0.2 — 创建目录结构

```
src/core/          # 纯逻辑层
src/game/          # 对局控制
src/ui/            # 渲染与交互
src/scenes/        # .tscn 场景文件
test/unit/         # GUT 单元测试
assets/textures/   # 贴图资源
```

### 任务 0.3 — 项目设置调整

在 Godot 编辑器中设置：
- **窗口大小**：`1024 × 768`
- **拉伸模式**：`canvas_items`
- **背景色**：深木色 `#8B6914` 或类似

### 任务 0.4 — 环境验证测试

- 文件：`test/unit/test_smoke.gd`

```gherkin
# Given GUT 框架已安装
# When 运行测试套件
# Then 至少有一个测试通过（本测试）
```

```gdscript
# test/unit/test_smoke.gd
extends GutTest

func test_environment_ready():
    assert_true(true, "GUT 环境就绪")
```

- **验收**：Godot 编辑器中运行 GUT → `1 passing`

---

## §4 阶段 1：核心数据结构

### 任务 1.1 — Stone 枚举

- 文件：`src/core/stone.gd`
- 内容：

```gdscript
# src/core/stone.gd
class_name Stone

enum Type {
    EMPTY = 0,
    BLACK = 1,
    WHITE = 2,
}

## 返回对手颜色，EMPTY 返回 EMPTY
static func opponent(s: Type) -> Type:
    match s:
        Type.BLACK: return Type.WHITE
        Type.WHITE: return Type.BLACK
        _: return Type.EMPTY
```

- 测试文件：`test/unit/test_stone.gd`

```gherkin
# Given Stone.Type.BLACK
# When 调用 Stone.opponent(BLACK)
# Then 返回 Stone.Type.WHITE

# Given Stone.Type.WHITE
# When 调用 Stone.opponent(WHITE)
# Then 返回 Stone.Type.BLACK

# Given Stone.Type.EMPTY
# When 调用 Stone.opponent(EMPTY)
# Then 返回 Stone.Type.EMPTY
```

- **依赖**：无
- **验收**：3 个测试全部通过

---

### 任务 1.2 — Board 类

- 文件：`src/core/board.gd`
- 核心签名：

```gdscript
class_name Board
extends RefCounted

const SIZE := 19

var _grid: Array[Array]  # _grid[row][col] → Stone.Type

func _init() -> void
func get_stone(row: int, col: int) -> Stone.Type
func set_stone(row: int, col: int, stone: Stone.Type) -> void
func is_on_board(row: int, col: int) -> bool
func clear() -> void
func clone() -> Board                                 # ⚠️ 深拷贝：_grid 每行 .duplicate(true)，浅拷贝会污染原棋盘
func get_neighbors(row: int, col: int) -> Array[Vector2i]  # 返回4个相邻有效坐标
```

> ⚠️ **深拷贝警告**：`clone()` 是劫检测（任务 2.4）和 AI 模拟（阶段 3）的基础。GDScript 的 `Array.duplicate()` 默认只浅拷贝一层——`_grid.duplicate()` 会复制 19 行的引用，修改副本的行仍会污染原棋盘。**必须**用 `_grid.duplicate(true)` 对每行也做深拷贝。此 bug 极难排查——劫检测静默失效、AI 操作后棋盘错乱。

- 测试文件：`test/unit/test_board.gd`

```gherkin
# 初始化
# Given 创建一个 19×19 Board
# When 检查所有交叉点
# Then 所有位置均为 Stone.Type.EMPTY

# 放置与读取
# Given 空棋盘
# When 在 (3,3) 放置 BLACK
# Then get_stone(3,3) 返回 BLACK，其余位置仍为 EMPTY

# 越界检测
# Given 19×19 Board
# When 检查 (-1, 0) / (19, 0) / (0, -1) / (0, 19)
# Then is_on_board 全部返回 false

# 获取相邻坐标
# Given 坐标 (0, 0) — 角落
# When 调用 get_neighbors(0, 0)
# Then 返回 [(1,0), (0,1)] — 仅 2 个有效邻居

# 深拷贝
# Given Board A 在 (5,5) 有 BLACK
# When 调用 A.clone() → Board B
# Then B.get_stone(5,5) == BLACK，且修改 B 不影响 A
```

- **依赖**：1.1
- **验收**：5 组测试全部通过

---

### 任务 1.3 — StoneGroup 类（棋组 + 气）

- 文件：`src/core/group.gd`

```gdscript
class_name StoneGroup
extends RefCounted

## 从种子坐标 BFS，收集同色相连棋子和它们的气
## 返回 Dictionary { "stones": Array[Vector2i], "liberties": Array[Vector2i] }
static func build_group(board: Board, seed: Vector2i) -> Dictionary
```

**BFS 算法伪代码**（§A 有详细版）：

```
初始化 visited[seed] = true, queue = [seed], stones = [], liberties = {}
while queue 非空:
    cur = queue.pop()
    stones.append(cur)
    for each neighbor of cur on board:
        if neighbor 同色 and 未访问:
            标记访问, 入队
        elif neighbor 是 EMPTY:
            liberties.add(neighbor)  # 用 Set 去重
return { stones, liberties }
```

- 测试文件：`test/unit/test_group.gd`

```gherkin
# 单子四气
# Given 棋盘只有 (3,3) 一枚黑子
# When 对 (3,3) 调用 build_group
# Then stones 包含 [(3,3)]，liberties 包含 [(2,3),(4,3),(3,2),(3,4)]（4个方向）

# 相连棋组共享气
# Given (3,3) 和 (3,4) 各有一枚黑子相连
# When 对 (3,3) 调用 build_group
# Then stones 包含 2 个坐标，liberties 包含 6 个坐标（不是8个，因为两子共享边已占用）

# 被围无气
# Given 一枚黑子四边都被白子包围
# When 对黑子调用 build_group
# Then liberties 为空数组

# 异色不连通
# Given (3,3) 黑子，(3,4) 白子
# When 对 (3,3) 调用 build_group
# Then stones 只包含 [(3,3)]，不包含白子
```

- **依赖**：1.2
- **验收**：4 组测试全部通过

---

## §5 阶段 2：规则引擎

- 文件：`src/core/rules.gd`

```gdscript
class_name GoRules
extends RefCounted

var _ko_hash: int = -1  # 上一手局面的哈希值，-1 表示无劫

## 完整落子流程，返回落子结果
func play_move(board: Board, row: int, col: int, color: Stone.Type) -> MoveResult
func pass() -> void
func is_game_over(consecutive_passes: int) -> bool
func clear_ko() -> void
```

`MoveResult` 是一个 `RefCounted` 数据类：

```gdscript
class MoveResult extends RefCounted:
    var valid: bool           # 落子是否合法
    var captured: Array[Vector2i]  # 被提的棋子坐标
    var reason: String        # 不合法原因（"occupied"/"suicide"/"ko"）
```

---

### 任务 2.1 — 占位检测

```gherkin
# Given 棋盘 (3,3) 已有黑子
# When 黑方尝试在 (3,3) 落子
# Then 返回 valid=false, reason="occupied"
```

---

### 任务 2.2 — 提子逻辑

```gherkin
# Given 白子 (2,3) 仅剩一口气在 (1,3)
# When 黑方在 (1,3) 落子
# Then 白子 (2,3) 被移除，captured 包含 [(2,3)]

# Given 黑方落子同时提掉多个白子组
# When 黑方落子导致两组各一枚白子无气
# Then captured 包含两枚白子坐标
```

**提子算法**：

```
对落子位置的 4 个邻居：
    if 邻居是对方棋子:
        group = StoneGroup.build_group(board, neighbor)
        if group.liberties 为空:
            从棋盘移除 group.stones 中的所有棋子
            将 group.stones 加入 captured 列表
```

---

### 任务 2.3 — 自杀检测

```gherkin
# Given 黑子落在一个被白子四面包围的空位
# When 黑方落子且该落子不能提掉任何白子
# Then 返回 valid=false, reason="suicide"

# Given 黑子落入看似自杀但可以提掉一枚白子
# When 落子后提掉白子让自己有了气
# Then 返回 valid=true（这不是自杀）
```

**自杀判断**：落子后，先执行提对方子，再检查己方棋组是否有气。有气则合法。

---

### 任务 2.4 — 劫检测（Ko）

```gherkin
# Given 棋盘处于劫争局面（黑提一白子后，白可立即提回恢复原状）
# When 白方尝试立即提回
# Then 返回 valid=false, reason="ko"

# Given 棋盘处于劫争，但黑方在别处落了一手
# When 白方再回来提劫
# Then 返回 valid=true（中间有别手，劫已解）
```

**劫检测算法**：

```
落子前：计算当前棋盘哈希（只算棋子，不计空位顺序）
落子后：执行放置+提子
计算落子后哈希
if 后哈希 == _ko_hash:
    还原棋盘，返回 KO 非法
else:
    _ko_hash = 前哈希（落子前局面的哈希）
```

**棋盘哈希函数**（用于劫检测）：

```gdscript
## 简单多项式哈希，遍历所有棋子位置
func _hash_board(board: Board) -> int:
    var h := 0
    for row in Board.SIZE:
        for col in Board.SIZE:
            var s = board.get_stone(row, col)
            h = (h * 31 + int(s)) & 0x7FFFFFFF
    return h
```

---

### 任务 2.5 — 完整落子流程

```
play_move(board, row, col, color):
    1. 检查 row/col 是否合法
    2. 检查位置是否为空（若已占用 → 返回 occupied）
    3. 保存当前棋盘哈希 pre_hash
    4. 在棋盘上放置棋子
    5. 执行提子（检查4个邻居）
    6. 检查己方棋组是否有气（无气且未提子 → 自杀 → 还原棋盘）
    7. 计算落子后哈希 post_hash
    8. 若 post_hash == _ko_hash → 还原棋盘 → 返回 ko
    9. _ko_hash = pre_hash
    10. 返回 valid=true + captured
```

---

### 任务 2.6 — Pass 逻辑

```gherkin
# Given 当前方为 BLACK
# When 调用 pass()
# Then 不修改棋盘，只是轮到 WHITE 方
```

```gdscript
func pass() -> void:
    _ko_hash = -1  # Pass 清除劫记录
```

---

### 任务 2.7 — 终局判定

```gherkin
# Given 双方各 pass 一次（consecutive_passes == 2）
# When 调用 is_game_over(2)
# Then 返回 true

# Given 黑方 pass，白方落子
# When 调用 is_game_over(1)
# Then 返回 false
```

- **依赖**：2.1, 2.2, 2.3, 2.4
- **验收**：7 组测试全部通过

---

## §6 阶段 3：AI 模块

> **设计原则**：GameController 只依赖 `AiBase` 抽象接口，不依赖具体 AI 实现。V1.0 提供 `AiRandom`（简单）和 `AiHeuristic`（普通/困难），V1.1 新增 `AiMcts` 时只需添加新类，GameController 无需修改。

- 目录：`src/ai/`
- 文件结构：

```
src/ai/
├── ai_base.gd         # 抽象基类（接口定义）
├── ai_random.gd       # 随机 AI（简单难度）
├── ai_heuristic.gd    # 启发式 AI（普通/困难难度）
└── ai_mcts.gd         # MCTS AI（V1.1 预留，暂时只建空壳）
```

---

### 任务 3.1 — AiBase 抽象接口

- 文件：`src/ai/ai_base.gd`

```gdscript
# src/ai/ai_base.gd
class_name AiBase
extends RefCounted

## 子类必须重写：根据当前棋盘返回 AI 选择的落子坐标
## 返回 Vector2i(row, col)，如果 AI 选择 pass 则返回 Vector2i(-1, -1)
func get_move(board: Board, color: Stone.Type) -> Vector2i:
    push_error("AiBase.get_move() 必须被子类重写")
    return Vector2i(-1, -1)

## 可选重写：AI 的名称（用于 HUD 显示）
func get_name() -> String:
    return "AI 基类"

## 可选重写：AI 的难度等级描述
func get_level() -> String:
    return "未定义"
```

- 测试文件：`test/unit/test_ai_base.gd`

```gherkin
# Given AiBase 实例
# When 调用 get_move(board, BLACK)
# Then 触发 push_error（基类不应被直接调用）

# Given 子类 AiRandom 已实现 get_move
# When 通过 AiBase 类型变量调用 get_move
# Then 正确调用子类方法（多态验证）
```

- **依赖**：1.2, 2.5（需要 Board 和合法的 play_move）
- **验收**：2 组测试通过

---

### 任务 3.2 — AiRandom（简单难度）

- 文件：`src/ai/ai_random.gd`

```gdscript
# src/ai/ai_random.gd
class_name AiRandom
extends AiBase

## 从所有合法落子中随机选一个
func get_move(board: Board, color: Stone.Type) -> Vector2i:
    # 1. 收集所有合法落子位置
    # 2. 若无合法落子 → 返回 (-1, -1) 表示 pass
    # 3. 随机选一个返回
    pass

func get_name() -> String:
    return "随机 AI"

func get_level() -> String:
    return "简单"
```

**算法**：

```
对每个候选位置：
    副本 = board.clone()  # ⚠️ 必须在副本上测试，play_move 会修改棋盘！
    用临时 GoRules 在副本上测试 play_move
    合法 → 加入候选列表
若候选列表为空 → 返回 (-1, -1) 表示 pass
随机选一个候选返回
```

- 测试文件：`test/unit/test_ai_random.gd`

```gherkin
# 空棋盘
# Given 空棋盘，BLACK 方
# When 调用 AiRandom.get_move
# Then 返回的坐标在 [0,18] 范围内且该位置合法

# 只剩一口气
# Given 棋盘只有一个空位 (0,0)，其余全满
# When 调用 AiRandom.get_move
# Then 返回 (0,0) 或 (-1, -1) pass

# 全部不可落子
# Given 所有位置都不合法（无法构造，用 Mock Board 模拟）
# When 调用 AiRandom.get_move
# Then 返回 (-1, -1) 表示 pass
```

- **依赖**：3.1, 2.5
- **验收**：3 组测试通过

---

### 任务 3.3 — AiHeuristic（普通/困难难度）

- 文件：`src/ai/ai_heuristic.gd`

```gdscript
# src/ai/ai_heuristic.gd
class_name AiHeuristic
extends AiBase

enum Level { NORMAL, HARD }

var _level: Level
var _rules: GoRules  # 用于测试落子合法性

func _init(level: Level = Level.NORMAL) -> void:
    _level = level
    _rules = GoRules.new()

func get_move(board: Board, color: Stone.Type) -> Vector2i:
    # 对所有合法落子打分，选最高分
    pass

func get_name() -> String:
    return "启发式 AI"

func get_level() -> String:
    return "普通" if _level == Level.NORMAL else "困难"
```

**打分策略（普通难度）**：

```
候选 = 所有合法落子
对每个候选坐标计算分数：
    +10  如果落在角位置 (0,0)/(0,18)/(18,0)/(18,18)
    +5   如果落在星位
    +3   如果落在边上（row==0 或 row==18 或 col==0 或 col==18）
    +8   如果落子后能提掉对方棋子（captured 数量 × 8）
    -20  如果落子后己方棋组只剩 1 气（危险）
    +2   随机扰动（避免每次走法都一样）
选最高分 → 落子
```

**困难难度加成**：

```
额外打分：
    +15  如果落子后对方某棋组只剩 1 气（逼对方应）
    -30  如果落子于对方星位附近且对方已有子（避免冒进）
    -10  如果落子位置距离棋盘中心太远且非边角（NORMAL 不评估此项）
```

- 测试文件：`test/unit/test_ai_heuristic.gd`

```gherkin
# 空棋盘优先占角
# Given 空棋盘，BLACK 方，普通难度
# When 调用 AiHeuristic.get_move
# Then 返回四个角之一：(0,0) / (0,18) / (18,0) / (18,18)

# 能提子优先提子
# Given 棋盘上有一枚白子只剩一口气
# When 黑方 AI 调用 get_move
# Then 返回那口气的坐标（提子得分 > 占角得分）

# 避免自杀
# Given 某个"合法但危险"的位置（落子后己方仅剩 1 气）
# When 有更安全的位置可选
# Then AI 不选那个危险位置

# 困难 vs 普通差异
# Given 同一局面
# When 分别用 NORMAL 和 HARD 调用 get_move
# Then 两种难度可能返回不同结果（HARD 评估更保守）
```

- **依赖**：3.1, 3.2, 2.5
- **验收**：4 组测试通过

---

### 任务 3.4 — AI 模块集成测试（可选，阶段 6 之前完成即可）

- 文件：`test/unit/test_ai.gd`

```gherkin
# Given AiRandom 和 AiHeuristic 都实现了 AiBase 接口
# When 通过 AiBase 类型变量调用 get_move
# Then 两者都能正常工作（多态性验证）

# Given 三种难度（简单=AiRandom, 普通/困难=AiHeuristic）
# When 每种难度在空棋盘上调用 100 次 get_move
# Then 每次返回都在合法范围内
```

- **依赖**：3.2, 3.3
- **验收**：2 组测试通过

---

## §7 阶段 4：计分系统

- 文件：`src/core/scoring.gd`

```gdscript
class_name GoScoring
extends RefCounted

## 中国规则计分
## 返回 Dictionary { "black_score": float, "white_score": float, "winner": Stone.Type }
static func score(board: Board, komi: float = 7.5) -> Dictionary
```

### 任务 4.1 — 空域查找（BFS 找所有连通空位区域）

```gherkin
# Given 棋盘全空
# When 查找所有空域
# Then 返回 1 个空域，包含全部 361 个交叉点

# Given 棋盘中间有一条黑子线分割
# When 查找空域
# Then 返回 2 个独立的空域
```

**算法**：

```
遍历所有 (row, col)：
    if 该位置为 EMPTY 且未被访问过:
        BFS 收集连通空位 → 一个空域
        同时记录该空域的边界颜色（相邻的黑/白棋子）
```

### 任务 4.2 — 空域归属判定

```gherkin
# Given 一个空域四周只与黑子相邻
# When 判定归属
# Then 该空域归黑方

# Given 一个空域四周同时与黑子和白子相邻
# When 判定归属
# Then 该空域为中立（不计入任何一方）
```

### 任务 4.3 — 中国规则计分

```
score(board, komi=7.5):
    black_area = 棋盘上黑子数量
    white_area = 棋盘上白子数量
    对每个空域：
        if 空域只与黑相邻：black_area += 空域大小
        elif 空域只与白相邻：white_area += 空域大小
    white_area += komi
    return { black_score, white_score, winner }
```

- **测试文件**：`test/unit/test_scoring.gd`

```gherkin
# 空棋盘
# Given 空棋盘
# When 计分
# Then 黑 0 + 空域361归双方=争议，白得 7.5 贴目 → 白胜

# 简单终局
# Given 黑子占左上角9子方块，其余全空
# When 计分
# Then 正确计算黑空+子，白空+子+贴目
```

- **依赖**：1.2, 1.3
- **验收**：3 组测试通过

---

## §8 阶段 5：棋盘渲染

### 任务 5.1 — 棋盘网格绘制

- 文件：`src/ui/board_renderer.gd`
- 继承：`Node2D`
- 使用 `_draw()` 绘制：
  - 木色背景矩形
  - 19×18 条横线 + 19×18 条竖线（间隔一致，如 36px）
  - 线条颜色：黑色 `#1a1a1a`，宽度 1.5px

```gdscript
class_name BoardRenderer
extends Node2D

const CELL_SIZE := 36          # 每格像素
const BOARD_PADDING := 40      # 棋盘边距
const BOARD_SIZE_PX := CELL_SIZE * (Board.SIZE - 1)  # 648px

func _draw() -> void:
    # 画背景
    # 画网格线
    # 画星位
    # 画棋子（遍历 Board 调用 draw_stone）
```

### 任务 5.2 — 棋子渲染

- 在 `_draw()` 中画圆：
  - 黑子：深色填充 `#1a1a1a` + 浅色高光（模拟光泽）
  - 白子：浅色填充 `#f0f0e0` + 边框 `#999`

```gdscript
func draw_stone(row: int, col: int, color: Stone.Type) -> void:
    var pos := grid_to_pixel(row, col)
    match color:
        Stone.Type.BLACK:
            draw_circle(pos, STONE_RADIUS, Color.BLACK)
            # 高光小圆
        Stone.Type.WHITE:
            draw_circle(pos, STONE_RADIUS, Color.WHITE)
            draw_arc(pos, STONE_RADIUS, 0, TAU, 32, Color.GRAY, 1.0)
```

### 任务 5.3 — 星位标记

- 9 个星位：`(3,3), (3,9), (3,15), (9,3), (9,9), (9,15), (15,3), (15,9), (15,15)`
- 画小实心圆，半径约 4px

### 任务 5.4 — 最后落子标记

- 在最后落子位置画一个小的红色圆形标记（或不同色的高亮）

### 任务 5.5 — 坐标转换

```gdscript
func pixel_to_grid(screen_pos: Vector2) -> Vector2i:
    # 屏幕像素 → (row, col)，超出返回 (-1, -1)

func grid_to_pixel(row: int, col: int) -> Vector2:
    # (row, col) → 棋子中心屏幕坐标
```

- **测试文件**：`test/unit/test_board_renderer.gd`（只测试坐标转换，渲染效果需手动验证）

```gherkin
# Given CELL_SIZE=36, BOARD_PADDING=40
# When 像素 (40, 40) 转换为棋盘坐标
# Then 返回 (0, 0)

# Given 像素 (40+648, 40+648) = (688, 688)
# When 转换
# Then 返回 (18, 18)

# Given 像素 (0, 0) 在棋盘外
# When 转换
# Then 返回 (-1, -1)
```

- **依赖**：1.1, 1.2
- **验收**：坐标转换测试通过 + 手动查看棋盘渲染效果

---

## §9 阶段 6：人机对战流程

### 🔗 流程串联说明（先读这个）

阶段 6 的 5 个任务不是各自独立的——它们有严格的信号传递链。由 `main.gd`（或主场景根节点）负责串联：

```
main.gd 启动
  │
  ├─① 显示 ColorSelect（任务 6.1）
  │     └─ 用户选择 → color_chosen 信号 → 隐藏 ColorSelect
  │
  ├─② 显示 DifficultySelect（任务 6.2）
  │     └─ 用户选择 → difficulty_chosen 信号 → 隐藏 DifficultySelect
  │
  ├─③ 实例化 GameScene（任务 6.4）
  │     └─ game_scene.start_game(player_color, ai_instance)
  │           └─ 内部创建 GameController（任务 6.3）+ HUD（任务 6.5）
  │
  └─④ 对局进行中...
        BoardView 点击 → game_scene._on_board_clicked()
        Pass 按钮 → game_scene._on_pass_pressed()
        HUD 持续调用 update_all() 刷新
```

**必须由同一个管理器（main.gd）持有 ColorSelect → DifficultySelect → GameScene 的引用，逐个切换。** 不要让每个场景自己去找下一个——用信号解耦，管理器负责连线。

> **核心要点**：GameController 通过 `AiBase` 接口调用 AI。玩家落子后自动切换到 AI 回合，AI 计算完成后自动切换回玩家。AI 的身份取决于开局选择（玩家执黑→AI 执白，反之亦然）。

---

### 任务 6.1 — 颜色选择 UI

- 文件：`src/ui/color_select.gd`
- 继承：`Control`
- 开局前弹出二选一界面：
  - 「执黑（先手）」→ 玩家 = BLACK，AI = WHITE
  - 「执白（后手）」→ 玩家 = WHITE，AI = BLACK（AI 先走第一步）

```gdscript
class_name ColorSelect
extends Control

signal color_chosen(player_color: Stone.Type)

func _ready() -> void:
    # 显示两个按钮，点击后发出信号并隐藏
    pass
```

```gherkin
# Given 颜色选择界面已显示
# When 玩家点击「执黑」
# Then 发出 color_chosen(BLACK) 信号

# Given 玩家点击「执白」
# When AI 被设置为 BLACK
# Then AI 自动落第一步
```

---

### 任务 6.2 — 难度选择 UI

- 文件：`src/ui/difficulty_select.gd`

```gdscript
class_name DifficultySelect
extends Control

signal difficulty_chosen(ai_instance: AiBase)

func _ready() -> void:
    # 三个按钮，每个创建对应的 AI 实例：
    #   「简单」→ AiRandom.new()
    #   「普通」→ AiHeuristic.new(AiHeuristic.Level.NORMAL)
    #   「困难」→ AiHeuristic.new(AiHeuristic.Level.HARD)
    pass
```

```gherkin
# Given 难度选择界面
# When 点击「简单」
# Then 发出 difficulty_chosen 信号，参数为 AiRandom 实例
```

---

### 任务 6.3 — GameController 状态机（人机版）

- 文件：`src/game/game_controller.gd`

```gdscript
class_name GameController
extends RefCounted

enum Phase { PLAYING, AI_THINKING, GAME_OVER }

var board: Board
var rules: GoRules
var ai: AiBase                # AI 实例（策略模式注入）
var player_color: Stone.Type  # 玩家执色
var current_color: Stone.Type
var phase: Phase
var consecutive_passes: int
var move_history: Array
var captured_black: int = 0
var captured_white: int = 0

func init(player_stone: Stone.Type, ai_instance: AiBase) -> void:
    player_color = player_stone
    ai = ai_instance
    board = Board.new()
    rules = GoRules.new()
    current_color = Stone.Type.BLACK
    phase = Phase.PLAYING
    # AI 执黑时先走第一步
    if current_color != player_color:
        _ai_turn()

func handle_player_click(row: int, col: int) -> MoveResult:
    if phase != Phase.PLAYING or current_color != player_color:
        return
    var result = _do_move(row, col)
    if result.valid: _after_player_move()
    return result

func handle_player_pass() -> void:
    if phase != Phase.PLAYING or current_color != player_color:
        return
    rules.pass()
    consecutive_passes += 1
    _check_game_over()
    if phase == Phase.PLAYING: _ai_turn()

func _ai_turn() -> void:
    phase = Phase.AI_THINKING
    var move = ai.get_move(board.clone(), current_color)
    if move == Vector2i(-1, -1):
        rules.pass()
        consecutive_passes += 1
    else:
        _do_move(move.x, move.y)
    _after_ai_move()

func _do_move(row: int, col: int) -> MoveResult:
    var result = rules.play_move(board, row, col, current_color)
    if result.valid:
        move_history.append(board.clone())
        if current_color == Stone.Type.BLACK:
            captured_white += result.captured.size()
        else:
            captured_black += result.captured.size()
    return result

func _after_player_move() -> void:
    consecutive_passes = 0
    _check_game_over()
    if phase == Phase.PLAYING:
        _switch_turn()
        _ai_turn()

func _after_ai_move() -> void:
    _check_game_over()
    if phase == Phase.PLAYING:
        _switch_turn()
        # 回到玩家回合

func _switch_turn() -> void:
    current_color = Stone.opponent(current_color)

func _check_game_over() -> void:
    if consecutive_passes >= 2:
        phase = Phase.GAME_OVER

func get_captured_counts() -> Dictionary:
    return { "black": captured_black, "white": captured_white }
```

**状态转换图**：

```
PLAYING ──玩家落子/Pass──→ _after_player_move ──轮到AI──→ AI_THINKING
  ↑                                                            │
  └──── _switch_turn() ←── _after_ai_move ←── AI落子/Pass ────┘

双方连续 Pass → GAME_OVER
```

- **关键行为**：
  1. 玩家落子 → 自动触发 AI 回合（`_ai_turn()`）
  2. AI 计算完成后 → 自动切回玩家
  3. AI 回合中玩家点击无效（`phase == AI_THINKING` 阻断）
  4. 双方连续 Pass → 终局
- **依赖**：3.1, 3.2, 3.3, 2.5, 1.2
- **验收**：状态转换测试通过

---

### 任务 6.4 — 场景连线

- 文件：`src/scenes/game.gd`

```gdscript
class_name GameScene
extends Node2D

@onready var board_view: BoardRenderer = $BoardView
@onready var hud: GameHUD = $GameHUD

var controller: GameController

func start_game(player_color: Stone.Type, ai_instance: AiBase) -> void:
    controller = GameController.new()
    controller.init(player_color, ai_instance)
    board_view.set_board(controller.board)
    hud.init(controller, ai_instance)
    board_view.queue_redraw()
    hud.update_all()

func _on_board_clicked(row: int, col: int) -> void:
    var result = controller.handle_player_click(row, col)
    if result and result.valid:
        board_view.queue_redraw()
    elif result:
        hud.show_message(result.reason)

func _on_pass_pressed() -> void:
    controller.handle_player_pass()
    board_view.queue_redraw()
```

- 场景结构：
  ```
  GameScene (Node2D)
  ├── BoardView (BoardRenderer)   ← _draw 渲染 + 鼠标点击
  └── GameHUD (Control)           ← 信息面板 + Pass 按钮
  ```

---

### 任务 6.5 — HUD 信息面板（人机版）

- 文件：`src/ui/game_hud.gd`

需显示的内容：
  - 当前轮到我方还是 AI（`phase == AI_THINKING` → 「AI 思考中...」）
  - 你执黑/白
  - AI 名称和难度（`ai.get_name()` + `ai.get_level()`）
  - 双方提子数
  - Pass 按钮（玩家回合才可点击）
  - 终局时显示计分结果

```gdscript
class_name GameHUD
extends Control

func init(controller: GameController, ai: AiBase) -> void
func update_all() -> void
func show_message(msg: String) -> void
func show_score(black_score: float, white_score: float, winner: Stone.Type) -> void
```

- **依赖**：6.3, 5.1, 4.3
- **验收**：完整人机对局可玩（选色 → 选难度 → 落子 → AI 响应 → 提子 → Pass → 终局计分）

---

## §10 阶段 7：扩展功能

### 任务 7.1 — 棋盘尺寸切换

- 新增 `Board.SIZE` 可配置（9/13/19）
- `BoardRenderer` 自动适配不同尺寸
- 星位坐标根据尺寸计算

### 任务 7.2 — 悔棋

- 保存每步完整棋盘快照到 `move_history`
- `undo()`：弹出最后一步，恢复棋盘 + 切换回上一方

### 任务 7.3 — SGF 棋谱导出

- 实现 SGF 格式序列化
- `export_sgf(path: String)`：将 `move_history` 导出为 .sgf 文件

---

### 任务 7.4 — MCTS AI 升级（V1.1）

- 文件：`src/ai/ai_mcts.gd`
- 将 AiHeuristic 替换为蒙特卡洛树搜索，棋力跃升至业余有段

```gdscript
class_name AiMcts
extends AiBase

var simulations: int = 5000  # 每步模拟次数

func get_move(board: Board, color: Stone.Type) -> Vector2i:
    # 对每个合法落子运行 MCTS
    # 返回胜率最高的落子
    pass

func get_name() -> String:
    return "MCTS AI"

func get_level() -> String:
    return "业余有段"
```

**MCTS 四步循环**：每次模拟执行 Selection → Expansion → Simulation → Backpropagation。5000 次模拟后选访问次数最多的子节点（详见 §A 可补充 MCTS 伪代码）。

**切换方式**：初始化时 `AiMcts.new(5000)` 替代 `AiHeuristic.new()`，GameController 零改动。

- **依赖**：AiBase 接口稳定即可，与现有代码无耦合
- **验收**：空棋盘先手占角，胜率显著高于 AiHeuristic

---

## §A 附录：核心算法参考伪代码

### A.1 棋组构建 + 气计算（BFS）

```
function build_group(board, seed):
    color = board.get_stone(seed)
    visited = 空集合
    queue = [seed]
    stones = []
    liberties = Set()  # 自动去重

    while queue 非空:
        cur = queue.pop_front()
        if cur in visited: continue
        visited.add(cur)
        stones.append(cur)

        for neighbor in board.get_neighbors(cur):
            neighbor_color = board.get_stone(neighbor)
            if neighbor_color == color and neighbor not in visited:
                queue.append(neighbor)
            elif neighbor_color == EMPTY:
                liberties.add(neighbor)

    return { "stones": stones, "liberties": liberties.to_array() }
```

### A.2 落子合法性检查

```
function play_move(board, row, col, color):
    if not board.is_on_board(row, col):
        return INVALID("off_board")
    if board.get_stone(row, col) != EMPTY:
        return INVALID("occupied")

    pre_hash = hash_board(board)

    # 临时放置
    board.set_stone(row, col, color)

    captured = []
    for neighbor in board.get_neighbors(row, col):
        if board.get_stone(neighbor) == opponent(color):
            group = build_group(board, neighbor)
            if group.liberties.size() == 0:
                for stone in group.stones:
                    board.set_stone(stone, EMPTY)
                    captured.append(stone)

    # 检查自杀
    own_group = build_group(board, Vector2i(row, col))
    if own_group.liberties.size() == 0:
        # 还原
        board.set_stone(row, col, EMPTY)
        for stone in captured:
            board.set_stone(stone, opponent(color))
        return INVALID("suicide")

    # 检查劫
    post_hash = hash_board(board)
    if post_hash == _ko_hash:
        # 还原
        board.set_stone(row, col, EMPTY)
        for stone in captured:
            board.set_stone(stone, opponent(color))
        return INVALID("ko")

    _ko_hash = pre_hash
    return VALID(captured)
```

### A.3 空域 BFS + 归属判定

```
function find_territories(board):
    visited = 全部 false
    territories = []

    for row in 0..SIZE-1:
        for col in 0..SIZE-1:
            if board.get_stone(row,col) == EMPTY and not visited[row][col]:
                # BFS 收集此空域
                region = []
                borders = Set()
                queue = [(row,col)]
                while queue 非空:
                    cur = queue.pop()
                    if visited[cur]: continue
                    visited[cur] = true
                    region.append(cur)
                    for neighbor in board.get_neighbors(cur):
                        n_color = board.get_stone(neighbor)
                        if n_color == EMPTY and not visited[neighbor]:
                            queue.append(neighbor)
                        elif n_color != EMPTY:
                            borders.add(n_color)
                territories.append({
                    "points": region,
                    "borders": borders  # {BLACK} / {WHITE} / {BLACK,WHITE}
                })
    return territories
```

### A.4 中国规则计分

```
function score(board, komi=7.5):
    black_score = count_stones(board, BLACK)
    white_score = count_stones(board, WHITE)

    for territory in find_territories(board):
        if territory.borders == {BLACK}:
            black_score += territory.points.size()
        elif territory.borders == {WHITE}:
            white_score += territory.points.size()
        # 如果 borders 包含双方或为空，不计入

    white_score += komi

    if black_score > white_score:
        winner = BLACK
    else:
        winner = WHITE

    return { black_score, white_score, winner }
```

---

## §B 附录：常见坑 & 注意事项

### B.0 各阶段快速参考

| 阶段 | 名称 | 文件目录 | 测试目录 | 任务数 |
| --- | --- | --- | --- | --- |
| 0 | 环境搭建 | 项目根 | `test/unit/` | 4 |
| 1 | 核心数据结构 | `src/core/` | `test/unit/` | 3 |
| 2 | 规则引擎 | `src/core/` | `test/unit/` | 7 |
| 3 | AI 模块 | `src/ai/` | `test/unit/` | 4 |
| 4 | 计分系统 | `src/core/` | `test/unit/` | 3 |
| 5 | 棋盘渲染 | `src/ui/` | `test/unit/` | 5 |
| 6 | 人机对战流程 | `src/game/`, `src/ui/`, `src/scenes/` | `test/unit/` + 手动¹ | 5 |
| 7 | 扩展功能 | 多目录 | 手动 | 4 |

¹ 阶段 6 中 GameController 状态转换（任务 6.3）是纯逻辑，必须写 GUT 测试（AI_THINKING 阻断、回合切换、连续 Pass 终局）。UI 部分（颜色/难度选择、HUD 渲染）手动验证。

### B.1 GUT 反模式（来自 tdd-godot skill）

1. ❌ **不要**在测试中访问 Godot 场景树（`get_tree()`, `get_node()`）— 核心层测试应纯数据
2. ❌ **不要**用 `yield`/`await` 做异步测试（GUT 有 `await` 支持，但核心逻辑是同步的）
3. ❌ **不要**在 `_ready()` 中初始化测试数据 — 用 `before_each()`
4. ❌ **不要**写依赖执行顺序的测试 — 每个测试独立
5. ❌ **不要**用 `assert_*` 之外的验证方式

### B.2 围棋规则易错点

1. **自杀判定必须在提子之后** — 先提对方无气子，再查己方是否有气
2. **劫只比较棋盘棋子布局**，不比较当前轮到哪方
3. **坐标顺序**：内部统一 `(row, col)`，row 先行号（1-19 = 0-18）
4. **Pass 清除劫**：一方 pass 后，劫禁手解除
5. **空域归属**：一个空域可能同时接触黑白（公气），此时不计入任何一方

### B.3 Godot 渲染注意事项

1. `_draw()` 只在 `queue_redraw()` 被调用后触发
2. 棋子渲染顺序：先画棋盘线，再画棋子（棋子覆盖在线上）
3. 输入处理用 `_input(event)` 或 `_unhandled_input(event)`，检查 `InputEventMouseButton`

### B.4 测试必须先运行再继续

每完成一个任务后，必须运行 GUT 确认测试通过。命令：

```bash
# 在 Godot 编辑器中运行 GUT，或使用命令行：
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -gexit
```

**⛔ 阶段级把关**：每个阶段最后一个任务完成后，运行**该阶段全部测试**（非仅最后一个任务）。全部绿了才能进入下一阶段。一个失败 = 停下来修，不允许攒到后面。

**阶段依赖链**：阶段 N 的 bug 在阶段 N+1 会被放大。例如 Board.clone() 浅拷贝 bug 在阶段 1 测试中可能不触发（测试没写深拷贝验证），但到阶段 2.4（劫检测）和阶段 3（AI 模拟）会静默失效。所以阶段 1 的深拷贝测试必须包含「修改克隆不影响原棋盘」的断言。

### B.5 AI 模块注意事项

1. **AiBase 接口只能增加方法，不能删除/修改已有方法签名** — 已有的 `AiRandom`、`AiHeuristic` 和将来的 `AiMcts` 都依赖它
2. **AI 的 `get_move()` 接收 `board.clone()` 而非原始 board** — 防止 AI 内部修改棋盘影响游戏状态。如果 AI 需要模拟（如 MCTS），在自己的副本上操作
3. **AI 计算不要阻塞主线程** — V1.0 的 AiRandom/AiHeuristic 计算量小，可同步调用。V1.1 的 MCTS 如果单步计算超过 1 秒，考虑用 `WorkerThread` 异步执行，完成后发信号通知 GameController
4. **测试不同 AI 时用 Mock Board** — 不需要构造完整真实局面，mock 出 `get_stone()` 和 `is_on_board()` 即可
5. **难度切换通过实例化不同 AI 类实现** — 不要在一个类里用 if/else 堆砌难度逻辑（违反开闭原则）
6. **AI 返回 (-1, -1) = Pass** — GameController 统一处理，所有 AI 实现必须遵守这个约定
7. **启发式打分权重可调** — 在 AiHeuristic 中用常量定义权重（如 `CORNER_SCORE = 10`），方便后续平衡性调整，避免魔法数字

---

> **开始开发时，使用 `/skill godot-workflow` 启动标准开发流程。严格按阶段顺序执行，不要跳步。**
