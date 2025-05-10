package game

import rl "vendor:raylib"
import "core:math"
import "core:math/linalg"

// alias //
vector2 :: [2]f32

// constants //
SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 900

PLAYER_MAX_SPEED :: 800
PLAYER_SPEED_ACCELERATION :: 500
PLAYER_START_POS : vector2 : {SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.9}
PLAYER_MIN_POS : vector2 : {SCREEN_WIDTH * 0.1, SCREEN_HEIGHT * 0.7}
PLAYER_MAX_POS : vector2 : {SCREEN_WIDTH * 0.9, SCREEN_HEIGHT * 0.9}

// structs //
Actor :: struct {
    position: vector2,
    velocity: vector2,
    shape: Shape,
    visible: bool,
    active: bool,
}

CircleShape :: struct { 
    radius: f32, 
    color: rl.Color, 
}

RectShape :: struct { 
    x, y, w, h: f32, 
    color: rl.Color, 
}

// unions //
Shape :: union { 
    CircleShape, 
    RectShape 
}

// procedures //
actor_update :: proc(actor: ^Actor, delta: f32) {
    if !actor.active do return

    actor.position += actor.velocity * delta
}

actor_draw :: proc(actor: Actor) {
    if !actor.visible do return
    
    shape_draw(actor.position, actor.shape)
}

shape_draw :: proc(position: vector2, shape: Shape) {
    switch s in shape {
        case CircleShape: rl.DrawCircle(
            i32(position.x), i32(position.y), 
            s.radius, 
            s.color
        )
        case RectShape: rl.DrawRectangle(
            i32(position.x + s.x), i32(position.y + s.y), 
            i32(s.w), i32(s.h), 
            s.color
        )
    }
}

vector2_clamp :: proc(v: vector2, min: vector2, max: vector2) -> vector2 {
    return {
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y)
    }
}

player_update :: proc(player: ^Actor, delta: f32) {
    if !player.active do return

    player_direction : vector2 = {
        1.0 if rl.IsKeyDown(.RIGHT) else -1.0 if rl.IsKeyDown(.LEFT) else 0.0,
        1.0 if rl.IsKeyDown(.DOWN) else -1.0 if rl.IsKeyDown(.UP) else 0.0,
    }

    if abs(player.velocity.x) >= math.F32_EPSILON {
        player.velocity.x = linalg.lerp(player.velocity.x, 0, delta)
    } else {
        player.velocity.x = 0
    }

    if abs(player.velocity.y) >= math.F32_EPSILON {
        player.velocity.y = linalg.lerp(player.velocity.y, 0, delta)
    } else {
        player.velocity.y = 0
    }

    player.velocity += player_direction * PLAYER_SPEED_ACCELERATION * delta
    actor_update(player, delta)
    player.position = vector2_clamp(player.position, PLAYER_MIN_POS, PLAYER_MAX_POS)
}

// entry point //
main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Space Shooter Game")
    defer rl.CloseWindow()

    rl.SetConfigFlags({.VSYNC_HINT})
    rl.SetTargetFPS(500)
    
    player : Actor = {
        position = PLAYER_START_POS,
        velocity = {0, 0},
        shape = RectShape{
            x = -32, y = -32,
            w = 64, h = 64,
            color = rl.BLUE,
        },
        visible = true,
        active = true,
    }

    bullet : Actor = {
        position = PLAYER_START_POS - {0, 300},
        velocity = {0, 100},
        shape = CircleShape{
            radius = 16,
            color = rl.GOLD,
        },
        visible = true,
        active = true,
    }

    for !rl.WindowShouldClose() {
        // update
        delta : f32 = rl.GetFrameTime()
        
        player_update(&player, delta)
        actor_update(&bullet, delta)

        rl.ClearBackground(rl.BLACK)
        rl.BeginDrawing()
            // game elements
            actor_draw(player)
            actor_draw(bullet)

            // ui //
            rl.DrawText("Score: 0", 10, 10, 32, rl.WHITE)
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}

