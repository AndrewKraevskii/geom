const std = @import("std");

const geo = @import("geo");
const Vec2 = geo.Vec2;
const Point = geo.Point;
const sandwich = geo.sandwich;
const project = geo.project;
const mult = geo.product;
const join = geo.join;
const meet = geo.meet;
const rl = @import("raylib");
const Color = rl.Color;

const draw = @import("draw.zig");

const origin: geo.Point = .{
    .e123 = 1,
    .e023 = 0,
    .e013 = 0,
    .e012 = 0,
};

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

        const mouse_line = join(
            geo.Point{
                .e123 = 1,
                .e023 = ray.position.x,
                .e013 = ray.position.y,
                .e012 = ray.position.z,
            },
            geo.Point{
                .e123 = 1,
                .e023 = ray.position.add(ray.direction).x,
                .e013 = ray.position.add(ray.direction).y,
                .e012 = ray.position.add(ray.direction).z,
            },
        );

        const mouse_pos: Point = meet(mouse_line, geo.Plane{
            .e0 = 0,
            .e1 = 0,
            .e2 = 1,
            .e3 = 0,
        });

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
                geo.normalized(white_line),
                geo.normalized(join(blue_point, red_point)),
                0.5,
                // @floatCast(@sin(rl.getTime())),
            );

            const green_point = sandwich(
                // mult(white_line, pink_line),
                geo.exp(
                    geo.scale(geo.normalized(pink_line), @floatCast(rl.getTime())),
                ),
                red_point,
            );
            const yellow_point = project(white_line, red_point);

            draw.line(white_line, .white);
            draw.line(join(blue_point, red_point), .red);
            draw.line(join(green_point, red_point), .red);
            draw.line(pink_line, .pink);

            draw.point(green_point, .green);
            draw.point(yellow_point, .yellow);
            draw.point(red_point, .red);
            draw.point(blue_point, .blue);
            draw.lineSegment(blue_point, red_point, .red);
            draw.arrow(origin, .{
                .e123 = 1,
                .e023 = 0,
                .e013 = 5,
                .e012 = 0,
            }, 0.9, 0.4, 0.4, .gray);
            const dual_plane = geo.dual(blue_point);
            draw.plane(dual_plane, .blue);
            const plane = geo.Plane{
                .e0 = 3,
                .e1 = 3,
                .e2 = 1,
                .e3 = 1,
            };
            draw.plane(plane, .dark_blue);
            draw.line(meet(plane, dual_plane), .white);
            draw.motor(mult(white_line, pink_line), .brown);
        }
    }
}
