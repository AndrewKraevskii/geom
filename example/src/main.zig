const std = @import("std");

const geo = @import("geo");
const Vec2 = geo.Vec2;
const rl = @import("raylib");
const Point = geo.Point;
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

    var red_point: Point = .{
        .e123 = 1,
        .e012 = 0,
        .e023 = 1,
        .e013 = 1,
    };
    var blue_point: Point = .{
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

        // drawAxis(0, 0, 1000, .red);
        // rl.drawText("geo math", 0, 0, 10, .red);

        const vec = rl.getScreenToWorld2D(rl.getMousePosition(), camera);

        const mouse_pos: Point =
            .{
                .e123 = 1,
                .e023 = vec.x,
                .e013 = vec.y,
                .e012 = 0,
            };

        if (rl.isMouseButtonDown(.left)) {
            red_point = mouse_pos;
        } else if (rl.isMouseButtonDown(.right)) {
            blue_point = mouse_pos;
        }

        {
            const white_line = join(blue_point, Point{
                .e123 = 1,
                .e023 = 0,
                .e013 = 0,
                .e012 = 0,
            });
            const pink_line = geo.lerp(
                white_line,
                join(blue_point, red_point),
                @floatCast((@sin(rl.getTime()) + 1) / 2),
            );

            const green_point = sandwich(mult(white_line, pink_line), red_point);
            const yellow_point = project(white_line, red_point);

            drawTriangle(.{ green_point, yellow_point, blue_point }, .magenta);
            drawLine(white_line, .white);
            drawLine(join(blue_point, red_point), .red);
            drawLine(join(green_point, red_point), .red);
            drawLine(pink_line, .pink);

            drawPoint(green_point, .green);
            drawPoint(yellow_point, .yellow);
            drawPoint(red_point, .red);
            drawPoint(blue_point, .blue);
            drawLine(meet(geo.Plane{
                .e2 = 0,
                .e1 = 0,
                .e3 = 1,
                .e0 = 0,
            }, geo.dual(blue_point)), .blue);
        }
    }
}

pub fn drawPoint(point: Point, color: Color) void {
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

    rl.drawLineV(toRaylibPoint(start), toRaylibPoint(end), color);
}

pub fn toRaylibPoint(p: Point) rl.Vector2 {
    return .{
        .x = p.e023 / p.e123,
        .y = p.e013 / p.e123,
    };
}

pub fn drawTriangle(points: [3]Point, color: Color) void {
    rl.drawTriangle(
        toRaylibPoint(points[0]),
        toRaylibPoint(points[1]),
        toRaylibPoint(points[2]),
        color,
    );
    rl.drawTriangle(
        toRaylibPoint(points[1]),
        toRaylibPoint(points[0]),
        toRaylibPoint(points[2]),
        color,
    );
}

pub fn drawAxis(x: f32, y: f32, size: f32, color: Color) void {
    rl.drawLineV(.{ .x = x, .y = y - size / 2 }, .{ .x = x, .y = y + size / 2 }, color);
    rl.drawLineV(.{ .x = x - size / 2, .y = y }, .{ .x = x + size / 2, .y = y }, color);
}
