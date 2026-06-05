# src/core/group.gd
class_name StoneGroup
extends RefCounted

## 从种子坐标 BFS，收集同色相连棋子和它们的气
## 返回 Dictionary { "stones": Array[Vector2i], "liberties": Array[Vector2i] }
static func build_group(board: Board, seed: Vector2i) -> Dictionary:
    var color: Stone.Type = board.get_stone(seed.x, seed.y)
    if color == Stone.Type.EMPTY:
        return { "stones": [], "liberties": [] }

    # visited 二维数组：记录已访问位置
    var visited: Array[Array] = []
    for row in Board.SIZE:
        visited.append([])
        for _col in Board.SIZE:
            visited[row].append(false)

    var queue: Array[Vector2i] = [seed]
    visited[seed.x][seed.y] = true

    var stones: Array[Vector2i] = []
    var liberties: Dictionary = {}  # key="row,col" → Vector2i，用 Dict 做 Set 去重

    while not queue.is_empty():
        var cur: Vector2i = queue.pop_front()
        stones.append(cur)

        for nb in board.get_neighbors(cur.x, cur.y):
            var nb_color: Stone.Type = board.get_stone(nb.x, nb.y)
            if nb_color == color and not visited[nb.x][nb.y]:
                visited[nb.x][nb.y] = true
                queue.append(nb)
            elif nb_color == Stone.Type.EMPTY:
                var key: String = "%d,%d" % [nb.x, nb.y]
                if not liberties.has(key):
                    liberties[key] = nb

    # 将 Dict 的 values 转为 Array
    var liberties_arr: Array[Vector2i] = []
    for key in liberties:
        liberties_arr.append(liberties[key])

    return { "stones": stones, "liberties": liberties_arr }
