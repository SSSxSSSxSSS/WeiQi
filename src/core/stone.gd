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
