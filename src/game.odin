package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

// alias //
vector2 :: [2]f32

// constants //
SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 900

// entry point //
main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Space Shooter Game")
    defer rl.CloseWindow()
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.SetTargetFPS(500)
    
    player := g_player
    bullets := make_slice([]Actor, 128)
    shoot_time : f32 = 0.125
    shoot_timer : f32 = 0.0

    for !rl.WindowShouldClose() {
        // update
        delta : f32 = rl.GetFrameTime()
        shoot_timer -= delta

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
                shoot_timer = shoot_time
            }
        }

        player_update(&player, delta)
        for &bullet in bullets {
            actor_update(&bullet, delta)
            bullet_update(&bullet)
        }

        rl.ClearBackground(rl.BLACK)
        rl.BeginDrawing()
            // game elements
            for bullet in bullets {
                actor_draw(bullet)
            }
            actor_draw(player)
            
            // ui //
            rl.DrawText("Score: 0", 10, 10, 32, rl.WHITE)
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}

