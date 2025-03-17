const std = @import("std");

const Basis = enum {
    e0,
    e1,
    e2,

    pub fn square(b: Basis) i2 {
        return switch (b) {
            .e0 => 0,
            .e1 => 1,
            .e2 => 1,
        };
    }

    pub fn component(b: Basis) Component {
        return .{ .comps = .initOne(b) };
    }
};

const Component = struct {
    comps: std.EnumSet(Basis),

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeByte('e');
        var iter = self.comps.iterator();
        while (iter.next()) |e| {
            try writer.writeAll(@tagName(e)[1..]);
        }
    }

    pub fn fromVecs(vecs: []const Basis) Component {
        var res: Component = .{ .comps = .initEmpty() };
        for (vecs) |vec| {
            res.comps.insert(vec);
        }
        return res;
    }

    pub fn mult(lhs: Component, rhs: Component) struct { Component, i2 } {
        const both = lhs.comps.intersectWith(rhs.comps);
        var sign: i2 = 1;

        var mask: Component = .{ .comps = .initEmpty() };
        for (std.enums.values(Basis)) |base_vec| {
            mask.comps.insert(base_vec);

            if (!rhs.comps.contains(base_vec)) continue;

            const change_sign = lhs.comps.differenceWith(mask.comps).count() % 2 != 0;

            if (change_sign) sign *= -1;
            if (both.contains(base_vec)) sign *= base_vec.square();
        }
        return .{ .{ .comps = lhs.comps.xorWith(rhs.comps) }, sign };
    }

    pub fn fromString(str: []const u8) Component {
        std.debug.assert(str[0] == 'e');
        var res: Component = .{ .comps = .initEmpty() };
        for (str[1..]) |digit| {
            std.debug.assert(std.ascii.isDigit(digit));
            const name = "e" ++ .{digit};
            res.comps.insert(std.meta.stringToEnum(Basis, name).?);
        }
        return res;
    }

    pub fn less(lhs: Component, rhs: Component) bool {
        for (std.enums.values(Basis)) |base_vec| {
            if (!lhs.comps.contains(base_vec) and rhs.comps.contains(base_vec)) return true;
            if (lhs.comps.contains(base_vec) and !rhs.comps.contains(base_vec)) return false;
        }
        return false;
    }
};

pub fn main() void {
    const result = truncateType(prod(Line{
        .e0 = 1,
        .e1 = 1,
        .e2 = 0,
    }, Line{
        .e0 = 1,
        .e1 = 0,
        .e2 = -1,
    }), Point);

    std.debug.print("{any}\n", .{result});
}

pub const Line = extern struct {
    e0: f32,

    e1: f32,
    e2: f32,
};

pub const Point = extern struct {
    e12: f32,

    e01: f32,
    e02: f32,
};

pub const Motor = extern struct {
    e: f32,

    e12: f32,
    e10: f32,
    e20: f32,
};

pub const Rotor = extern struct {
    e: f32,

    e12: f32,
};

pub const Translator = extern struct {
    e: f32,

    e01: f32,
    e02: f32,
};

pub const Scalar = extern struct {
    e: f32,
};

pub fn TypeOfProd(lhs: type, rhs: type) type {
    @setEvalBranchQuota(100000);
    var components: std.BoundedArray(Component, @typeInfo(lhs).@"struct".fields.len * @typeInfo(rhs).@"struct".fields.len) = .{};

    inline for (@typeInfo(lhs).@"struct".fields) |lhf| {
        inline for (@typeInfo(rhs).@"struct".fields) |rhf| {
            const first_e = Component.fromString(lhf.name);
            const second_e = Component.fromString(rhf.name);
            const res, _ = comptime first_e.mult(second_e);

            for (components.slice()) |comp| {
                if (std.meta.eql(comp, res)) break;
            } else components.appendAssumeCapacity(res);
        }
    }

    std.mem.sort(Component, components.slice(), {}, struct {
        fn less(_: void, l: Component, r: Component) bool {
            return l.less(r);
        }
    }.less);

    const types: []const type = &.{
        Line,
        Rotor,
        Point,
    };

    types: for (types) |T| {
        if (@typeInfo(T).@"struct".fields.len != components.len) continue;

        type: inline for (@typeInfo(T).@"struct".fields) |type_info| {
            const component = Component.fromString(type_info.name);
            for (components.slice()) |comp| {
                if (std.meta.eql(comp, component)) continue :type;
            }

            continue :types;
        }

        return T;
    }

    var fields: [components.len]std.builtin.Type.StructField = undefined;
    for (&fields, components.slice()) |*field, component| {
        const name = std.fmt.comptimePrint("{}", .{component});
        field.* = .{
            .name = name,
            .type = f32,
            .alignment = @alignOf(f32),
            .is_comptime = false,
            .default_value_ptr = null,
        };
    }
    return @Type(.{
        .@"struct" = .{
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
            .layout = .auto,
        },
    });
}

pub fn prod(lhs: anytype, rhs: anytype) TypeOfProd(@TypeOf(lhs), @TypeOf(rhs)) {
    var result = std.mem.zeroes(TypeOfProd(@TypeOf(lhs), @TypeOf(rhs)));

    const L = @TypeOf(lhs);
    const R = @TypeOf(rhs);

    inline for (@typeInfo(R).@"struct".fields) |lhf| {
        inline for (@typeInfo(L).@"struct".fields) |rhf| {
            const first_e = comptime Component.fromString(lhf.name);
            const second_e = comptime Component.fromString(rhf.name);
            const res, const sign = comptime first_e.mult(second_e);

            const name = std.fmt.comptimePrint("{}", .{res});
            @field(result, name) =
                @mulAdd(
                    f32,
                    @field(lhs, lhf.name),
                    @field(rhs, rhf.name) * @as(f32, @floatFromInt(sign)),
                    @field(result, name),
                );
        }
    }
    return result;
}

pub fn truncateType(source: anytype, T: type) T {
    var result: T = undefined;
    inline for (@typeInfo(T).@"struct".fields) |field| {
        @field(result, field.name) = @field(source, field.name);
    }
    return result;
}
