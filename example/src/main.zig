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

        rl.drawFPS(0, 0);

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
                geo.normalized(white_line),
                geo.normalized(join(blue_point, red_point)),
                @floatCast(@abs(@mod(rl.getTime(), 2) - 1)),
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
            drawPoint(origin, .ray_white);
            drawPlane(geo.dual(blue_point), Color.blue.alpha(0.5));
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

const plane_distance_from_origin = 10;

pub fn drawLine(line: geo.Line, color: Color) void {
    var plane = geo.normalized(geo.innerProduct(
        origin,
        line,
    ));
    plane.e0 = plane_distance_from_origin;
    const start = meet(plane, line);
    plane.e0 *= -1;
    const end = meet(plane, line);

    drawLineSegment(start, end, color);
}

pub fn drawPlane(plane: geo.Plane, color: Color) void {
    _ = plane; // autofix
    _ = color; // autofix
    // const geo.innerProduct(
    //     plane,
    //     origin,
    // );
    // const planes = [6]geo.Plane{
    //     .{
    //         .e0 = plane_distance_from_origin / 2,
    //         .e1 = 1,
    //         .e2 = 0,
    //         .e3 = 0,
    //     },
    //     .{
    //         .e0 = plane_distance_from_origin / 2,
    //         .e1 = 0,
    //         .e2 = 1,
    //         .e3 = 0,
    //     },
    //     .{
    //         .e0 = plane_distance_from_origin / 2,
    //         .e1 = 0,
    //         .e2 = 0,
    //         .e3 = 1,
    //     },
    //     .{
    //         .e0 = plane_distance_from_origin / 2,
    //         .e1 = -1,
    //         .e2 = 0,
    //         .e3 = 0,
    //     },
    //     .{
    //         .e0 = plane_distance_from_origin / 2,
    //         .e1 = 0,
    //         .e2 = -1,
    //         .e3 = 0,
    //     },
    //     .{
    //         .e0 = plane_distance_from_origin / 2,
    //         .e1 = 0,
    //         .e2 = 0,
    //         .e3 = -1,
    //     },
    // };
    // _ = planes;
    // _ = color; // autofix
    // _ = plane; // autofix
    // // plane.
}

// pub fn drawSomething(width: u32, height: u32, color: Color) void {
//     for (0..width) |w| {
//         for (height / 2..height) |h| {
//             rl.drawPixel(
//                 @intCast(w),
//                 @intCast(h),
//                 color,
//             );
//         }
//     }
// }

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

// pub fn drawArrow(position: Point, direction: Point, length: f32, headLength: f32, headRadius: f32, lineThickness: f32, color: Color)
// {
//     // Normalize the direction vector
//     Vector3 dirNorm = Vector3Normalize(direction);

//     // Calculate the end position of the arrow shaft
//     Vector3 endPos = Vector3Add(position, Vector3Scale(dirNorm, length - headLength));

//     // Draw the arrow shaft (as a thin cylinder)
//     DrawCylinderEx(position, endPos, lineThickness/2, lineThickness/2, 8, color);

//     // Calculate the position for the arrow head (cone)
//     Vector3 headPos = Vector3Add(endPos, Vector3Scale(dirNorm, headLength/2));

//     // Draw the arrow head (as a cone)
//     DrawCylinderEx(headPos, Vector3Add(headPos, Vector3Scale(dirNorm, headLength)), headRadius, 0, 8, color);
// }
