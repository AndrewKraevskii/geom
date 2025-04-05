const std = @import("std");

pub const Basis = enum {
    e0,
    e1,
    e2,
    e3,

    comptime {
        for (@typeInfo(Basis).@"enum".fields) |field| {
            const value = @field(Basis, field.name);
            std.debug.assert(value == fromNum(@tagName(value)[1] - '0'));
        }
    }

    pub fn fromNum(num: u8) Basis {
        return @enumFromInt(num);
    }

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

pub const Scalar = extern struct {
    e: f32 = 0,
};

pub const PseudoScalar = extern struct {
    e0123: f32 = 0,
};

/// Also known as 1-vector
pub const Plane = extern struct {
    e0: f32 = 0,

    e1: f32 = 0,
    e2: f32 = 0,
    e3: f32 = 0,
};

/// Also known as 2-vector
pub const Line = extern struct {
    e01: f32 = 0,
    e02: f32 = 0,
    e03: f32 = 0,

    e23: f32 = 0,
    e13: f32 = 0,
    e12: f32 = 0,
};

/// Also known as 3-vector
pub const Point = extern struct {
    e123: f32 = 0,

    /// x
    e023: f32 = 0,
    /// y
    e013: f32 = 0,
    /// z
    e012: f32 = 0,
};

/// Also known as `quaternion`
pub const Rotor = extern struct {
    e: f32 = 0,

    e12: f32 = 0,
    e13: f32 = 0,
    e23: f32 = 0,
};

/// Also known as `dual quaternion`
pub const Motor = extern struct {
    e: f32 = 0,

    e23: f32 = 0,
    e13: f32 = 0,
    e12: f32 = 0,

    e01: f32 = 0,
    e02: f32 = 0,
    e03: f32 = 0,

    e0123: f32 = 0,
};

pub const TwoReflection = extern struct {
    e: f32 = 0,

    e23: f32 = 0,
    e13: f32 = 0,
    e12: f32 = 0,

    e01: f32 = 0,
    e02: f32 = 0,
    e03: f32 = 0,
};

pub const Translator = extern struct {
    e: f32 = 0,

    e01: f32 = 0,
    e02: f32 = 0,
    e03: f32 = 0,
};

// No idea how to name it properly but it has both plane and point parts.
pub const PointPlane = extern struct {
    e0: f32 = 0,

    e1: f32 = 0,
    e2: f32 = 0,
    e3: f32 = 0,

    e023: f32 = 0,
    e013: f32 = 0,
    e012: f32 = 0,

    e123: f32 = 0,
};

// No idea how to name it properly but it has both plane and point parts.
pub const AThing = extern struct {
    e0: f32 = 0,

    e1: f32 = 0,
    e2: f32 = 0,
    e3: f32 = 0,

    e023: f32 = 0,
    e013: f32 = 0,
    e012: f32 = 0,
};

pub const Component = struct {
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
            res.comps.insert(.fromNum(digit - '0'));
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

    pub fn dual(c: Component) Component {
        return .{ .comps = c.comps.complement() };
    }
};

pub fn components(T: type) []Component {
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

pub fn selectGrade(value: anytype, grade: comptime_int) SelectGrade(@TypeOf(value), grade) {
    return truncateType(value, SelectGrade(@TypeOf(value), grade));
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
        (gradeOf(Left) + gradeOf(Right)) % @typeInfo(Basis).@"enum".fields.len,
    );
}

/// OuterProduct
pub fn meet(lhs: anytype, rhs: anytype) Meet(@TypeOf(lhs), @TypeOf(rhs)) {
    return selectGrade(geomProduct(lhs, rhs), (gradeOf(@TypeOf(lhs)) + gradeOf(@TypeOf(rhs))) % @typeInfo(Basis).@"enum".fields.len);
}

pub fn Dual(T: type) type {
    const comps = components(T);
    for (comps) |*comp| {
        comp.* = comp.dual();
    }
    return TypeFromComponents(comps);
}

pub fn dual(value: anytype) Dual(@TypeOf(value)) {
    var result: Dual(@TypeOf(value)) = undefined;

    inline for (@typeInfo(@TypeOf(result)).@"struct".fields) |field| {
        const comp = comptime Component.fromString(field.name).dual();
        const name = comptime std.fmt.comptimePrint("{}", .{comp});

        if (comptime comp.grade() == 3) {
            @field(result, field.name) = -@field(value, name);
        } else @field(result, field.name) = @field(value, name);
    }
    return result;
}

pub fn Join(Left: type, Right: type) type {
    @setEvalBranchQuota(10000);
    return Dual(Meet(Dual(Left), Dual(Right)));
}

/// Regressive Product
pub fn join(lhs: anytype, rhs: anytype) Join(@TypeOf(lhs), @TypeOf(rhs)) {
    return dual(meet(dual(lhs), dual(rhs)));
}

pub fn InnerProduct(Left: type, Right: type) type {
    return SelectGrade(
        GeomProduct(Left, Right),
        @abs(gradeOf(Left) - gradeOf(Right)),
    );
}

pub fn innerProduct(lhs: anytype, rhs: anytype) InnerProduct(@TypeOf(lhs), @TypeOf(rhs)) {
    return selectGrade(
        geomProduct(lhs, rhs),
        @abs(gradeOf(@TypeOf(lhs)) - gradeOf(@TypeOf(rhs))),
    );
}

pub fn reverse(value: anytype) @TypeOf(value) {
    var copy = value;
    inline for (@typeInfo(@TypeOf(copy)).@"struct".fields) |field| {
        if (comptime Component.fromString(field.name).grade() % 4 >= 2)
            @field(copy, field.name) *= -1;
    }
    return copy;
}

pub fn project(lhs: anytype, rhs: anytype) @TypeOf(rhs) {
    return truncateType(geomProduct(innerProduct(lhs, rhs), lhs), @TypeOf(rhs));
}

pub fn sandwich(transform: anytype, thing: anytype) @TypeOf(thing) {
    const result = geomProduct(transform, geomProduct(thing, reverse(transform)));
    return truncateType(result, @TypeOf(thing));
}

// TODO: perf even tho we skip some componets which are 0 we would still gane them in TypeFromComponents. Do something about it.
pub fn GeomProduct(lhs: type, rhs: type) type {
    @setEvalBranchQuota(100000);

    var comps: std.BoundedArray(Component, @typeInfo(lhs).@"struct".fields.len * @typeInfo(rhs).@"struct".fields.len) = .{};

    inline for (components(lhs)) |first_e| {
        inline for (components(rhs)) |second_e| {
            const res, const sign = first_e.mult(second_e);

            if (sign == 0) {
                continue;
            }

            for (comps.slice()) |comp| {
                if (std.meta.eql(comp, res)) break;
            } else comps.appendAssumeCapacity(res);
        }
    }

    return TypeFromComponents(comps.slice());
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
            if (comptime sign == 0) continue;

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

pub fn componentContainedInType(comp: Component, T: type) bool {
    inline for (components(T)) |component|
        if (std.meta.eql(comp, component)) return true;

    return false;
}

pub fn TypeFromComponents(comps: []const Component) type {
    const types: []const type = &.{
        Plane,
        Line,
        Point,
        Rotor,
        Motor,
        TwoReflection,
        Translator,
        Scalar,
        PseudoScalar,
        PointPlane,
        AThing,
    };

    type: for (types) |T| {
        if (@typeInfo(T).@"struct".fields.len < comps.len) continue;

        for (comps) |comp| {
            if (!componentContainedInType(comp, T)) {
                continue :type;
            }
        }

        return T;
    }

    var res: []const u8 = "";
    for (comps) |comp| {
        res = res ++ std.fmt.comptimePrint(" {}", .{comp});
    }
    @compileError("Got component with this components. Provide type to store them" ++ res);
}

pub fn add(lhs: anytype, rhs: @TypeOf(lhs)) @TypeOf(lhs) {
    var result: @TypeOf(lhs) = undefined;
    inline for (@typeInfo(@TypeOf(rhs)).@"struct".fields) |field| {
        @field(result, field.name) = @field(lhs, field.name) + @field(rhs, field.name);
    }
    return result;
}

pub fn scale(lhs: anytype, rhs: f32) @TypeOf(lhs) {
    var copy = lhs;
    inline for (@typeInfo(@TypeOf(lhs)).@"struct".fields) |field| {
        @field(copy, field.name) *= rhs;
    }
    return copy;
}

pub fn norm(value: anytype) f32 {
    const result = geomProduct(value, reverse(value));
    return @sqrt(result.e);
}

pub fn normalized(value: anytype) @TypeOf(value) {
    return scale(value, 1 / norm(value));
}

pub fn lerp(lhs: anytype, rhs: anytype, t: f32) @TypeOf(lhs, rhs) {
    return add(scale(lhs, 1 - t), scale(rhs, t));
}

pub fn truncateType(source: anytype, T: type) T {
    var result: T = undefined;
    inline for (@typeInfo(T).@"struct".fields) |field| {
        @field(result, field.name) = @field(source, field.name);
    }
    return result;
}

pub fn sqrt(value: anytype) @TypeOf(value) {
    // TODO: something is not right here
    const sign: f32 = if (value.e < 0) -1 else 1;
    var normalized_value = normalized(value);
    normalized_value.e += sign;
    return normalized(normalized_value);
}
// pub fn log(r: Motor) Line {
//     if (r.e == 1) return .{
//         .e01 = r.e01,
//         .e02 = r.e02,
//         .e03 = r.e03,
//         .e12 = 0,
//         .e13 = 0,
//         .e23 = 0,
//     };

//     const a = 1 / (1 - r.e * r.e); // inv squared length
//     const b = std.math.acos(r.e0) * @sqrt(a); // rotation scale
//     const c = a * r.e0123 * (1 - r.e); // translation scale
//     // function log(r) {
//     //   if (r[0]==1) return bivector(r[1],r[2],r[3],0,0,0);
//     //   var a = 1/(1 - r[0]*r[0]),                 // inv squared length.
//     //       b = acos(r[0])*sqrt(a),                // rotation scale
//     //       c = a*r[7]*(1 - r[0]*b);               // translation scale
//     //   return bivector( c*r[6] + b*r[1], c*r[5] + b*r[2], c*r[4] + b*r[3], b*r[4], b*r[5], b*r[6] );
//     // }
//     //

//     // pub const Line = extern struct {
//     //     e01: f32,
//     //     e02: f32,
//     //     e03: f32,

//     //     e23: f32,
//     //     e13: f32,
//     //     e12: f32,
//     // };
//     // return .{
//     //     .e01 = c * r.e12 + b * r.e23,
//     //     .e02 = ,
//     //     .e03 = c
//     // };
// }

pub fn exp(bivector: Line) Motor {
    const l = (bivector.e12 * bivector.e12 + bivector.e13 * bivector.e13 + bivector.e23 * bivector.e23);

    if (l == 0) return .{
        .e = 1,
        .e01 = bivector.e01,
        .e02 = bivector.e02,
        .e03 = bivector.e03,
        .e12 = 0,
        .e13 = 0,
        .e23 = 0,
        .e0123 = 0,
    };
    const m = (bivector.e01 * bivector.e23 + bivector.e02 * -bivector.e13 + bivector.e03 * bivector.e12);
    const a = @sqrt(l);
    const c = @cos(a);
    const s = @sin(a) / a;
    const t = m / l * (c - s);

    return .{
        .e = c,
        .e01 = s * bivector.e01 + t * bivector.e23,
        .e02 = s * bivector.e02 - t * bivector.e13,
        .e03 = s * bivector.e03 + t * bivector.e12,
        .e12 = s * bivector.e12,
        .e13 = s * bivector.e13,
        .e23 = s * bivector.e23,
        .e0123 = m * s,
    };
}
