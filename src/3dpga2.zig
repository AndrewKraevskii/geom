//! geometric relationships                                               expression
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

pub fn getFieldNameFromBlade(comptime T: type, comptime blade: Blade) struct { Sign, []const u8 } {
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (comptime same(bladeFromString(field.name), blade)) {
            if (sameSign(bladeFromString(field.name), blade)) {
                return .{ .@"1", field.name };
            } else {
                return .{ .@"-1", field.name };
            }
        }
    }
    @compileError(std.fmt.comptimePrint("Field matching blade {any} not found in type {any}", .{ blade, T }));
}

test getFieldNameFromBlade {
    {
        try std.testing.expectEqual(.@"-1", getFieldNameFromBlade(primitive.Motor, &.{ .e1, .e0 })[0]);
        try std.testing.expectEqual(.@"1", getFieldNameFromBlade(primitive.Motor, &.{ .e0, .e2 })[0]);
        try std.testing.expectEqual(.@"1", getFieldNameFromBlade(primitive.Motor, &.{ .e0, .e3, .e1, .e2 })[0]);
        try std.testing.expectEqual(.@"-1", getFieldNameFromBlade(primitive.Motor, &.{ .e3, .e0, .e1, .e2 })[0]);
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

pub fn Product(Left: type, Right: type) type {
    @setEvalBranchQuota(100000);
    comptime {
        var blades: []const Blade = &.{};
        for (@typeInfo(Left).@"struct".fields) |left| {
            for (@typeInfo(Right).@"struct".fields) |right| {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);

                var both = blk: {
                    const both: Blade = left_list ++ right_list;
                    break :blk both[0..both.len].*;
                };
                _ = sortGetSign(&both);

                blades = blades ++ &[1]Blade{collapseBlade(&both) orelse continue};
            }
        }
        return SelectTypeContainingBlades(
            blades,
            typesFromNamespace(primitive),
        );
    }
}

test Product {
    try std.testing.expectEqual(primitive.Motor, Product(primitive.Motor, primitive.Motor));
    try std.testing.expectEqual(primitive.Translator, Product(primitive.Translator, primitive.Translator));
    try std.testing.expectEqual(primitive.Rotor, Product(primitive.Rotor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, Product(primitive.Motor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, Product(primitive.Translator, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, Product(primitive.Plane, primitive.Plane));
}

pub fn product(lhs: anytype, rhs: anytype) Product(@TypeOf(lhs), @TypeOf(rhs)) {
    const Left = @TypeOf(lhs);
    const Right = @TypeOf(rhs);

    const Result = Product(@TypeOf(lhs), @TypeOf(rhs));

    var result: Result = .{};
    inline for (@typeInfo(Left).@"struct".fields) |left| {
        inline for (@typeInfo(Right).@"struct".fields) |right| {
            const sign, const result_field_name = comptime sign: {
                const left_list: Blade = bladeFromString(left.name);
                const right_list: Blade = bladeFromString(right.name);
                var both = blk: {
                    const both: Blade = left_list ++ right_list;
                    break :blk both[0..both.len].*;
                };
                const sign = sortGetSign(&both);
                const result_blade = collapseBlade(&both) orelse continue;
                const sign2, const result_field_name = getFieldNameFromBlade(Result, result_blade);
                break :sign .{ sign.mult(sign2), result_field_name };
            };

            // PERF: test if llvm can figure it out on is own.
            if (comptime std.meta.fieldInfo(Left, @field(std.meta.FieldEnum(Left), left.name)).is_comptime and
                std.meta.fieldInfo(Right, @field(std.meta.FieldEnum(Right), right.name)).is_comptime)
            {
                const left_value = comptime @field(lhs, left.name);
                const right_value = comptime @field(rhs, right.name);

                @field(result, result_field_name) += comptime (left_value * right_value * sign.float(f32));
                continue;
            }
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

test product {
    try std.testing.expectEqual(primitive.Scalar{ .@"1" = 1 }, product(.{
        .e1 = 1,
    }, .{
        .e1 = 1,
    }));
    try std.testing.expectEqual(primitive.Scalar{ .@"1" = -10 }, product(.{
        .e1 = 1,
    }, .{
        .e1 = -10,
    }));

    {
        // spawing operands changes result
        try std.testing.expectEqual(primitive.Plane{
            .e1 = -10,
            .e0 = -1,
        }, product(
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
        }, product(
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
        }, product(
            .{
                .e12 = 1,
            },
            .{
                .e0 = 1,
            },
        ));
        try std.testing.expectEqual(primitive.Point{
            .e012 = -1,
        }, product(
            .{
                .e21 = 1,
            },
            .{
                .e0 = 1,
            },
        ));
    }
}
