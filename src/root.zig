const std = @import("std");

pub const Vec2 = extern struct {
    x: f32,
    y: f32,

    pub const zero: Vec2 = .{ .x = 0, .y = 0 };

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return .{
            .x = a.x + b.x,
            .y = a.y + b.y,
        };
    }

    pub fn sub(a: Vec2, b: Vec2) Vec2 {
        return .{
            .x = a.x - b.x,
            .y = a.y - b.y,
        };
    }

    pub fn mul(a: Vec2, b: Vec2) Vec2 {
        return .{
            .x = a.x * b.x,
            .y = a.y * b.y,
        };
    }

    pub fn scale(v: Vec2, s: f32) Vec2 {
        return v.mul(.{ .x = s, .y = s });
    }

    pub fn normalize(v: Vec2) Vec2 {
        return v.scale(1 / v.mag());
    }

    pub fn mag(v: Vec2) f32 {
        return @sqrt(v.magSq());
    }

    pub fn magSq(v: Vec2) f32 {
        return v.x * v.x + v.y * v.y;
    }

    pub fn innerProd(a: Vec2, b: Vec2) f32 {
        return @mulAdd(f32, a.x, b.x, a.y * b.y);
    }

    pub fn outerProd(a: Vec2, b: Vec2) Bivec2 {
        return .{ .xy = @mulAdd(f32, a.x, b.x, -a.y * b.y) };
    }

    pub fn geomProd(lhs: Vec2, rhs: Vec2) Rotor2 {
        return .{
            .xy = lhs.outerProd(rhs).xy,
            .a = lhs.innerProd(rhs),
        };
    }
};

pub const Bivec2 = extern struct {
    xy: f32,
};

pub const Rotor2 = extern struct {
    xy: f32,
    a: f32,
};

pub const Multivector = @import("multivector.zig").Multivector;
