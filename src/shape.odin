package game

import rl "vendor:raylib"

CircleShape :: struct { 
    radius: f32, 
    color: Maybe(rl.Color), 
}

RectShape :: struct { 
    x, y, w, h: f32, 
    color: Maybe(rl.Color), 
}

// unions //
Shape :: union { 
    CircleShape,
    RectShape 
}

// procedures //
shape_draw :: proc(position: vector2, shape: Shape) {
    switch s in shape {
        case CircleShape: rl.DrawCircle(
            i32(position.x), i32(position.y), 
            s.radius, 
            s.color.? or_else rl.PINK,
        )
        case RectShape: rl.DrawRectangle(
            i32(position.x + s.x), i32(position.y + s.y), 
            i32(s.w), i32(s.h), 
            s.color.? or_else rl.PINK,
        )
    }
}