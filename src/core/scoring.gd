# src/core/scoring.gd
class_name GoScoring
extends RefCounted

## 中国规则计分，返回 { black_score, white_score, winner }
static func score(board: Board, komi: float = 7.5) -> Dictionary:
    var visited: Array[Array] = []
    for row in Board.SIZE:
        visited.append([])
        for _col in Board.SIZE:
            visited[row].append(false)

    var black_score: float = 0.0
    var white_score: float = 0.0

    for row in Board.SIZE:
        for col in Board.SIZE:
            var stone: Stone.Type = board.get_stone(row, col)
            if stone == Stone.Type.BLACK:
                black_score += 1.0
            elif stone == Stone.Type.WHITE:
                white_score += 1.0
            elif not visited[row][col]:
                # 找到未访问的空位，BFS 收集整个空域
                var territory: Dictionary = _flood_fill(board, visited, row, col)
                if territory["owner"] == Stone.Type.BLACK:
                    black_score += territory["size"]
                elif territory["owner"] == Stone.Type.WHITE:
                    white_score += territory["size"]
                # 中立 → 不计数

    white_score += komi

    var winner: Stone.Type = Stone.Type.EMPTY
    if black_score > white_score:
        winner = Stone.Type.BLACK
    elif white_score > black_score:
        winner = Stone.Type.WHITE

    return { "black_score": black_score, "white_score": white_score, "winner": winner }

## BFS 收集连通空域，判断归属
static func _flood_fill(board: Board, visited: Array[Array], start_row: int, start_col: int) -> Dictionary:
    var queue: Array[Vector2i] = [Vector2i(start_row, start_col)]
    visited[start_row][start_col] = true
    var size: float = 0.0
    var borders_black: bool = false
    var borders_white: bool = false

    while not queue.is_empty():
        var cur: Vector2i = queue.pop_front()
        size += 1.0

        for nb in board.get_neighbors(cur.x, cur.y):
            var nb_stone: Stone.Type = board.get_stone(nb.x, nb.y)
            if nb_stone == Stone.Type.EMPTY and not visited[nb.x][nb.y]:
                visited[nb.x][nb.y] = true
                queue.append(nb)
            elif nb_stone == Stone.Type.BLACK:
                borders_black = true
            elif nb_stone == Stone.Type.WHITE:
                borders_white = true

    var owner: Stone.Type = Stone.Type.EMPTY  # 中立
    if borders_black and not borders_white:
        owner = Stone.Type.BLACK
    elif borders_white and not borders_black:
        owner = Stone.Type.WHITE

    return { "size": size, "owner": owner }
