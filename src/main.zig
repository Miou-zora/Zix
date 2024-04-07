const std = @import("std");
const ray = @import("raylib.zig");

pub fn main() !void {
    try ray_main();
}

fn ray_main() !void {
    const width = 800;
    const height = 450;

    var dots = [_]ray.Vector2{.{.x=0, .y=0}} ** 10;
    var current_pos: u64 = 0;

    ray.InitWindow(width, height, "zig raylib example");
    defer ray.CloseWindow();

    while (!ray.WindowShouldClose()) {
        // draw
        {
            ray.BeginDrawing();
            defer ray.EndDrawing();

            if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT)) {
                dots[current_pos] = ray.GetMousePosition();
                current_pos = (current_pos + 1) % dots.len;
            }

            for (dots) |dot| {
                ray.DrawCircleV(dot, 10.0, ray.RED);
            }

            ray.ClearBackground(ray.GRAY);

            ray.DrawFPS(width - 100, 10);
        }
    }
}
