const std = @import("std");

const geo = @import("geo");
const Vec2 = geo.Vec2;
const sandwich = geo.sandwichProduct;
const project = geo.orhogonalProjection;
const mult = geo.geometricProduct;
const join = geo.join;
const meet = geo.meet;
const rl = @import("raylib");
const Color = rl.Color;
const p = geo.primitive;

const draw = @import("draw.zig");

const origin: p.Point = .{
    .e123 = 1,
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

    var red_point: p.Point = .{
        .e123 = 1,
        .e012 = 3,
        .e032 = 1,
        .e013 = -4,
    };
    var blue_point: p.Point = .{
        .e123 = 1,
        .e012 = 0,
        .e032 = -7,
        .e013 = -9,
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
            .{
                .e123 = 1,
                .e032 = ray.position.x,
                .e013 = ray.position.y,
                .e012 = ray.position.z,
            },
            .{
                .e123 = 1,
                .e032 = ray.position.add(ray.direction).x,
                .e013 = ray.position.add(ray.direction).y,
                .e012 = ray.position.add(ray.direction).z,
            },
        );

        const mouse_pos: p.Point = meet(mouse_line, .{
            .e2 = 1,
        });

        if (rl.isMouseButtonDown(.left)) {
            red_point = mouse_pos;
        } else if (rl.isMouseButtonDown(.right)) {
            blue_point = mouse_pos;
        }

        {
            const white_line = join(blue_point, .{
                .e023 = 1,
            });

            const pink_line = geo.lerp(
                geo.normalized(white_line),
                geo.normalized(join(blue_point, red_point)),
                @sin(@as(f32, @floatCast(rl.getTime()))),
            );

            const green_point = sandwich(
                red_point,
                geo.exp(
                    geo.geometricProduct(geo.normalized(pink_line), .{ .@"1" = @as(f32, @floatCast(rl.getTime())) }),
                ),
            );
            const yellow_point = project(red_point, white_line);

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
                .e013 = 5,
            }, 0.9, 0.4, 0.4, .gray);
            const dual_plane = geo.dual(blue_point);
            draw.plane(dual_plane, .blue);
            const plane: p.Plane = .{
                .e0 = 3,
                .e1 = 3,
                .e2 = 1,
                .e3 = 1,
            };
            draw.plane(plane, .dark_blue);
            draw.line(meet(plane, dual_plane), .white);
            // draw.motor(mult(white_line, pink_line), .brown);
        }
    }
}
