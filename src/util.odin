package game

vector2_clamp :: proc(v: vector2, min: vector2, max: vector2) -> vector2 {
    return {
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y)
    }
}