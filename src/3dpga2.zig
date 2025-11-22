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
        .e021 = z,
    };
}

pub const primitive = struct {
    pub const Scalar = struct {
        @"1": f32 = 0,
    };

    pub const Pseudoscalar = struct {
        e0123: f32 = 0,
    };

    pub const i: Pseudoscalar = .{
        .e0123 = 1,
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
        e021: f32 = 0,
    };

    /// Also known as `quaternion`
    pub const Rotor = struct {
        @"1": f32 = 0,

        e12: f32 = 0,
        e31: f32 = 0,
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
        e021: f32 = 0,

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
            if (@TypeOf(@field(namespace, decl.name)) != type) continue;
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
    comptime {
        return Product(Left, Right, .geometric);
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

pub fn sqrt(value: anytype) @TypeOf(value) {
    const n = normalized(value);

    return add(n, .{ .@"1" = 1 });
}

test sqrt {
    const motor = primitive.Motor{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    };
    const sqrt_of_motor = sqrt(motor);

    try expectApproxEqualRel(motor, normalized(geometricProduct(sqrt_of_motor, sqrt_of_motor)), 0.000001);
}

pub fn geometricProduct(lhs: anytype, rhs: anytype) GeometricProduct(@TypeOf(lhs), @TypeOf(rhs)) {
    return product(lhs, rhs, .geometric);
}

test geometricProduct {
    try expectEqual(.{ .@"1" = 1 }, geometricProduct(.{
        .e1 = 1,
    }, .{
        .e1 = 1,
    }));
    try expectEqual(.{ .@"1" = -10 }, geometricProduct(.{
        .e1 = 1,
    }, .{
        .e1 = -10,
    }));

    {
        // spawing operands changes result
        try expectEqual(.{
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
        try expectEqual(.{
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
        try expectEqual(.{
            .e012 = 1,
        }, geometricProduct(
            .{
                .e12 = 1,
            },
            .{
                .e0 = 1,
            },
        ));
        try expectEqual(.{
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
    @setEvalBranchQuota(10000);
    var result: T = .{};
    inline for (@typeInfo(@TypeOf(value)).@"struct".fields) |field| {
        const blades = comptime bladeFromString(field.name);
        const sign, const field_name = comptime getFieldNameFromBlade(T, blades) orelse continue;

        @field(result, field_name) = sign.float(f32) * @field(value, field.name);
    }
    return result;
}

test reduce {
    try expectEqual(.{
        .@"1" = 1,
        .e01 = 1,
    }, reduce(primitive.Translator, .{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }));
    try expectEqual(.{
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
    try expectEqual(.{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }, involute(.{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }));
    try expectEqual(.{
        .e012 = -1,
        .e013 = -1,
        .e123 = 1,
    }, involute(primitive.Point{
        .e021 = -1,
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
    try expectEqual(.{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = -1,
    }, reverse(primitive.Motor{
        .@"1" = 1,
        .e0123 = 1,
        .e01 = 1,
    }));
    try expectEqual(.{
        .e012 = -1,
        .e013 = -1,
        .e123 = 1,
    }, reverse(primitive.Point{
        .e021 = -1,
        .e013 = 1,
        .e123 = -1,
    }));
    const random_point: primitive.Point = .{
        .e021 = -1,
        .e013 = 1,
        .e123 = -1,
    };

    try expectEqual(.{ .@"1" = 1 }, geometricProduct(random_point, reverse(random_point)));
    try expectEqual(.{ .@"1" = 3 }, geometricProduct(.{
        .e0 = 1,
        .e1 = 1,
        .e2 = 1,
        .e3 = 1,
    }, reverse(.{
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
    @setEvalBranchQuota(100000);
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
    @setEvalBranchQuota(100000);
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

pub fn iDual(value: anytype) DualWithBasis(
    @TypeOf(value),
    Basis.pseudo_vector,
) {
    @setEvalBranchQuota(10000);
    var result: DualWithBasis(@TypeOf(value), Basis.pseudo_vector) = .{};
    inline for (@typeInfo(@TypeOf(value)).@"struct".fields) |field| {
        const blade = comptime bladeFromString(field.name);
        const xor = comptime xorBlade(bladeFromString(field.name), Basis.pseudo_vector);
        const sign, const field_name = comptime getFieldNameFromBlade(@TypeOf(result), xor) orelse continue;
        if (comptime sameSign(xor ++ blade, Basis.pseudo_vector) == (sign == .@"1")) {
            @field(result, field_name) = @field(value, field.name);
        } else {
            @field(result, field_name) = -@field(value, field.name);
        }
    }

    return result;
}

test dual {
    @setEvalBranchQuota(1000000);
    inline for (@typeInfo(primitive.Multivector).@"struct".fields) |field| {
        var blade: primitive.Multivector = .{};
        @field(blade, field.name) = 1;

        try expectEqual(.{
            .e0123 = 1,
        }, geometricProduct(
            blade,
            dual(blade),
        ));

        try expectEqual(
            blade,
            iDual(dual(blade)),
        );
    }

    try expectEqual(.{
        .e123 = -1,
    }, dual(dual(.{
        .e123 = 1,
    })));
    try expectEqual(.{
        .e123 = 1,
    }, iDual(dual(.{
        .e123 = 1,
    })));

    try expectEqual(.{
        .e1 = -1,
    }, dual(.{
        .e032 = 1,
    }));

    try expectEqual(.{
        .e3 = 1,
    }, dual(.{ .e012 = 1 }));
    try expectEqual(.{
        .e0 = -1,
    }, dual(.{ .e123 = 1 }));
}

export fn absDiff(a: usize, b: usize) usize {
    return @max(a, b) - @min(a, b);
}

pub fn InnerProduct(Left: type, Right: type) type {
    comptime {
        return Product(Left, Right, .inner);
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
    try expectEqual(.{
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

const ProductType = enum {
    geometric,
    inner,
    outer,
};

pub fn Product(Left: type, Right: type, @"type": ProductType) type {
    @setEvalBranchQuota(100000);
    comptime {
        var blades: []const Blade = &.{};
        for (@typeInfo(Left).@"struct".fields) |left| {
            for (@typeInfo(Right).@"struct".fields) |right| {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);
                const blade = (BladeProduct(left_list, right_list) orelse continue)[1];
                switch (@"type") {
                    .inner => {
                        const chosen_len = absDiff(left_list.len, right_list.len);
                        if (chosen_len != blade.len) continue;
                    },
                    .outer => {
                        const chosen_len = left_list.len + right_list.len;
                        if (chosen_len != blade.len) continue;
                    },
                    .geometric => {},
                }

                blades = blades ++ &[1]Blade{blade};
            }
        }
        return SelectTypeContainingBlades(
            blades,
            typesFromNamespace(primitive),
        );
    }
}

test Product {
    try std.testing.expectEqual(primitive.Scalar, Product(primitive.Point, primitive.Point, .inner));
    try std.testing.expectEqual(primitive.Translator, Product(primitive.Point, primitive.Point, .geometric));
    try std.testing.expectEqual(primitive.Point, Product(primitive.Line, primitive.Plane, .outer));
}

fn product(lhs: anytype, rhs: anytype, comptime @"type": ProductType) Product(@TypeOf(lhs), @TypeOf(rhs), @"type") {
    const Left = @TypeOf(lhs);
    const Right = @TypeOf(rhs);

    const Result = Product(@TypeOf(lhs), @TypeOf(rhs), @"type");

    var result: Result = .{};
    inline for (@typeInfo(Left).@"struct".fields) |left| {
        inline for (@typeInfo(Right).@"struct".fields) |right| {
            const sign, const result_field_name = comptime sign: {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);
                const sign, const result_blade = BladeProduct(left_list, right_list) orelse continue;
                switch (@"type") {
                    .inner => {
                        const chosen_len = absDiff(left_list.len, right_list.len);
                        if (chosen_len != result_blade.len) continue;
                    },
                    .outer => {
                        const chosen_len = left_list.len + right_list.len;
                        if (chosen_len != result_blade.len) continue;
                    },
                    .geometric => {},
                }

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

pub fn OuterProduct(Left: type, Right: type) type {
    comptime {
        return Product(Left, Right, .outer);
    }
}

test OuterProduct {
    try std.testing.expectEqual(primitive.Motor, OuterProduct(primitive.Motor, primitive.Motor));
    try std.testing.expectEqual(primitive.Translator, OuterProduct(primitive.Translator, primitive.Translator));
    try std.testing.expectEqual(primitive.Rotor, OuterProduct(primitive.Rotor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, OuterProduct(primitive.Motor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, OuterProduct(primitive.Translator, primitive.Rotor));
    try std.testing.expectEqual(primitive.Line, OuterProduct(primitive.Plane, primitive.Plane));
}

pub fn outerProduct(lhs: anytype, rhs: anytype) OuterProduct(@TypeOf(lhs), @TypeOf(rhs)) {
    return product(lhs, rhs, .outer);
}

test outerProduct {
    // (e123 + e012 + 10e201 + 10) | (e123) = 10e123
    try expectEqual(.{
        .e123 = 10,
    }, outerProduct(.{
        .e123 = 1,
        .e012 = 1,
        .e201 = 10,
        .@"1" = 10,
    }, .{
        .e123 = 1,
    }));
}

pub const meet = outerProduct;

pub fn RegressiveProduct(Left: type, Right: type) type {
    @setEvalBranchQuota(30000);
    return DualWithBasis(OuterProduct(DualWithBasis(Left, Basis.pseudo_vector), DualWithBasis(Right, Basis.pseudo_vector)), Basis.pseudo_vector);
}

pub const join = regressiveProduct;

test RegressiveProduct {
    try std.testing.expectEqual(primitive.Line, RegressiveProduct(primitive.Point, primitive.Point));
    try std.testing.expectEqual(primitive.Plane, RegressiveProduct(primitive.Point, primitive.Line));
}

pub fn regressiveProduct(lhs: anytype, rhs: anytype) RegressiveProduct(@TypeOf(lhs), @TypeOf(rhs)) {
    @setEvalBranchQuota(30000);
    return iDual(product(dual(lhs), dual(rhs), .outer));
}

pub fn equal(lhs: anytype, rhs: anytype) bool {
    @setEvalBranchQuota(10000);
    // TODO: perf remove duplicate comparisents.
    const Left = @TypeOf(lhs);
    const Right = @TypeOf(rhs);

    inline for (@typeInfo(Left).@"struct".fields) |field| {
        const left_value = @field(lhs, field.name);
        const right_value = blk: {
            const sign, const right_field_name = comptime getFieldNameFromBlade(Right, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(rhs, right_field_name);
        };

        if (left_value != right_value) return false;
    }
    inline for (@typeInfo(Right).@"struct".fields) |field| {
        const right_value = @field(rhs, field.name);
        const left_value = blk: {
            const sign, const left_field_name = comptime getFieldNameFromBlade(Left, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(lhs, left_field_name);
        };

        if (left_value != right_value) return false;
    }

    return true;
}

test equal {
    try std.testing.expect(equal(.{
        .e1 = 1,
    }, .{
        .e1 = 1,
    }));
    try std.testing.expect(!equal(.{
        .e1 = 2,
    }, .{
        .e1 = 1,
    }));
    try std.testing.expect(!equal(.{}, .{
        .e1 = 1,
    }));
    try std.testing.expect(!equal(.{
        .e1 = 1,
    }, .{}));
    try std.testing.expect(equal(.{
        .e12 = 1,
    }, .{
        .e21 = -1,
    }));
}

pub fn expectEqual(expected: anytype, actual: anytype) error{TestExpectedEqual}!void {
    @setEvalBranchQuota(10000);
    // TODO: perf remove duplicate comparisents.
    const Expected = @TypeOf(expected);
    const Actual = @TypeOf(actual);

    inline for (@typeInfo(Expected).@"struct".fields) |field| {
        const left_value = @field(expected, field.name);
        const right_value = blk: {
            const sign, const right_field_name = comptime getFieldNameFromBlade(Actual, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(actual, right_field_name);
        };

        if (left_value != right_value) {
            std.debug.print("{s} parts are not equal {d} != {d}\n", .{ field.name, left_value, right_value });
            return error.TestExpectedEqual;
        }
    }
    inline for (@typeInfo(Actual).@"struct".fields) |field| {
        const right_value = @field(actual, field.name);
        const left_value = blk: {
            const sign, const left_field_name = comptime getFieldNameFromBlade(Expected, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(expected, left_field_name);
        };

        if (left_value != right_value) {
            std.debug.print("{s} parts are not equal {d} != {d}\n", .{ field.name, left_value, right_value });
            return error.TestExpectedEqual;
        }
    }

    return;
}

pub fn expectApproxEqualRel(expect: anytype, actual: anytype, tolerance: f32) error{TestExpectedEqual}!void {
    @setEvalBranchQuota(10000);
    // TODO: perf remove duplicate comparisents.
    const Expect = @TypeOf(expect);
    const Actual = @TypeOf(actual);

    inline for (@typeInfo(Expect).@"struct".fields) |field| {
        const left_value = @field(expect, field.name);
        const right_value = blk: {
            const sign, const right_field_name = comptime getFieldNameFromBlade(Actual, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(actual, right_field_name);
        };

        if (!std.math.approxEqRel(f32, left_value, right_value, tolerance)) {
            std.debug.print("{s} parts are not equal {d} != {d}\n", .{ field.name, left_value, right_value });
            return error.TestExpectedEqual;
        }
    }
    inline for (@typeInfo(Actual).@"struct".fields) |field| {
        const right_value = @field(actual, field.name);
        const left_value = blk: {
            const sign, const left_field_name = comptime getFieldNameFromBlade(Expect, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(expect, left_field_name);
        };

        if (!std.math.approxEqRel(f32, left_value, right_value, tolerance)) {
            std.debug.print("{s} parts are not equal {d} != {d}\n", .{ field.name, left_value, right_value });
            return error.TestExpectedEqual;
        }
    }

    return;
}

pub fn expectApproxEqualAbs(expect: anytype, actual: anytype, tolerance: f32) error{TestExpectedEqual}!void {
    @setEvalBranchQuota(10000);
    // TODO: perf remove duplicate comparisents.
    const Expect = @TypeOf(expect);
    const Actual = @TypeOf(actual);

    inline for (@typeInfo(Expect).@"struct".fields) |field| {
        const left_value = @field(expect, field.name);
        const right_value = blk: {
            const sign, const right_field_name = comptime getFieldNameFromBlade(Actual, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(actual, right_field_name);
        };

        if (!std.math.approxEqAbs(f32, left_value, right_value, tolerance)) {
            std.debug.print("{s} parts are not equal {d} != {d}\n", .{ field.name, left_value, right_value });
            return error.TestExpectedEqual;
        }
    }
    inline for (@typeInfo(Actual).@"struct".fields) |field| {
        const right_value = @field(actual, field.name);
        const left_value = blk: {
            const sign, const left_field_name = comptime getFieldNameFromBlade(Expect, bladeFromString(field.name)) orelse break :blk 0;
            break :blk sign.float(f32) * @field(expect, left_field_name);
        };

        if (!std.math.approxEqAbs(f32, left_value, right_value, tolerance)) {
            std.debug.print("{s} parts are not equal {d} != {d}\n", .{ field.name, left_value, right_value });
            return error.TestExpectedEqual;
        }
    }

    return;
}

pub fn expectApproxEqualIgnoreNorm(lhs: anytype, rhs: anytype, tolerance: f32) error{TestExpectedEqual}!void {
    const scaled_left = geometricProduct(lhs, .{ .@"1" = norm(rhs) });
    const scaled_right = geometricProduct(rhs, .{ .@"1" = norm(lhs) });

    return expectApproxEqualRel(scaled_left, scaled_right, tolerance);
}

test regressiveProduct {
    // NOTE: Calculator here https://bivector.net/tools.html?p=3&q=0&r=1 is wrong
    // It gives negative e12 for this expression.
    // e012 & e123 = -e12 <- bivector.net old calculator.
    // e012 & e123 = +e12 <- new calculator https://enki.ws/ganja.js/examples/coffeeshop.html#XF2aui0Oi&fullscreen&1e012%20&%201e123.

    try expectEqual(
        .{
            .e12 = 1,
        },
        regressiveProduct(
            .{ .e012 = 1 },
            .{ .e123 = 1 },
        ),
    );
}
fn typeParity(comptime T: type) ?enum { even, odd } {
    const fields = @typeInfo(T).@"struct".fields;
    if (fields.len == 0) {
        return .even;
    }
    const parity = if (comptime bladeFromString(fields[0].name).len % 2 == 0) .even else .odd;
    for (fields[1..]) |field| {
        const field_parity = if (comptime bladeFromString(field.name).len % 2 == 0) .even else .odd;
        if (field_parity != parity) {
            return null;
        }
    }

    return parity;
}

// It only works for objects which contain only ever or odd blades not mixed parity.
// TODO: impelement it better not only for even/odd objects.
pub fn sandwichProduct(
    value: anytype,
    transform: anytype,
) @TypeOf(value) {
    const value_parity = comptime typeParity(@TypeOf(value));
    const transform_parity = comptime typeParity(@TypeOf(transform));

    const result = reduce(@TypeOf(value), geometricProduct(geometricProduct(transform, value), reverse(transform)));

    if (value_parity == .even or transform_parity == .even) {
        return result;
    } else {
        return geometricProduct(result, .{ .@"1" = -1 });
    }
}

test sandwichProduct {
    try expectEqual(.{
        .e123 = 1,
        .e021 = -1,
    }, sandwichProduct(primitive.Point{
        .e123 = 1,
    }, primitive.Translator{
        .@"1" = 1,
        .e03 = 1.0 / 2.0,
    }));
}

// Doesn't preserve norm.
pub fn orhogonalProjection(projecty: anytype, onto: anytype) @TypeOf(projecty) {
    return reduce(@TypeOf(projecty), geometricProduct(innerProduct(projecty, onto), reverse(onto)));
}

test orhogonalProjection {
    // projecting point onto itself gives same point.
    {
        const p = point(0, 0, 0);
        try expectEqual(p, orhogonalProjection(p, p));
    }
    {
        const p = point(2, -3, 10);
        try expectEqual(p, orhogonalProjection(p, p));
    }
    // projecting plane onto itself gives same plane.
    {
        const p = primitive.Plane{
            .e1 = 2,
            .e2 = -3,
            .e3 = 10,
        };
        try expectApproxEqualIgnoreNorm(p, orhogonalProjection(p, p), 0.001);
    }
    // project plane onto point and point onto plane.
    {
        const p = primitive.Plane{
            .e1 = 2,
        };
        try expectApproxEqualIgnoreNorm(point(0, 2, 3), orhogonalProjection(point(1, 2, 3), p), 0.001);
    }
    {
        const p = primitive.Plane{
            .e1 = 2,
        };
        try expectApproxEqualIgnoreNorm(.{
            .e0 = -2,
            .e1 = 2,
        }, orhogonalProjection(p, point(1, 2, 3)), 0.001);
    }
}

pub fn Merge(Left: type, Right: type) type {
    @setEvalBranchQuota(10000);
    var blades: []const Blade = &.{};
    for (@typeInfo(Left).@"struct".fields) |field| {
        blades = blades ++ &[1]Blade{bladeFromString(field.name)};
    }
    outer: for (@typeInfo(Right).@"struct".fields) |field| {
        const right_blade = bladeFromString(field.name);
        for (blades[0..@typeInfo(Left).@"struct".fields.len]) |left_blade| {
            if (same(left_blade, right_blade)) {
                continue :outer;
            }
        }
        blades = blades ++ &[1]Blade{right_blade};
    }

    return SelectTypeContainingBlades(
        blades,
        typesFromNamespace(primitive),
    );
}

pub fn add(lhs: anytype, rhs: anytype) Merge(@TypeOf(lhs), @TypeOf(rhs)) {
    const Result = Merge(@TypeOf(lhs), @TypeOf(rhs));
    const lhs_result: Result = reduce(Result, lhs);
    const rhs_result: Result = reduce(Result, rhs);
    var result: Result = undefined;
    inline for (@typeInfo(Result).@"struct".fields) |field| {
        @field(result, field.name) = @field(rhs_result, field.name) + @field(lhs_result, field.name);
    }
    return result;
}

test add {
    try expectEqual(.{
        .e1 = 1,
        .e12 = 2,
    }, add(.{
        .e12 = 2,
    }, .{
        .e1 = 1,
    }));
    try expectEqual(.{
        .e12 = 2,
    }, add(.{
        .e12 = 2,
    }, .{}));
}

/// source https://www.researchgate.net/publication/360528787_Normalization_Square_Roots_and_the_Exponential_and_Logarithmic_Maps_in_Geometric_Algebras_of_Less_than_6D
pub fn exp(bivector: primitive.Line) primitive.Motor {
    const l = (bivector.e12 * bivector.e12 + bivector.e31 * bivector.e31 + bivector.e23 * bivector.e23);

    if (l == 0) return .{
        .@"1" = 1,
        .e01 = bivector.e01,
        .e02 = bivector.e02,
        .e03 = bivector.e03,
        .e12 = 0,
        .e31 = 0,
        .e23 = 0,
        .e0123 = 0,
    };
    const m = (bivector.e01 * bivector.e23 + bivector.e02 * bivector.e31 + bivector.e03 * bivector.e12);
    const a = @sqrt(l);
    const c = @cos(a);
    const s = @sin(a) / a;
    const t = m / l * (c - s);

    return .{
        .@"1" = c,
        .e01 = s * bivector.e01 + t * bivector.e23,
        .e02 = s * bivector.e02 + t * bivector.e31,
        .e03 = s * bivector.e03 + t * bivector.e12,
        .e12 = s * bivector.e12,
        .e31 = s * bivector.e31,
        .e23 = s * bivector.e23,
        .e0123 = m * s,
    };
}

pub fn log(motor: primitive.Motor) primitive.Line {
    if (motor.@"1" == 1) return reduce(primitive.Line, motor);

    const a = 1 / (1 - motor.@"1" * motor.@"1");
    const b = std.math.acos(motor.@"1") * @sqrt(a);
    const c = a * motor.e0123 * (1 - motor.@"1" * b);

    return .{
        .e01 = c * motor.e23 + b * motor.e01,
        .e02 = c * motor.e31 + b * motor.e02,
        .e03 = c * motor.e12 + b * motor.e03,
        .e12 = b * motor.e12,
        .e31 = b * motor.e31,
        .e23 = b * motor.e23,
    };
}

test "log(exp(x)) == x" {
    const line: primitive.Line = .{
        .e12 = 1.0,
        .e23 = 1.0,
    };
    try expectApproxEqualIgnoreNorm(line, log(exp(line)), 0.0001);
}

pub fn lerp(lhs: anytype, rhs: anytype, t: f32) Merge(@TypeOf(lhs), @TypeOf(rhs)) {
    const Result = Merge(@TypeOf(lhs), @TypeOf(rhs));
    const lhs_result: Result = reduce(Result, lhs);
    const rhs_result: Result = reduce(Result, rhs);
    var result: Result = undefined;
    inline for (@typeInfo(Result).@"struct".fields) |field| {
        @field(result, field.name) = (1 - t) * @field(lhs_result, field.name) + t * @field(rhs_result, field.name);
    }
    return result;
}

pub fn normalized(value: anytype) @TypeOf(value) {
    const finite_norm = norm(value);
    // const infinite_norm = iNorm(value);
    // const n = if (std.math.approxEqAbs(f32, finite_norm, 0, 0e-10)) infinite_norm else finite_norm;
    const n = finite_norm;
    return geometricProduct(value, .{ .@"1" = 1 / n });
}

test normalized {
    try std.testing.expectEqual(1, norm(normalized(primitive.Line{
        .e12 = 2,
    })));
    try std.testing.expectEqual(1, norm(normalized(primitive.Line{
        .e01 = 1,
        .e12 = 1,
    })));
}
