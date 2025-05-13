package game

import "core:fmt"
import "core:math"
import "core:math/rand"

import rl "vendor:raylib"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Alias //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
vector2 :: [2]f32

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Constants //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 900
SHOOT_TIME :: 0.125
OBSTACLE_TIME :: 1.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
g_active_actors : [dynamic]^Actor
g_running : bool = true
g_score : i32 = 0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Entry Point
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Space Shooter Game")
    defer rl.CloseWindow()

    rl.SetConfigFlags({.VSYNC_HINT})
    rl.SetTargetFPS(500)

    player := g_player

    bullets := make_slice([]Actor, 128)
    obstacles := make_slice([]Actor, 32)

    shoot_timer : f32 = 0.0
    obstacle_spawn_timer : f32 = 0.0

    for g_running && !rl.WindowShouldClose() {
        // delta time //
        delta : f32 = rl.GetFrameTime()
        shoot_timer -= delta
        obstacle_spawn_timer -= delta

        // spawn obstacles //
        if obstacle_spawn_timer <= 0.0 {
            obstacle_index : i32 = 0
            can_spawn: bool = false

            for ;; {
                if !obstacles[obstacle_index].active {
                    can_spawn = true
                    break
                }
                obstacle_index = (obstacle_index + 1)
                if obstacle_index >= 32 do break
            }

            if can_spawn {
                sx := rand.float32_range(100, SCREEN_WIDTH-100)
                sy := rand.float32_range(0, 200)
                obstacles[obstacle_index] = obstacle_spawn({sx, sy})
            }
    
            // rather wait the same amount again when everything is occupied
            obstacle_spawn_timer = OBSTACLE_TIME
        }

        // Get all active actors // 
        g_active_actors = make_dynamic_array([dynamic]^Actor, allocator = context.temp_allocator)
        
        for &bullet in bullets {
            if bullet.active {
                append(&g_active_actors, &bullet)
            }
        }

        if player.active {
            append(&g_active_actors, &player)
        }

        for &obstacle in obstacles {
            if obstacle.active {
                append(&g_active_actors, &obstacle)
            }
        }

        if rl.IsKeyDown(.SPACE) && shoot_timer <= 0{
            bullet_index : i32 = 0
            can_spawn: bool = false

            for ;; {
                if !bullets[bullet_index].active {
                    can_spawn = true        
                    break
                }
                bullet_index = (bullet_index + 1)
                if bullet_index >= 128 do break
            }
            
            if can_spawn {
                bullets[bullet_index] = bullet_spawn(player.position, {0,-1})
                shoot_timer = SHOOT_TIME
            }
        }

        // update //
        player_update(&player, delta)
       
        for actor in game_get_active_actors() {
            actor_update(actor, delta)
        }

        rl.ClearBackground(rl.BLACK)
        rl.BeginDrawing()
            // game elements //
            for actor in game_get_active_actors() {
                actor_draw(actor^)
            }
            
            // ui //
            score_str := fmt.ctprint("Score:", g_score, "| Player Health:", player.health)
            rl.DrawText(score_str, 10, 10, 40, rl.WHITE)
        rl.EndDrawing()

        // free memory //
        free_all(context.temp_allocator)
        
    }
}

game_get_active_actors :: proc() -> []^Actor {
    return g_active_actors[:]
}

send_game_over :: proc() {
    fmt.print("Game Over")
    g_running = false
}

game_add_score :: proc(score: i32) {
    g_score += score
}