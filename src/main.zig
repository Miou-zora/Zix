const std = @import("std");
const ray = @import("raylib.zig");
const NUMBER_OF_DOTS = 10;
pub fn main() !void {
    try ray_main();
}

pub fn interpolate(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

pub fn interpolate_vector2(a: ray.Vector2, b: ray.Vector2, t: f32) ray.Vector2 {
    return ray.Vector2{
        .x = interpolate(a.x, b.x, t),
        .y = interpolate(a.y, b.y, t),
    };
}

// https://www.youtube.com/watch?v=9_aJGUTePYo
pub fn get_pos_from_catmull_rom_spline_local(list_of_dots: []ray.Vector2, t: f32) ray.Vector2 {
    const p1 = @as(usize, @intFromFloat(@floor(t))) + 1;
    const p2 = p1 + 1;
    const p3 = p2 + 1;
    const p0 = p1 - 1;

    const tt = t * t;
    const ttt = tt * t;

    const q1 = -ttt + 2.0 * tt - t;
    const q2 = 3.0 * ttt - 5.0 * tt + 2.0;
    const q3 = -3.0 * ttt + 4.0 * tt + t;
    const q4 = ttt - tt;

    const tx = 0.5 * (list_of_dots[p0].x * q1 + list_of_dots[p1].x * q2 + list_of_dots[p2].x * q3 + list_of_dots[p3].x * q4);
    const ty = 0.5 * (list_of_dots[p0].y * q1 + list_of_dots[p1].y * q2 + list_of_dots[p2].y * q3 + list_of_dots[p3].y * q4);

    return ray.Vector2{ .x = tx, .y = ty };
}

pub fn get_value_from_catmull_rom_spline(list_of_dots: []ray.Vector2, global_t: f32) ray.Vector2 {
    if (list_of_dots.len <= 3) {
        return ray.Vector2{ .x = 0, .y = 0 };
    }
    if (global_t == 1) {
        return list_of_dots[list_of_dots.len - 1];
    } else if (global_t == 0) {
        return list_of_dots[0];
    }
    const local_t = global_t * @as(f32, @floatFromInt(list_of_dots.len - 3));
    const i: usize = @intFromFloat(@floor(local_t));
    const vec = get_pos_from_catmull_rom_spline_local(list_of_dots[i..(i + 4)], local_t - @as(f32, @floatFromInt(i)));
    return vec;
}

pub fn get_value_from_bezier_spline(list_of_dots: []ray.Vector2, t: f32) ray.Vector2 {
    if (list_of_dots.len <= 1) {
        return ray.Vector2{ .x = 0, .y = 0 };
    }
    if (t == 1) {
        return list_of_dots[list_of_dots.len - 1];
    } else if (t == 0) {
        return list_of_dots[0];
    }
    var cpy_list_of_dots = [_]ray.Vector2{.{ .x = 0, .y = 0 }} ** NUMBER_OF_DOTS;
    @memcpy(&cpy_list_of_dots, list_of_dots);
    var i: u64 = list_of_dots.len - 1;
    while (i > 0) {
        for (0..(list_of_dots.len - 1)) |k| {
            cpy_list_of_dots[k] = interpolate_vector2(cpy_list_of_dots[k], cpy_list_of_dots[k + 1], t);
        }
        i -= 1;
    }
    return cpy_list_of_dots[0];
}

pub fn draw_spline(pos_fn: *const fn (list_of_dots: []ray.Vector2, t: f32) ray.Vector2, list_of_dots: []ray.Vector2, color: ray.Color) !void {
    const num_points = 100;
    var points = [_]ray.Vector2{.{ .x = 0, .y = 0 }} ** (num_points + 1);
    for (0..(num_points + 1)) |i| {
        points[i] = pos_fn(list_of_dots, @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(num_points)));
    }
    for (1..(num_points + 1)) |i| {
        ray.DrawLineV(points[i - 1], points[i], color);
    }
}

fn ray_main() !void {
    const width = 800;
    const height = 450;

    var dots = [_]ray.Vector2{.{ .x = 0, .y = 0 }} ** NUMBER_OF_DOTS;

    const splines = comptime [_]*const fn (list_of_dots: []ray.Vector2, t: f32) ray.Vector2{ &get_value_from_bezier_spline, &get_value_from_catmull_rom_spline };
    const splines_names = comptime [_][*:0]const u8{
        "Bezier",
        "Catmull-Rom",
    };
    var used_spline: u64 = 0;
    ray.InitWindow(width, height, "Zix");
    defer ray.CloseWindow();

    while (!ray.WindowShouldClose()) {
        {
            if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_LEFT)) {
                for (1..(dots.len)) |i| {
                    dots[dots.len - i] = dots[dots.len - i - 1];
                }
                dots[0] = ray.GetMousePosition();
            }
            if (ray.IsKeyPressed(ray.KEY_SPACE)) {
                used_spline = @mod(used_spline + 1, splines.len);
            }
        }
        {
            ray.BeginDrawing();
            defer ray.EndDrawing();
            ray.ClearBackground(ray.GRAY);

            for (dots) |dot| {
                ray.DrawCircleV(dot, 10.0, ray.RED);
            }
            try draw_spline(splines[used_spline], &dots, ray.GREEN);

            ray.DrawText(splines_names[used_spline], 10, 10, 20, ray.BLACK);

                ray.DrawFPS(width - 100, 10);
        }
    }
}
