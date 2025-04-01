const std = @import("std");

const Basis = enum {
    e0,
    e1,
    e2,
    e3,

    pub fn square(b: Basis) i2 {
        return switch (b) {
            .e0 => 0,
            .e1 => 1,
            .e2 => 1,
            .e3 => 1,
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

    pub fn grade(c: Component) usize {
        return c.comps.count();
    }
};

pub fn components(T: type) []const Component {
    var comps: [@typeInfo(T).@"struct".fields.len]Component = undefined;
    inline for (&comps, @typeInfo(T).@"struct".fields) |*comp, field| {
        comp.* = Component.fromString(field.name);
    }
    return &comps;
}

pub fn SelectGrade(T: type, grade: comptime_int) type {
    var comps: std.BoundedArray(Component, components(T).len) = .{};
    for (components(T)) |component| {
        if (component.grade() == grade) {
            comps.appendAssumeCapacity(component);
        }
    }
    return TypeFromComponents(comps.slice());
}

pub fn selectGrade(value: anytype, grade: comptime_int) SelectGrade(@TypeOf(value, grade)) {
    const T = @TypeOf(value);
    var comps: std.BoundedArray(Component, components(T).len) = .{};
    for (components(T)) |component| {
        if (component.grade() == grade) {
            comps.append(component);
        }
    }
    return TypeFromComponents(comps.slice());
}

pub fn outerProduct(lhs: anytype, rhs: anytype) SelectGrade(GeomProduct(lhs, rhs)) {
    return selectGrade(
        geomProduct(lhs, rhs),
    );
}

pub fn gradeOf(value: type) comptime_int {
    const first_grade = components(value)[0].grade();
    for (components(value)) |comp| {
        if (first_grade != comp.grade()) {
            @compileError("Multigrade stuff is not allowed");
        }
    }
    return first_grade;
}

pub fn Meet(Left: type, Right: type) type {
    return SelectGrade(
        GeomProduct(Left, Right),
        gradeOf(Left) + gradeOf(Right),
    );
}

/// OuterProduct
pub fn meet(lhs: anytype, rhs: anytype) Meet(@TypeOf(lhs), @TypeOf(rhs)) {
    return selectGrade(
        geomProduct(lhs, rhs),
        gradeOf(@TypeOf(rhs)) + gradeOf(@TypeOf(rhs)),
    );
}

// pub fn Join(Left: type, Right: type) type {
//     return SelectGrade(
//         GeomProduct(Left, Right),
//         @abs(gradeOf(Left) - gradeOf(Right)),
//     );
// }

// /// Regressive Product
// pub fn join(lhs: anytype, rhs: anytype) Meet(@TypeOf(lhs), @TypeOf(rhs)) {
//     return selectGrade(
//         geomProduct(lhs, rhs),
//         @abs(gradeOf(@TypeOf(rhs)) - gradeOf(@TypeOf(rhs))),
//     );
// }

pub fn InnerProduct(Left: type, Right: type) type {
    return SelectGrade(
        GeomProduct(Left, Right),
        @abs(gradeOf(Left) - gradeOf(Right)),
    );
}

pub fn innerProduct(lhs: anytype, rhs: anytype) Meet(@TypeOf(lhs), @TypeOf(rhs)) {
    return selectGrade(
        geomProduct(lhs, rhs),
        @abs(gradeOf(@TypeOf(rhs)) - gradeOf(@TypeOf(rhs))),
    );
}

pub fn main() void {
    const result = Meet(Plane, Point);

    std.debug.print("{any}\n", .{result});
}

pub const Scalar = extern struct {
    e: f32,
};

pub const PseudoScalar = extern struct {
    e0123: f32,
};

pub const Plane = extern struct {
    e0: f32,

    e1: f32,
    e2: f32,
    e3: f32,
};

pub const Line = extern struct {
    e01: f32,
    e02: f32,
    e03: f32,

    e12: f32,
    e13: f32,
    e23: f32,
};

pub const Point = extern struct {
    e123: f32,

    e012: f32,
    e023: f32,
    e013: f32,
};

pub const Rotor = extern struct {
    e: f32,

    e12: f32,
    e13: f32,
    e23: f32,
};

pub const Motor = extern struct {
    e: f32,

    e12: f32,
    e13: f32,
    e23: f32,

    e01: f32,
    e02: f32,
    e03: f32,

    e0123: f32,
};

pub const Translator = extern struct {
    e: f32,

    e01: f32,
    e02: f32,
};

pub const PointPlane = extern struct {
    e0: f32,

    e1: f32,
    e2: f32,
    e3: f32,

    e023: f32,
    e013: f32,
    e012: f32,

    e123: f32,
};

pub fn GeomProduct(lhs: type, rhs: type) type {
    @setEvalBranchQuota(100000);
    var comps: std.BoundedArray(Component, @typeInfo(lhs).@"struct".fields.len * @typeInfo(rhs).@"struct".fields.len) = .{};

    inline for (components(lhs)) |first_e| {
        inline for (components(rhs)) |second_e| {
            const res, _ = first_e.mult(second_e);

            for (comps.slice()) |comp| {
                if (std.meta.eql(comp, res)) break;
            } else comps.appendAssumeCapacity(res);
        }
    }

    std.mem.sort(Component, comps.slice(), {}, struct {
        fn less(_: void, l: Component, r: Component) bool {
            return l.less(r);
        }
    }.less);

    return TypeFromComponents(comps.slice());
}

pub fn TypeFromComponents(comps: []const Component) type {
    const types: []const type = &.{
        Plane,
        Line,
        Point,
        Rotor,
        Motor,
        Translator,
        Scalar,
        PseudoScalar,
        PointPlane,
    };

    type: for (types) |T| {
        if (@typeInfo(T).@"struct".fields.len < comps.len) continue;

        component: for (comps) |comp| {
            inline for (components(T)) |component|
                if (std.meta.eql(comp, component)) continue :component;

            continue :type;
        }

        return T;
    }
}

pub fn geomProduct(lhs: anytype, rhs: anytype) GeomProduct(@TypeOf(lhs), @TypeOf(rhs)) {
    var result = std.mem.zeroes(GeomProduct(@TypeOf(lhs), @TypeOf(rhs)));

    const L = @TypeOf(lhs);
    const R = @TypeOf(rhs);

    inline for (@typeInfo(L).@"struct".fields) |lhf| {
        inline for (@typeInfo(R).@"struct".fields) |rhf| {
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

export fn pointVPoint(a: Point, b: Point) Motor {
    return geomProduct(a, b);
}

export fn lineVLine(a: Line, b: Line) Motor {
    return geomProduct(a, b);
}

export fn planeVLine(a: Plane, b: Line) PointPlane {
    return geomProduct(a, b);
}

pub fn truncateType(source: anytype, T: type) T {
    var result: T = undefined;
    inline for (@typeInfo(T).@"struct".fields) |field| {
        @field(result, field.name) = @field(source, field.name);
    }
    return result;
}
