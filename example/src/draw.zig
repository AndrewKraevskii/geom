const geo = @import("geo");
const sandwich = geo.sandwich;
const project = geo.orhogonalProjection;
const mult = geo.geometricProduct;
const join = geo.join;
const meet = geo.meet;
const rl = @import("raylib");
const Color = rl.Color;

const origin: geo.primitive.Point = .{
    .e123 = 1,
    .e032 = 0,
    .e013 = 0,
    .e012 = 0,
};

pub fn point(p: geo.primitive.Point, color: Color) void {
    const vec: rl.Vector3 = .{
        .x = p.e032 / p.e123,
        .y = p.e013 / p.e123,
        .z = p.e012 / p.e123,
    };
    rl.drawSphere(vec, 1, color);
}

const plane_distance_from_origin = 10;
const line_len = 100;

pub fn line(l: geo.primitive.Line, color: Color) void {
    var _plane = geo.normalized(geo.innerProduct(
        origin,
        l,
    ));
    _plane.e0 = line_len;
    const start = meet(_plane, l);
    _plane.e0 *= -1;
    const end = meet(_plane, l);

    lineSegment(start, end, color);
}

pub fn plane(p: geo.primitive.Plane, color: Color) void {
    const vertical_line = geo.primitive.Line{
        .e31 = 1,
    };

    const line_on_plane = project(vertical_line, p);
    line(line_on_plane, color);

    var horisontal_plane_down = geo.normalized(join(line_on_plane, origin));
    horisontal_plane_down.e0 = plane_distance_from_origin / 2;
    var horisontal_plane_up = horisontal_plane_down;
    horisontal_plane_up.e0 *= -1;

    var vertical_plane_left = geo.normalized(geo.innerProduct(line_on_plane, origin));
    vertical_plane_left.e0 = plane_distance_from_origin / 2;
    var vertical_plane_right = vertical_plane_left;
    vertical_plane_right.e0 *= -1;

    const points = [_]geo.primitive.Point{
        meet(meet(horisontal_plane_up, vertical_plane_left), p),
        meet(meet(horisontal_plane_down, vertical_plane_left), p),
        meet(meet(horisontal_plane_up, vertical_plane_right), p),
        meet(meet(horisontal_plane_down, vertical_plane_right), p),
    };
    triangle(points[0..3].*, color.alpha(0.5));
    triangle(points[1..4].*, color.alpha(0.5));
}

pub fn motor(_motor: geo.primitive.Motor, color: Color) void {
    line(geo.reduce(geo.primitive.Line, _motor), color);
}

pub fn lineSegment(start: geo.primitive.Point, end: geo.primitive.Point, color: Color) void {
    rl.drawLine3D(toRaylibPoint(start), toRaylibPoint(end), color);
}

pub fn toRaylibPoint(p: geo.primitive.Point) rl.Vector3 {
    return .{
        .x = p.e032 / p.e123,
        .y = p.e013 / p.e123,
        .z = p.e012 / p.e123,
    };
}

pub fn triangle(points: [3]geo.primitive.Point, color: Color) void {
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

pub fn arrow(position: geo.primitive.Point, end: geo.primitive.Point, headPart: f32, headRadius: f32, lineThickness: f32, color: Color) void {
    const headPos = geo.lerp(
        geo.normalized(position),
        geo.normalized(end),
        headPart,
    );
    rl.drawCylinderEx(toRaylibPoint(position), toRaylibPoint(headPos), lineThickness / 2, lineThickness / 2, 8, color);

    rl.drawCylinderEx(toRaylibPoint(headPos), toRaylibPoint(end), headRadius, 0, 8, color);
}
