package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

// Actor // 
Actor :: struct {
    position: vector2,
    velocity: vector2,
    shape: Shape,
    visible: bool,
    active: bool,
    collider: Shape,
}

actor_update :: proc(actor: ^Actor, delta: f32) {
    if !actor.active do return

    actor.position += actor.velocity * delta
}

actor_draw :: proc(actor: Actor) {
    if !actor.visible do return
    
    shape_draw(actor.position, actor.shape)
}

actor_check_collision_rect :: proc(actor: Actor, pos: vector2, size: vector2) -> bool {
    switch col in actor.collider {
        case CircleShape: return rl.CheckCollisionCircleRec(
            actor.position, col.radius, {pos.x, pos.y, size.x, size.y}
        )
        case RectShape: return rl.CheckCollisionRecs(
            {actor.position.x + col.x, actor.position.y + col.y, col.w, col.h},
            {pos.x, pos.y, size.x, size.y}
        )
    }
    return false
}

actor_check_collision_circle :: proc(actor: Actor, pos: vector2, radius: f32) -> bool {
    return false
}

actor_check_collision_actor :: proc(actor: Actor, other: Actor) -> bool {
    return false
}

actor_check_collision :: proc{
    actor_check_collision_rect,
    actor_check_collision_circle,
    actor_check_collision_actor,
}

actor_is_inside_screen :: proc(actor: Actor, margin: f32 = 0) -> bool {
    return actor_check_collision_rect(actor, {-margin, -margin}, {SCREEN_WIDTH + margin, SCREEN_HEIGHT + margin})
}

// Player //
PLAYER_MAX_SPEED :: 800
PLAYER_SPEED_ACCELERATION :: 500
PLAYER_START_POS : vector2 : {SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.9}
PLAYER_MIN_POS : vector2 : {SCREEN_WIDTH * 0.1, SCREEN_HEIGHT * 0.7}
PLAYER_MAX_POS : vector2 : {SCREEN_WIDTH * 0.9, SCREEN_HEIGHT * 0.9}

g_player : Actor = {
    position = PLAYER_START_POS,
    shape = RectShape{
        x = -32, y = -32,
        w = 64, h = 64,
        color = rl.BLUE,
    },
    visible = true,
    active = true,
    collider = CircleShape{
        radius = 32,
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

// Bullet //
BULLET_SPEED :: 1000

_default_bullet_shape : CircleShape = {
    radius = 8,
    color = rl.GOLD,
}

bullet_spawn :: proc(pos: vector2, dir: vector2) -> Actor {
    return {
        position = pos,
        velocity = dir * BULLET_SPEED,
        shape = _default_bullet_shape,
        visible = true,
        active = true,
        collider = _default_bullet_shape,
    }
}

bullet_update :: proc(bullet: ^Actor) {
    if !bullet.active do return

    if bullet.active && !actor_is_inside_screen(bullet^) {
        bullet.active = false
    }
}