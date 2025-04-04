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
                @floatCast(@abs(@mod(rl.getTime(), 2) - 1)),
            );
            const green_point = sandwich(mult(white_line, pink_line), red_point);
            const yellow_point = project(white_line, red_point);

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
            drawArrow(origin, .{
                .e123 = 1,
                .e023 = 0,
                .e013 = 5,
                .e012 = 0,
            }, 0.9, 0.4, 0.4, .gray);
            const dual_plane = geo.dual(blue_point);
            drawPlane(dual_plane, .blue);
            const plane = geo.Plane{
                .e0 = 3,
                .e1 = 3,
                .e2 = 1,
                .e3 = 1,
            };
            drawPlane(plane, .dark_blue);
            drawLine(meet(plane, dual_plane), .white);
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
const line_len = 100;

pub fn drawLine(line: geo.Line, color: Color) void {
    var plane = geo.normalized(geo.innerProduct(
        origin,
        line,
    ));
    plane.e0 = line_len;
    const start = meet(plane, line);
    plane.e0 *= -1;
    const end = meet(plane, line);

    drawLineSegment(start, end, color);
}

pub fn drawPlane(plane: geo.Plane, color: Color) void {
    const vertical_line = geo.Line{
        .e01 = 0,
        .e02 = 0,
        .e03 = 0,

        .e12 = 0,
        .e13 = 1,
        .e23 = 0,
    };

    const line_on_plane = project(plane, vertical_line);
    drawLine(line_on_plane, color);

    var horisontal_plane_down = geo.normalized(join(line_on_plane, origin));
    horisontal_plane_down.e0 = plane_distance_from_origin / 2;
    var horisontal_plane_up = horisontal_plane_down;
    horisontal_plane_up.e0 *= -1;

    var vertical_plane_left = geo.normalized(geo.innerProduct(line_on_plane, origin));
    vertical_plane_left.e0 = plane_distance_from_origin / 2;
    var vertical_plane_right = vertical_plane_left;
    vertical_plane_right.e0 *= -1;

    const points = [_]geo.Point{
        meet(meet(horisontal_plane_up, vertical_plane_left), plane),
        meet(meet(horisontal_plane_down, vertical_plane_left), plane),
        meet(meet(horisontal_plane_up, vertical_plane_right), plane),
        meet(meet(horisontal_plane_down, vertical_plane_right), plane),
    };
    drawTriangle(points[0..3].*, color.alpha(0.5));
    drawTriangle(points[1..4].*, color.alpha(0.5));
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

pub fn drawArrow(position: Point, end: Point, headPart: f32, headRadius: f32, lineThickness: f32, color: Color) void {
    const headPos = geo.lerp(
        geo.normalized(position),
        geo.normalized(end),
        headPart,
    );
    rl.drawCylinderEx(toRaylibPoint(position), toRaylibPoint(headPos), lineThickness / 2, lineThickness / 2, 8, color);

    rl.drawCylinderEx(toRaylibPoint(headPos), toRaylibPoint(end), headRadius, 0, 8, color);
}
