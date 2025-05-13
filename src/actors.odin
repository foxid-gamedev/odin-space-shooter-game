package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Actor
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Actor :: struct {
    position: vector2,
    velocity: vector2,
    shape: Shape,
    visible: bool,
    active: bool,
    collider: Shape,
    type: ActorType,
    
    health: i32,
    damage: i32,
}

ActorType :: enum {
    Default,
    Player,
    Obstacle,
    Enemy,
    Bullet_Player,
    Bullet_Enemy,
}

actor_update :: proc(actor: ^Actor, delta: f32) {
    if !actor.active do return

    actor.position += actor.velocity * delta

    #partial switch actor.type {
        case .Obstacle: obstacle_update(actor, delta)
        case .Bullet_Player: bullet_update(actor)
        case .Bullet_Enemy: bullet_update(actor)
    }
}

actor_draw :: proc(actor: Actor) {
    if !actor.visible do return
    
    shape_draw(actor.position, actor.shape)
}

actor_check_collision_rect :: proc(actor: Actor, pos: vector2, size: vector2) -> bool {
    if !actor.active do return false

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
    if !actor.active do return false

    switch col in actor.collider {
        case CircleShape: return rl.CheckCollisionCircles(
            actor.position, col.radius, pos, radius
        )
        case RectShape: return rl.CheckCollisionCircleRec(
            pos, 
            radius, 
            {actor.position.x + col.x, actor.position.y + col.y, col.w, col.h}
        )
    }

    return false
}

actor_check_collision_actor :: proc(actor: Actor, other: Actor) -> bool {
    if !actor.active || !other.active || actor.collider == nil || other.collider == nil {
        return false
    }

    // avoid nested switch by calling simplified version of actor_check on other actor
    switch other_col in other.collider {
        case CircleShape: return actor_check_collision_circle(
            actor, other.position, other_col.radius
        )
        case RectShape: return actor_check_collision_rect(
            actor, 
            other.position + {other_col.x, other_col.y}, 
            {other_col.w, other_col.h }
        )
    }
    
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

actor_take_damage :: proc(actor: ^Actor, damage: i32) {
    actor.health -= damage

    if actor.type == .Player && actor.health <= 0 {
        player_game_over()
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Player
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
PLAYER_HEALTH ::  100
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
    },
    type = .Player,
    health = PLAYER_HEALTH,
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

player_game_over :: proc() {
    send_game_over()
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Bullet
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BULLET_SPEED :: 1000

_default_bullet_shape : CircleShape = {
    radius = 8,
    color = rl.GOLD,
}

bullet_spawn :: proc(pos: vector2, dir: vector2, from_player: bool = true) -> Actor {
    return {
        position = pos,
        velocity = dir * BULLET_SPEED,
        shape = _default_bullet_shape,
        visible = true,
        active = true,
        collider = _default_bullet_shape,
        type = .Bullet_Player if from_player else .Bullet_Enemy,
    }
}

bullet_update :: proc(bullet: ^Actor) {
    if !bullet.active do return

    if bullet.active && !actor_is_inside_screen(bullet^) {
        bullet.active = false
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Obstacle
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
OBSTACLE_SPEED :: 350
OBSTACLE_DAMAGE :: 35
OBSTACLE_RADIUS :: 24
OBSTACLE_SCORE :: 5

obstacle_spawn :: proc(pos: vector2) -> Actor {
    return {
        position = pos,
        velocity = {0,OBSTACLE_SPEED},
        shape = CircleShape{
            radius = OBSTACLE_RADIUS,
            color = rl.GRAY,
        },
        visible = true,
        active = true,
        collider = CircleShape{
            radius = OBSTACLE_RADIUS,
            color = rl.GRAY
        },
        type = .Obstacle,
        damage = OBSTACLE_DAMAGE,
    }
}

obstacle_update :: proc(actor: ^Actor, delta: f32) {
    other_actors := game_get_active_actors()

    for other_actor in other_actors {
        if actor == other_actor do continue

        if other_actor.type == .Bullet_Player {
            if actor_check_collision_actor(actor^, other_actor^) {
                actor.active = false
                actor.visible = false
                game_add_score(OBSTACLE_SCORE)
                break
            }
        }
        else if other_actor.type == .Player {
            if actor_check_collision_actor(actor^, other_actor^) {
                actor.active = false
                actor.visible = false
                actor_take_damage(other_actor, actor.damage)
            }
        }
    }
}