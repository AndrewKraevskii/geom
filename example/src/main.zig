const std = @import("std");

const geo = @import("geo");
const Vec2 = geo.Vec2;
const rl = @import("raylib");
const Color = rl.Color;
const sandwich = geo.sandwich;
const project = geo.project;
const mult = geo.geomProduct;
const join = geo.join;
const meet = geo.meet;

pub fn main() !void {
    rl.initWindow(720, 480, "geo math");
    defer rl.closeWindow();

    var camera: rl.Camera2D = .{
        .target = .zero(),
        .offset = .{ .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2, .y = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2 },
        .zoom = 1,
        .rotation = 0,
    };

    var start_point: geo.Point = .{
        .e123 = 1,
        .e012 = 0,
        .e023 = 1,
        .e013 = 1,
    };
    var end_point: geo.Point = .{
        .e123 = 1,
        .e012 = 0,
        .e023 = 1,
        .e013 = 1,
    };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        camera.begin();
        defer camera.end();

        drawAxis(0, 0, 1000, .red);
        rl.drawText("geo math", 0, 0, 10, .red);

        const vec = rl.getScreenToWorld2D(rl.getMousePosition(), camera);

        const mouse_pos: geo.Point =
            .{
                .e123 = 1,
                .e023 = vec.x,
                .e013 = vec.y,
                .e012 = 0,
            };

        if (rl.isMouseButtonDown(.left)) {
            start_point = mouse_pos;
        } else if (rl.isMouseButtonDown(.right)) {
            end_point = mouse_pos;
        }

        {
            const flip_around = join(end_point, geo.Point{
                .e123 = 1,
                .e023 = 0,
                .e013 = 0,
                .e012 = 0,
            });

            const reflected = sandwich(flip_around, start_point);
            const projected = project(flip_around, start_point);

            drawLine(flip_around, .white);
            drawLine(join(end_point, start_point), .red);
            drawLine(join(reflected, start_point), .red);
            drawLine(geo.lerp(
                flip_around,
                join(end_point, start_point),
                @floatCast((@sin(rl.getTime()) + 1) / 2),
            ), .red);

            drawPoint(reflected, .green);
            drawPoint(projected, .yellow);
            drawPoint(start_point, .red);
            drawPoint(end_point, .blue);
        }
    }
}

pub fn drawPoint(point: geo.Point, color: Color) void {
    const vec: rl.Vector2 = .{
        .x = point.e023 / point.e123,
        .y = point.e013 / point.e123,
    };
    rl.drawCircleV(vec, 10, color);
}

pub fn drawLine(line: geo.Line, color: Color) void {
    const left_side_of_screen = geo.Plane{
        .e2 = -1,
        .e1 = 0,
        .e3 = 0,
        .e0 = 1000,
    };

    const right_side_of_screen = geo.Plane{
        .e2 = 1,
        .e1 = 0,
        .e3 = 0,
        .e0 = 1000,
    };

    const start = geo.meet(left_side_of_screen, line);
    const end = geo.meet(right_side_of_screen, line);

    rl.drawLineV(.{
        .x = start.e023 / start.e123,
        .y = start.e013 / start.e123,
    }, .{
        .x = end.e023 / end.e123,
        .y = end.e013 / end.e123,
    }, color);
}

pub fn drawAxis(x: f32, y: f32, size: f32, color: Color) void {
    rl.drawLineV(.{ .x = x, .y = y - size / 2 }, .{ .x = x, .y = y + size / 2 }, color);
    rl.drawLineV(.{ .x = x - size / 2, .y = y }, .{ .x = x + size / 2, .y = y }, color);
}
