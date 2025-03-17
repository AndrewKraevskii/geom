const std = @import("std");

const geo = @import("geo");
const MV = geo.Multivector;
const Vec2 = geo.Vec2;
const rl = @import("raylib");
const Color = rl.Color;

pub fn main() !void {
    rl.initWindow(720, 480, "geo math");
    defer rl.closeWindow();

    var camera: rl.Camera2D = .{
        .target = .zero(),
        .offset = .{ .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2, .y = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2 },
        .zoom = 1,
        .rotation = 0,
    };

    var start_vec: MV = MV.one(.e1).scale(100).add(MV.one(.e2));
    var end_vec: MV = MV.one(.e1).add(MV.one(.e2).scale(100));

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        camera.begin();
        defer camera.end();

        drawAxis(0, 0, 1000, .red);
        rl.drawText("geo math", 0, 0, 10, .red);

        const vec = rl.getScreenToWorld2D(rl.getMousePosition(), camera);

        const mouse_pos: MV = MV.point(vec.x, vec.y, 0);

        if (rl.isMouseButtonDown(.left)) {
            start_vec = mouse_pos;
        } else if (rl.isMouseButtonDown(.right)) {
            end_vec = mouse_pos;
        }

        const bivec = start_vec.mul(end_vec);
        std.debug.print("{d}\n", .{bivec.get(.e3)});

        drawBivectorAt(start_vec, end_vec, .zero, .blue, .white);

        drawVector(start_vec, .red);
        drawVector(end_vec, .blue);

        {
            const flip_around = end_vec.join(.point(0, 0, 0)).normalized();
            // const flip_around = end_vec;
            const reflected = flip_around.mul(start_vec).mul(flip_around.reverse());
            drawVector(reflected, .green);
        }
    }
}

pub fn drawVector(vec: MV, color: Color) void {
    drawVectorAt(vec, .zero, color);
}

pub fn drawVectorAt(vec: MV, pos: MV, color: Color) void {
    rl.drawLineV(@bitCast(pos.getVec3()[0..2].*), @bitCast(pos.add(vec).getVec3()[0..2].*), color);
}

pub fn drawBivectorAt(start: MV, end: MV, pos: Vec2, fill_color: Color, outline_color: Color) void {
    const s: Vec2 = @bitCast(start.getVec3()[0..2].*);
    const e: Vec2 = @bitCast(end.getVec3()[0..2].*);

    if (s.x * e.y - s.y * e.x >= 0) {
        rl.drawTriangle(@bitCast(pos.add(s)), @bitCast(pos), @bitCast(pos.add(s).add(e)), fill_color);
        rl.drawTriangle(@bitCast(pos), @bitCast(pos.add(e)), @bitCast(pos.add(s).add(e)), fill_color);
    } else {
        rl.drawTriangle(@bitCast(pos), @bitCast(pos.add(s)), @bitCast(pos.add(s).add(e)), fill_color);
        rl.drawTriangle(@bitCast(pos.add(e)), @bitCast(pos), @bitCast(pos.add(s).add(e)), fill_color);
    }
    rl.drawLineV(@bitCast(pos), @bitCast(pos.add(s)), outline_color);
    rl.drawLineV(@bitCast(pos), @bitCast(pos.add(e)), outline_color);
    rl.drawLineV(@bitCast(pos.add(s)), @bitCast(pos.add(s).add(e)), outline_color);
    rl.drawLineV(@bitCast(pos.add(e)), @bitCast(pos.add(s).add(e)), outline_color);
}

pub fn drawAxis(x: f32, y: f32, size: f32, color: Color) void {
    rl.drawLineV(.{ .x = x, .y = y - size / 2 }, .{ .x = x, .y = y + size / 2 }, color);
    rl.drawLineV(.{ .x = x - size / 2, .y = y }, .{ .x = x + size / 2, .y = y }, color);
}
