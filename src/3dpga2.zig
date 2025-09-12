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
};

pub fn basisListFromString(comptime str: []const u8) []const Basis {
    const basises = comptime blk: {
        if (std.mem.eql(u8, str, "1")) break :blk &.{};

        std.debug.assert(str[0] == 'e');
        var basises: []const Basis = &.{};

        for (str[1..]) |digit| {
            std.debug.assert(std.ascii.isDigit(digit));
            basises = basises ++ &[_]Basis{@enumFromInt(digit - '0')};
        }
        break :blk basises;
    };
    return basises;
}

test basisListFromString {
    try std.testing.expectEqualSlices(Basis, &[_]Basis{ .e1, .e2, .e3 }, basisListFromString("e123"));
    try std.testing.expectEqualSlices(Basis, &[_]Basis{.e0}, basisListFromString("e0"));
    try std.testing.expectEqualSlices(Basis, &[_]Basis{}, basisListFromString("e"));
    try std.testing.expectEqualSlices(Basis, &[_]Basis{ .e1, .e2, .e0, .e3 }, basisListFromString("e1203"));
}

/// Represents any not deforming motion in 3d.
/// Also known as dual quaternion.
const Motor = struct {
    @"1": f32 = 0,

    e01: f32 = 0,
    e02: f32 = 0,
    e03: f32 = 0,

    e12: f32 = 0,
    e23: f32 = 0,
    e31: f32 = 0,

    e0123: f32 = 0,
};

pub fn get(m: anytype, comptime field_name: []const u8) f32 {
    const T = switch (@typeInfo(@TypeOf(m))) {
        .pointer => |p| p.child,
        .@"struct" => @TypeOf(m),
        else => comptime unreachable,
    };
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (comptime same(basisListFromString(field.name), basisListFromString(field_name))) {
            if (sameSign(basisListFromString(field.name), basisListFromString(field_name))) {
                return @field(m, field.name);
            } else {
                return -@field(m, field.name);
            }
        }
    }
    @compileError(std.fmt.comptimePrint("Field {s} not found in type {any}", .{ field_name, T }));
}

test get {
    {
        const m: Motor = .{
            .e01 = 1,
            .e02 = 2,
            .e0123 = 3,
        };
        try std.testing.expectEqual(-1, get(m, "e10"));
        try std.testing.expectEqual(2, get(m, "e02"));
        try std.testing.expectEqual(3, get(m, "e0312"));
        try std.testing.expectEqual(-3, get(m, "e3012"));
    }
}

/// Figuers out will sign change if you reorder `first_order` to `second_order`
/// Asserts set of elements in first slice is same as in second.
fn sameSign(comptime first_order: []const Basis, comptime second_order: []const Basis) bool {
    std.debug.assert(same(first_order, second_order));

    var first_copy: [first_order.len]Basis = first_order[0..first_order.len].*;
    var second_copy: [second_order.len]Basis = second_order[0..second_order.len].*;

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
    var first_swaps: usize = 0;
    std.sort.insertionContext(
        0,
        first_order.len,
        CountSwaps{
            .swap_counter = &first_swaps,
            .items = &first_copy,
        },
    );
    var second_swaps: usize = 0;
    std.sort.insertionContext(
        0,
        first_order.len,
        CountSwaps{
            .swap_counter = &second_swaps,
            .items = &second_copy,
        },
    );

    return first_swaps % 2 == second_swaps % 2;
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

pub fn Product(Left: type, Right: type) type {
    var basises: []const []const Basis = &.{};
    inline for (@typeInfo(Left).@"struct".fields) |left| {
        basisListFromString(left.name);
    }
    inline for (@typeInfo(Right).@"struct".fields) |right| {}
}

test Product {
    try std.testing.expectEqual(Motor, Product(Motor, Motor));
}

// pub fn product(left: anytype, right: anytype) void {}
