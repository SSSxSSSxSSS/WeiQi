# test/unit/test_board_renderer.gd
extends GutTest

const BoardRenderer = preload("res://src/ui/board_renderer.gd")

# ============================================================
# 阶段 5 — BoardRenderer 坐标转换 行为规格
# ============================================================
# 坐标转换是可以自动化测试的部分。
# 渲染效果（颜色、线条、棋子）需在编辑器中人工查看。

# ------------------------------------------------------------
# 测试 1: grid_to_pixel——(0,0) 对应棋盘左上角边距位置
# ------------------------------------------------------------
func test_grid_to_pixel_origin():
    var renderer = BoardRenderer.new()
    var pixel = renderer.grid_to_pixel(0, 0)
    assert_eq(pixel, Vector2(40, 40), "(0,0) → (40,40)")

# ------------------------------------------------------------
# 测试 2: grid_to_pixel——(18,18) 对应棋盘右下角
# ------------------------------------------------------------
func test_grid_to_pixel_corner():
    var renderer = BoardRenderer.new()
    var pixel = renderer.grid_to_pixel(18, 18)
    # CELL_SIZE=36, BOARD_PADDING=40, 18*36 + 40 = 688
    assert_eq(pixel, Vector2(688, 688), "(18,18) → (688,688)")

# ------------------------------------------------------------
# 测试 3: pixel_to_grid——棋盘内像素转坐标
# ------------------------------------------------------------
func test_pixel_to_grid_inside():
    var renderer = BoardRenderer.new()
    var grid = renderer.pixel_to_grid(Vector2(40, 40))
    assert_eq(grid, Vector2i(0, 0), "(40,40) → (0,0)")

# ------------------------------------------------------------
# 测试 4: pixel_to_grid——棋盘外返回 (-1,-1)
# ------------------------------------------------------------
func test_pixel_to_grid_outside():
    var renderer = BoardRenderer.new()
    var grid = renderer.pixel_to_grid(Vector2(0, 0))
    assert_eq(grid, Vector2i(-1, -1), "(0,0) 在棋盘外")
