//! Following ../3D PGA Cheat Sheet.pdf
//!
//! -----------------------------------------------------------------------------------------
//! Plane     perpendicular to   plane p   and containing     line L      p · L
//! Point     intersection of    plane p   and                line L      p ∧ L
//! Line      perpendicular to   plane p   and containing     point P     p · P
//! Distance  (times I) from     point P   towards            plane p     p ∧ P
//! Plane     perpendicular to   line L    and containing     point P     L · P
//! Plane     parallel to        plane p   and containing     point P     (p · P)/P
//! Line      parallel to        line L    and containing     point P     (L · P)/P
//! Point     repositioned from  point X   and placed at      point P     (X · P)/P
//! Plane     projected from     plane p   and containing     line L      (p · L)/L
//! Point     projected from     point P   and lying on       line L      L\(L · P)
//! Point     projected from     point P   and lying on       plane p     p\(p · P)
//! Plane     as reflection of   plane p   in the reflector   point X     −X p/X
//! Line      as reflection of   line L    in the reflector   point X     X L/X
//! Point     as reflection of   point P   in the reflector   point X     −X P/X
//! Line      from               point P   to                 point Q     P ∨ Q
//! Line      from               point P   to direction       V_u         P ∨ Vu
//! Plane     through            points    P, Q, R                        P ∨ Q ∨ R
//! Distance  between            point P   and                point Q     ‖P ∨ Q‖
//! Chirality (times I) between  line L    and                line M      L ∧ M
//! -----------------------------------------------------------------------------------------

const std = @import("std");

const Basis = enum(u2) {
    /// plane at infinity
    e0 = 0,
    /// x plane
    e1 = 1,
    /// y plane
    e2 = 2,
    /// z plane
    e3 = 3,

    pub fn squared(b: Basis) Sign {
        return switch (b) {
            .e0 => .@"0",
            .e1 => .@"1",
            .e2 => .@"1",
            .e3 => .@"1",
        };
    }
    const pseudo_vector: Blade = &.{ .e0, .e1, .e2, .e3 };
};

pub fn point(x: f32, y: f32, z: f32) primitive.Point {
    return .{
        .e123 = 1,
        .e032 = x,
        .e013 = y,
        .e012 = z,
    };
}

pub fn plane(x: f32, y: f32, z: f32) primitive.Point {
    return .{
        .e0 = 1,
        .e1 = x,
        .e2 = y,
        .e3 = z,
    };
}

pub const primitive = struct {
    pub const Scalar = struct {
        @"1": f32 = 0,
    };

    pub const Plane = struct {
        e0: f32 = 0,

        e1: f32 = 0,
        e2: f32 = 0,
        e3: f32 = 0,
    };

    pub const Line = struct {
        e01: f32 = 0,
        e02: f32 = 0,
        e03: f32 = 0,

        e23: f32 = 0,
        e31: f32 = 0,
        e12: f32 = 0,
    };

    pub const Point = struct {
        e123: f32 = 0,

        /// x
        e032: f32 = 0,
        /// y
        e013: f32 = 0,
        /// z
        e012: f32 = 0,
    };

    /// Also known as `quaternion`
    pub const Rotor = struct {
        @"1": f32 = 0,

        e12: f32 = 0,
        e13: f32 = 0,
        e23: f32 = 0,
    };

    pub const Translator = struct {
        @"1": f32 = 0,

        e01: f32 = 0,
        e02: f32 = 0,
        e03: f32 = 0,
    };

    /// Represents any not deforming motion in 3d.
    /// Also known as dual quaternion.
    pub const Motor = struct {
        @"1": f32 = 0,

        e01: f32 = 0,
        e02: f32 = 0,
        e03: f32 = 0,

        e12: f32 = 0,
        e23: f32 = 0,
        e31: f32 = 0,

        e0123: f32 = 0,
    };

    pub const Multivector = struct {
        @"1": f32 = 0,

        e0: f32 = 0,

        e1: f32 = 0,
        e2: f32 = 0,
        e3: f32 = 0,

        e01: f32 = 0,
        e02: f32 = 0,
        e03: f32 = 0,

        e12: f32 = 0,
        e23: f32 = 0,
        e31: f32 = 0,

        e123: f32 = 0,

        /// x
        e032: f32 = 0,
        /// y
        e013: f32 = 0,
        /// z
        e012: f32 = 0,

        e0123: f32 = 0,
    };
};

const Blade = []const Basis;

fn bladeFromString(comptime str: []const u8) Blade {
    return comptime blk: {
        if (std.mem.eql(u8, str, "1")) break :blk &.{};

        std.debug.assert(str[0] == 'e');
        var blades: Blade = &.{};

        for (str[1..]) |digit| {
            blades = blades ++ &[_]Basis{@enumFromInt(digit - '0')};
        }
        break :blk blades;
    };
}

test bladeFromString {
    try std.testing.expectEqualSlices(Basis, &[_]Basis{ .e1, .e2, .e3 }, bladeFromString("e123"));
    try std.testing.expectEqualSlices(Basis, &[_]Basis{.e0}, bladeFromString("e0"));
    try std.testing.expectEqualSlices(Basis, &[_]Basis{}, bladeFromString("e"));
    try std.testing.expectEqualSlices(Basis, &[_]Basis{ .e1, .e2, .e0, .e3 }, bladeFromString("e1203"));
}

pub fn getFieldNameFromBlade(comptime T: type, comptime blade: Blade) ?struct { Sign, []const u8 } {
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (comptime same(bladeFromString(field.name), blade)) {
            if (sameSign(bladeFromString(field.name), blade)) {
                return .{ .@"1", field.name };
            } else {
                return .{ .@"-1", field.name };
            }
        }
    }

    return null;
}

test getFieldNameFromBlade {
    {
        try std.testing.expectEqual(.@"-1", getFieldNameFromBlade(primitive.Motor, &.{ .e1, .e0 }).?[0]);
        try std.testing.expectEqual(.@"1", getFieldNameFromBlade(primitive.Motor, &.{ .e0, .e2 }).?[0]);
        try std.testing.expectEqual(.@"1", getFieldNameFromBlade(primitive.Motor, &.{ .e0, .e3, .e1, .e2 }).?[0]);
        try std.testing.expectEqual(.@"-1", getFieldNameFromBlade(primitive.Motor, &.{ .e3, .e0, .e1, .e2 }).?[0]);
        try std.testing.expectEqual(@as(?struct { Sign, []const u8 }, null), getFieldNameFromBlade(primitive.Motor, &.{
            .e3,
            .e0,
            .e1,
        }));
    }
}

const Sign = enum(i2) {
    @"-1" = -1,
    @"0" = 0,
    @"1" = 1,

    pub fn float(s: Sign, Float: type) Float {
        return @floatFromInt(@intFromEnum(s));
    }

    pub fn mult(s: Sign, other: Sign) Sign {
        const lhs = @intFromEnum(s);
        const rhs = @intFromEnum(other);
        return @enumFromInt(lhs * rhs);
    }

    test mult {
        try std.testing.expectEqual(Sign.@"0", Sign.@"-1".mult(.@"0"));
        try std.testing.expectEqual(Sign.@"-1", Sign.@"-1".mult(.@"1"));
        try std.testing.expectEqual(Sign.@"1", Sign.@"-1".mult(.@"-1"));
        try std.testing.expectEqual(Sign.@"0", Sign.@"1".mult(.@"0"));
        try std.testing.expectEqual(Sign.@"1", Sign.@"1".mult(.@"1"));
        try std.testing.expectEqual(Sign.@"-1", Sign.@"1".mult(.@"-1"));
        try std.testing.expectEqual(Sign.@"0", Sign.@"0".mult(.@"0"));
        try std.testing.expectEqual(Sign.@"0", Sign.@"0".mult(.@"1"));
        try std.testing.expectEqual(Sign.@"0", Sign.@"0".mult(.@"-1"));
    }
};

const ChangedSign = enum {
    changed,
    unchanged,
};

fn sortGetSign(order: []Basis) Sign {
    const CountSwaps = struct {
        items: []Basis,
        swap_counter: *usize,

        pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            return @intFromEnum(ctx.items[a]) < @intFromEnum(ctx.items[b]);
        }

        pub fn swap(ctx: @This(), a: usize, b: usize) void {
            // Insertion sort always swaps elements near each other.
            std.debug.assert(a - b == 1);
            ctx.swap_counter.* += 1;
            return std.mem.swap(Basis, &ctx.items[a], &ctx.items[b]);
        }
    };
    var swaps: usize = 0;
    std.sort.insertionContext(
        0,
        order.len,
        CountSwaps{
            .swap_counter = &swaps,
            .items = order,
        },
    );
    return if (swaps % 2 == 0) .@"1" else .@"-1";
}

/// Figuers out will sign change if you reorder `first_order` to `second_order`
/// Asserts set of elements in first slice is same as in second.
fn sameSign(comptime first_order: []const Basis, comptime second_order: []const Basis) bool {
    std.debug.assert(same(first_order, second_order));
    var first_array = first_order[0..first_order.len].*;
    var second_array = second_order[0..second_order.len].*;

    return sortGetSign(&first_array) == sortGetSign(&second_array);
}

test sameSign {
    {
        const first = [_]Basis{ .e0, .e1, .e2 };
        const second = [_]Basis{ .e0, .e1, .e2 };

        try std.testing.expect(sameSign(&first, &second));
    }
    {
        const first = [_]Basis{ .e0, .e1, .e2 };
        const second = [_]Basis{ .e0, .e2, .e1 };

        try std.testing.expect(!sameSign(&first, &second));
    }
    {
        const first = [_]Basis{ .e0, .e2, .e3 };
        const second = [_]Basis{ .e3, .e2, .e0 };

        try std.testing.expect(!sameSign(&first, &second));
    }
    try std.testing.expect(sameSign(&.{}, &.{}));
}

/// Checks if set of elements in list is the same ignoring order.
fn same(first_order: []const Basis, second_order: []const Basis) bool {
    if (first_order.len != second_order.len) return false;

    return basisListToEnumSet(first_order).eql(basisListToEnumSet(second_order));
}

fn basisListToEnumSet(list: []const Basis) std.EnumSet(Basis) {
    var set: std.EnumSet(Basis) = .initEmpty();

    for (list) |element| {
        set.insert(element);
    }
    return set;
}

test same {
    try std.testing.expect(same(&.{}, &.{}));
    {
        const first = [_]Basis{ .e0, .e1, .e2 };
        const second = [_]Basis{ .e0, .e1, .e2 };

        try std.testing.expect(same(&first, &second));
    }
    {
        const first = [_]Basis{ .e0, .e1, .e2 };
        const second = [_]Basis{ .e0, .e2, .e1 };

        try std.testing.expect(same(&first, &second));
    }
    {
        const first = [_]Basis{ .e0, .e2, .e3 };
        const second = [_]Basis{ .e3, .e2, .e0 };

        try std.testing.expect(same(&first, &second));
    }
    {
        const first = [_]Basis{ .e0, .e2, .e3 };
        const second = [_]Basis{ .e3, .e2, .e1 };

        try std.testing.expect(!same(&first, &second));
    }
}

pub fn containsBlade(comptime T: type, blade: Blade) bool {
    for (@typeInfo(T).@"struct".fields) |field| {
        if (same(bladeFromString(field.name), blade)) return true;
    }
    return false;
}

pub fn SelectTypeContainingBlades(blades: []const Blade, types: []const type) type {
    type: for (types) |@"type"| {
        for (blades) |blade| {
            if (!containsBlade(@"type", blade)) continue :type;
        }
        return @"type";
    }
}

pub fn typesFromNamespace(namespace: type) []const type {
    return comptime blk: {
        var types: []const type = &.{};
        for (@typeInfo(namespace).@"struct".decls) |decl| {
            types = types ++ &[1]type{@field(namespace, decl.name)};
        }
        break :blk types;
    };
}

pub fn collapseBlade(slice: []Basis) ?[]Basis {
    if (slice.len <= 1) return slice;

    var write_index: usize = 0;
    var read_index: usize = 0;
    while (read_index + 1 < slice.len) {
        const elem = slice[read_index];
        const next = slice[read_index + 1];
        if (elem == next) {
            switch (elem.squared()) {
                .@"-1", .@"1" => read_index += 2,
                .@"0" => return null,
            }
        } else {
            slice[write_index] = slice[read_index];
            write_index += 1;
            read_index += 1;
        }
    }
    if (read_index + 1 == slice.len and slice[read_index] != slice[read_index - 1]) {
        slice[write_index] = slice[read_index];
        write_index += 1;
    }
    return slice[0..write_index];
}

test collapseBlade {
    try std.testing.expectEqualSlices(Basis, &.{}, collapseBlade(&.{}).?);
    {
        var array: [1]Basis = .{.e0};
        try std.testing.expectEqualSlices(Basis, &.{.e0}, collapseBlade(&array).?);
    }
    {
        var array: [2]Basis = .{ .e0, .e0 };
        try std.testing.expectEqual(@as(?[]Basis, null), collapseBlade(&array));
    }
    {
        var array: [2]Basis = .{ .e0, .e1 };
        try std.testing.expectEqualSlices(Basis, &.{ .e0, .e1 }, collapseBlade(&array).?);
    }
    {
        var array: [4]Basis = .{ .e0, .e1, .e2, .e3 };
        try std.testing.expectEqualSlices(Basis, &.{ .e0, .e1, .e2, .e3 }, collapseBlade(&array).?);
    }
    {
        var array: [2]Basis = .{ .e1, .e1 };
        try std.testing.expectEqualSlices(Basis, &.{}, collapseBlade(&array).?);
    }
    {
        var array: [6]Basis = .{ .e1, .e2, .e1, .e2, .e3, .e3 };
        try std.testing.expectEqualSlices(Basis, &.{ .e1, .e2, .e1, .e2 }, collapseBlade(&array).?);
    }
    {
        var array: [6]Basis = .{ .e0, .e0, .e1, .e2, .e3, .e3 };
        try std.testing.expectEqual(@as(?[]Basis, null), collapseBlade(&array));
    }
}

pub fn BladeProduct(lhs: Blade, rhs: Blade) ?struct { Sign, Blade } {
    var both = blk: {
        const both: Blade = lhs ++ rhs;
        break :blk both[0..both.len].*;
    };
    const sign = sortGetSign(&both);

    return .{ sign, collapseBlade(&both) orelse return null };
}

pub fn GeometricProduct(Left: type, Right: type) type {
    @setEvalBranchQuota(100000);
    comptime {
        var blades: []const Blade = &.{};
        for (@typeInfo(Left).@"struct".fields) |left| {
            for (@typeInfo(Right).@"struct".fields) |right| {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);

                blades = blades ++ &[1]Blade{(BladeProduct(left_list, right_list) orelse continue)[1]};
            }
        }
        return SelectTypeContainingBlades(
            blades,
            typesFromNamespace(primitive),
        );
    }
}

test GeometricProduct {
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Motor, primitive.Motor));
    try std.testing.expectEqual(primitive.Translator, GeometricProduct(primitive.Translator, primitive.Translator));
    try std.testing.expectEqual(primitive.Rotor, GeometricProduct(primitive.Rotor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Motor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Translator, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Plane, primitive.Plane));
}

pub fn geometricProduct(lhs: anytype, rhs: anytype) GeometricProduct(@TypeOf(lhs), @TypeOf(rhs)) {
    const Left = @TypeOf(lhs);
    const Right = @TypeOf(rhs);

    const Result = GeometricProduct(@TypeOf(lhs), @TypeOf(rhs));

    var result: Result = .{};
    inline for (@typeInfo(Left).@"struct".fields) |left| {
        inline for (@typeInfo(Right).@"struct".fields) |right| {
            const sign, const result_field_name = comptime sign: {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);
                const sign, const result_blade = BladeProduct(left_list, right_list) orelse continue;

                const sign2, const result_field_name = getFieldNameFromBlade(Result, result_blade).?;
                break :sign .{ sign.mult(sign2), result_field_name };
            };

            switch (sign) {
                .@"1" => @field(result, result_field_name) = @mulAdd(
                    f32,
                    @field(lhs, left.name),
                    @field(rhs, right.name),
                    @field(result, result_field_name),
                ),
                .@"-1" => @field(result, result_field_name) = @mulAdd(
                    f32,
                    @field(lhs, left.name),
                    -@field(rhs, right.name),
                    @field(result, result_field_name),
                ),
                else => comptime unreachable,
            }
        }
    }
    return result;
}

test geometricProduct {
    try std.testing.expectEqual(primitive.Scalar{ .@"1" = 1 }, geometricProduct(.{
        .e1 = 1,
    }, .{
        .e1 = 1,
    }));
    try std.testing.expectEqual(primitive.Scalar{ .@"1" = -10 }, geometricProduct(.{
        .e1 = 1,
    }, .{
        .e1 = -10,
    }));

    {
        // spawing operands changes result
        try std.testing.expectEqual(primitive.Plane{
            .e1 = -10,
            .e0 = -1,
        }, geometricProduct(
            .{
                .e1 = 1,
            },
            .{
                .@"1" = -10,
                .e01 = 1,
            },
        ));
        try std.testing.expectEqual(primitive.Plane{
            .e1 = -10,
            .e0 = 1,
        }, geometricProduct(
            .{
                .@"1" = -10,
                .e01 = 1,
            },
            .{
                .e1 = 1,
            },
        ));
    }
    {
        // can swap numbers in field names to flip sign
        try std.testing.expectEqual(primitive.Point{
            .e012 = 1,
        }, geometricProduct(
            .{
                .e12 = 1,
            },
            .{
                .e0 = 1,
            },
        ));
        try std.testing.expectEqual(primitive.Point{
            .e012 = -1,
        }, geometricProduct(
            .{
                .e21 = 1,
            },
            .{
                .e0 = 1,
            },
        ));
    }
}

pub fn reduce(comptime T: type, value: anytype) T {
    var result: T = .{};
    inline for (@typeInfo(@TypeOf(value)).@"struct".fields) |field| {
        const blades = comptime bladeFromString(field.name);
        const sign, const field_name = comptime getFieldNameFromBlade(T, blades) orelse continue;

        @field(result, field_name) = sign.float(f32) * @field(value, field.name);
    }
    return result;
}

test reduce {
    try std.testing.expectEqual(primitive.Translator{
        .@"1" = 1,
        .e01 = 1,
    }, reduce(primitive.Translator, primitive.Motor{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }));
    try std.testing.expectEqual(primitive.Translator{
        .@"1" = 1,
        .e01 = 0,
    }, reduce(primitive.Translator, .{
        .@"1" = 1,
    }));
}

/// Changes sign of every basis vector in multivector.
///
/// For blades with even number of basis vector it is nope.
pub fn involute(value: anytype) @TypeOf(value) {
    var copy = value;
    inline for (@typeInfo(@TypeOf(value)).@"struct".fields) |field| {
        if (comptime bladeFromString(field.name).len % 2 == 1) {
            @field(copy, field.name) *= -1;
        }
    }
    return copy;
}

test involute {
    try std.testing.expectEqual(primitive.Motor{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }, involute(primitive.Motor{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }));
    try std.testing.expectEqual(primitive.Point{
        .e012 = -1,
        .e013 = -1,
        .e123 = 1,
    }, involute(primitive.Point{
        .e012 = 1,
        .e013 = 1,
        .e123 = -1,
    }));
}

/// Flips basis vectors order in blades.
///
/// Effect is changing sign of bivector and trivector part.
pub fn reverse(value: anytype) @TypeOf(value) {
    var copy = value;
    inline for (@typeInfo(@TypeOf(value)).@"struct".fields) |field| {
        const same_sign = comptime blk: {
            const blade = bladeFromString(field.name);
            var reversed = blade[0..blade.len].*;

            std.mem.reverse(Basis, &reversed);
            break :blk sameSign(blade, &reversed);
        };
        if (comptime !same_sign) {
            @field(copy, field.name) *= -1;
        }
    }
    return copy;
}

test reverse {
    try std.testing.expectEqual(primitive.Motor{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = -1,
    }, reverse(primitive.Motor{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }));
    try std.testing.expectEqual(primitive.Point{
        .e012 = -1,
        .e013 = -1,
        .e123 = 1,
    }, reverse(primitive.Point{
        .e012 = 1,
        .e013 = 1,
        .e123 = -1,
    }));
    const random_point: primitive.Point = .{
        .e012 = 1,
        .e013 = 1,
        .e123 = -1,
    };

    try std.testing.expectEqual(primitive.Translator{ .@"1" = 1 }, geometricProduct(random_point, reverse(random_point)));
    try std.testing.expectEqual(primitive.Motor{ .@"1" = 3 }, geometricProduct(primitive.Plane{
        .e0 = 1,
        .e1 = 1,
        .e2 = 1,
        .e3 = 1,
    }, reverse(primitive.Plane{
        .e0 = 1,
        .e1 = 1,
        .e2 = 1,
        .e3 = 1,
    })));
}

pub fn norm(value: anytype) f32 {
    const result = geometricProduct(value, reverse(value));

    return @sqrt(result.@"1");
}

test norm {
    try std.testing.expectEqual(@sqrt(@as(f32, 119)), norm(primitive.Motor{
        .@"1" = 10,
        .e12 = 3,
        .e31 = 1,
        .e03 = 0,
        .e23 = 3,
        .e01 = 1,
        .e02 = 3,
        .e0123 = 3,
    }));
}

pub fn iNorm(value: anytype) f32 {
    @setEvalBranchQuota(10000);
    const dual_value = dual(value);
    const result = geometricProduct(dual_value, reverse(dual_value));

    return @sqrt(result.@"1");
}

test iNorm {
    try std.testing.expectEqual(@sqrt(@as(f32, 0)), iNorm(.{
        .e1 = 1,
    }));
    try std.testing.expectEqual(@sqrt(@as(f32, 1)), iNorm(.{
        .e0 = 1,
    }));
}

fn xorBlade(comptime values: Blade, comptime blade: Blade) Blade {
    return comptime blk: {
        std.debug.assert(values.len <= blade.len);
        find: for (values) |value| {
            for (blade) |b| {
                if (b == value) continue :find;
            }
            // TODO: give better error message
            std.debug.print("uses value outside of allowed range", .{});
        }

        var result: Blade = &.{};
        find: for (blade) |b| {
            for (values) |v| {
                if (b == v) continue :find;
            }

            result = result ++ &[1]Basis{b};
        }

        break :blk result;
    };
}

test xorBlade {
    try std.testing.expectEqualSlices(
        Basis,
        &.{ .e0, .e2, .e3 },
        xorBlade(&.{.e1}, &.{ .e0, .e1, .e2, .e3 }),
    );
    try std.testing.expectEqualSlices(
        Basis,
        &.{ .e0, .e1, .e2, .e3 },
        xorBlade(&.{}, &.{ .e0, .e1, .e2, .e3 }),
    );
    try std.testing.expectEqualSlices(
        Basis,
        &.{},
        xorBlade(&.{ .e0, .e1, .e2, .e3 }, &.{ .e0, .e1, .e2, .e3 }),
    );
}

fn DualWithBasis(comptime T: type, comptime base: Blade) type {
    var blades: []const Blade = &.{};
    for (@typeInfo(T).@"struct".fields) |field| {
        blades = blades ++ &[1]Blade{xorBlade(bladeFromString(field.name), base)};
    }
    return SelectTypeContainingBlades(
        blades,
        typesFromNamespace(primitive),
    );
}

test DualWithBasis {
    try std.testing.expectEqual(
        primitive.Plane,
        DualWithBasis(
            primitive.Point,
            Basis.pseudo_vector,
        ),
    );
}

pub fn dual(value: anytype) DualWithBasis(
    @TypeOf(value),
    Basis.pseudo_vector,
) {
    @setEvalBranchQuota(10000);
    var result: DualWithBasis(@TypeOf(value), Basis.pseudo_vector) = .{};
    inline for (@typeInfo(@TypeOf(value)).@"struct".fields) |field| {
        const blade = comptime bladeFromString(field.name);
        const xor = comptime xorBlade(bladeFromString(field.name), Basis.pseudo_vector);
        const sign, const field_name = comptime getFieldNameFromBlade(@TypeOf(result), xor) orelse continue;
        if (comptime sameSign(blade ++ xor, Basis.pseudo_vector) == (sign == .@"1")) {
            @field(result, field_name) = @field(value, field.name);
        } else {
            @field(result, field_name) = -@field(value, field.name);
        }
    }

    return result;
}

test dual {
    try std.testing.expectEqual(primitive.Motor{
        .e0123 = 1,
    }, geometricProduct(
        primitive.Plane{
            .e0 = 1,
        },
        dual(primitive.Plane{
            .e0 = 1,
        }),
    ));
    try std.testing.expectEqual(primitive.Motor{
        .e0123 = 1,
    }, geometricProduct(
        primitive.Plane{
            .e1 = 1,
        },
        dual(primitive.Plane{
            .e1 = 1,
        }),
    ));
    try std.testing.expectEqual(primitive.Motor{
        .e0123 = 1,
    }, geometricProduct(
        primitive.Plane{
            .e2 = 1,
        },
        dual(primitive.Plane{
            .e2 = 1,
        }),
    ));
    try std.testing.expectEqual(primitive.Motor{
        .e0123 = 1,
    }, geometricProduct(
        primitive.Plane{
            .e3 = 1,
        },
        dual(primitive.Plane{
            .e3 = 1,
        }),
    ));
    try std.testing.expectEqual(primitive.Motor{
        .e0123 = 1,
    }, geometricProduct(
        primitive.Line{
            .e12 = 1,
        },
        dual(primitive.Line{
            .e12 = 1,
        }),
    ));
    try std.testing.expectEqual(primitive.Motor{
        .e0123 = 1,
    }, geometricProduct(
        .{
            .@"1" = 1,
        },
        dual(.{
            .@"1" = 1,
        }),
    ));
}

export fn absDiff(a: usize, b: usize) usize {
    return @max(a, b) - @min(a, b);
}

pub fn InnerProduct(Left: type, Right: type) type {
    @setEvalBranchQuota(100000);
    comptime {
        var blades: []const Blade = &.{};
        for (@typeInfo(Left).@"struct".fields) |left| {
            for (@typeInfo(Right).@"struct".fields) |right| {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);
                const chosen_len = absDiff(left_list.len, right_list.len);
                const blade = (BladeProduct(left_list, right_list) orelse continue)[1];
                if (chosen_len != blade.len) continue;

                blades = blades ++ &[1]Blade{blade};
            }
        }
        return SelectTypeContainingBlades(
            blades,
            typesFromNamespace(primitive),
        );
    }
}

test InnerProduct {
    try std.testing.expectEqual(primitive.Scalar, InnerProduct(primitive.Point, primitive.Point));
}

pub fn innerProduct(lhs: anytype, rhs: anytype) InnerProduct(@TypeOf(lhs), @TypeOf(rhs)) {
    const Left = @TypeOf(lhs);
    const Right = @TypeOf(rhs);

    const Result = InnerProduct(@TypeOf(lhs), @TypeOf(rhs));

    var result: Result = .{};
    inline for (@typeInfo(Left).@"struct".fields) |left| {
        inline for (@typeInfo(Right).@"struct".fields) |right| {
            const sign, const result_field_name = comptime sign: {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);
                const chosen_len = absDiff(left_list.len, right_list.len);
                const sign, const result_blade = BladeProduct(left_list, right_list) orelse continue;
                if (chosen_len != result_blade.len) continue;

                const sign2, const result_field_name = getFieldNameFromBlade(Result, result_blade).?;
                break :sign .{ sign.mult(sign2), result_field_name };
            };

            switch (sign) {
                .@"1" => @field(result, result_field_name) = @mulAdd(
                    f32,
                    @field(lhs, left.name),
                    @field(rhs, right.name),
                    @field(result, result_field_name),
                ),
                .@"-1" => @field(result, result_field_name) = @mulAdd(
                    f32,
                    @field(lhs, left.name),
                    -@field(rhs, right.name),
                    @field(result, result_field_name),
                ),
                else => comptime unreachable,
            }
        }
    }
    return result;
}

test innerProduct {
    // (e123 + e012 + 10e201 + 10) | (e123) = −1+10e123
    try std.testing.expectEqual(primitive.Multivector{
        .@"1" = -1,
        .e123 = 10,
    }, innerProduct(.{
        .e123 = 1,
        .e012 = 1,
        .e201 = 10,
        .@"1" = 10,
    }, .{
        .e123 = 1,
    }));
}
