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

    var camera: rl.Camera3D = .{
        .target = .zero(),
        .position = .{
            .x = -10,
            .y = 10,
            .z = -10,
        },
        .up = .{
            .x = 0,
            .y = 1,
            .z = 0,
        },
        .fovy = 60,
        .projection = .perspective,
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
        rl.drawGrid(10, 1);

        const ray = rl.getScreenToWorldRay(rl.getMousePosition(), camera);

        const collision = rl.getRayCollisionQuad(
            ray,
            .{
                .x = -10,
                .y = 0,
                .z = -10,
            },
            .{
                .x = 10,
                .y = 0,
                .z = -10,
            },
            .{
                .x = 10,
                .y = 0,
                .z = 10,
            },
            .{
                .x = -10,
                .y = 0,
                .z = 10,
            },
        );

        const mouse_pos: Point =
            .{
                .e123 = 1,
                .e023 = collision.point.x,
                .e013 = collision.point.y,
                .e012 = collision.point.z,
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
                .e013 = 1,
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
            drawLineSegment(blue_point, red_point, .red);
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
    const vec: rl.Vector3 = .{
        .x = point.e023 / point.e123,
        .y = point.e013 / point.e123,
        .z = point.e012 / point.e123,
    };
    rl.drawSphere(vec, 1, color);
}

pub fn drawLine(line: geo.Line, color: Color) void {
    const plane_distance_from_origin = 10;

    var plane = geo.normalized(geo.innerProduct(
        geo.Point{
            .e123 = 1,
            .e023 = 0,
            .e013 = 0,
            .e012 = 0,
        },
        line,
    ));
    plane.e0 = plane_distance_from_origin;
    const start = meet(plane, line);
    plane.e0 *= -1;
    const end = meet(plane, line);

    drawLineSegment(start, end, color);
}

pub fn drawLineSegment(start: geo.Point, end: geo.Point, color: Color) void {
    rl.drawLine3D(toRaylibPoint(start), toRaylibPoint(end), color);
}

pub fn toRaylibPoint(p: Point) rl.Vector3 {
    return .{
        .x = p.e023 / p.e123,
        .y = p.e013 / p.e123,
        .z = p.e012 / p.e123,
    };
}

pub fn drawTriangle(points: [3]Point, color: Color) void {
    rl.drawTriangle3D(
        toRaylibPoint(points[0]),
        toRaylibPoint(points[1]),
        toRaylibPoint(points[2]),
        color,
    );
    rl.drawTriangle3D(
        toRaylibPoint(points[1]),
        toRaylibPoint(points[0]),
        toRaylibPoint(points[2]),
        color,
    );
}
