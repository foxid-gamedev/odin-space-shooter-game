package game

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

    bullet := bullet_spawn(player.position + {0,-500}, {0,1})
    
    for !rl.WindowShouldClose() {
        // update
        delta : f32 = rl.GetFrameTime()
        
        if rl.IsKeyPressed(.SPACE) {
            bullet = bullet_spawn(player.position, {0,-1})
        }

        player_update(&player, delta)
        actor_update(&bullet, delta)
        bullet_update(&bullet)

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

