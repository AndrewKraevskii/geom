const std = @import("std");

const Float = f32;

pub const Multivector = struct {
    mvec: std.EnumArray(basis, Float),

    pub const basis = enum {
        @"1",
        e0,
        e1,
        e2,
        e3,
        e01,
        e02,
        e03,
        e12,
        e31,
        e23,
        e021,
        e013,
        e032,
        e123,
        e0123,

        comptime {
            for (@typeInfo(basis).@"enum".fields) |field| {
                if (std.mem.eql(u8, "1", field.name)) continue;
                std.debug.assert(field.name[0] == 'e');
                for (field.name[1..]) |char| {
                    std.debug.assert(std.ascii.isDigit(char));
                }
                std.debug.assert(field.name[1..].len <= 9);
            }
        }

        pub fn grade(_b: basis) usize {
            return switch (_b) {
                .@"1" => 0,
                inline else => |b| return @tagName(b)[1..].len,
            };
        }
    };

    pub const zero: @This() = .{ .mvec = .initFill(0) };

    pub fn one(base: basis) @This() {
        var res = zero;
        res.mvec.set(base, 1.0);
        return res;
    }

    pub fn reverse(vec: @This()) @This() {
        var res: @This() = undefined;
        inline for (comptime std.enums.values(basis), &res.mvec.values, vec.mvec.values) |field, *target, source| {
            if (comptime field.grade() % 4 >= 2) {
                target.* = -source;
            } else {
                target.* = source;
            }
        }
        return res;
    }

    pub fn conjugate(vec: @This()) @This() {
        var res: @This() = undefined;
        inline for (comptime std.enums.values(basis), &res.mvec.values, vec.mvec.values) |field, *target, source| {
            if (comptime (field.grade() + 1) % 4 >= 2) {
                target.* = -source;
            } else {
                target.* = source;
            }
        }
        return res;
    }

    pub fn involute(vec: @This()) @This() {
        var res: @This() = undefined;
        inline for (comptime std.enums.values(basis), &res.mvec.values, vec.mvec.values) |field, *target, source| {
            if (comptime (field.grade()) % 2 == 1) {
                target.* = -source;
            } else {
                target.* = source;
            }
        }
        return res;
    }

    pub fn dual(vec: @This()) @This() {
        var res: @This() = undefined;
        inline for (0.., vec.mvec.values) |index, source| {
            res.mvec.values[vec.mvec.values.len - index - 1] = source;
        }
        return res;
    }

    pub fn mul(self: @This(), other: @This()) @This() {
        var res: @This() = undefined;
        const b = other.mvec.values;
        const a = self.mvec.values;

        res.mvec.values[0] = b[0] * a[0] + b[2] * a[2] + b[3] * a[3] + b[4] * a[4] - b[8] * a[8] - b[9] * a[9] - b[10] * a[10] - b[14] * a[14];
        res.mvec.values[1] = b[1] * a[0] + b[0] * a[1] - b[5] * a[2] - b[6] * a[3] - b[7] * a[4] + b[2] * a[5] + b[3] * a[6] + b[4] * a[7] + b[11] * a[8] + b[12] * a[9] + b[13] * a[10] + b[8] * a[11] + b[9] * a[12] + b[10] * a[13] + b[15] * a[14] - b[14] * a[15];
        res.mvec.values[2] = b[2] * a[0] + b[0] * a[2] - b[8] * a[3] + b[9] * a[4] + b[3] * a[8] - b[4] * a[9] - b[14] * a[10] - b[10] * a[14];
        res.mvec.values[3] = b[3] * a[0] + b[8] * a[2] + b[0] * a[3] - b[10] * a[4] - b[2] * a[8] - b[14] * a[9] + b[4] * a[10] - b[9] * a[14];
        res.mvec.values[4] = b[4] * a[0] - b[9] * a[2] + b[10] * a[3] + b[0] * a[4] - b[14] * a[8] + b[2] * a[9] - b[3] * a[10] - b[8] * a[14];
        res.mvec.values[5] = b[5] * a[0] + b[2] * a[1] - b[1] * a[2] - b[11] * a[3] + b[12] * a[4] + b[0] * a[5] - b[8] * a[6] + b[9] * a[7] + b[6] * a[8] - b[7] * a[9] - b[15] * a[10] - b[3] * a[11] + b[4] * a[12] + b[14] * a[13] - b[13] * a[14] - b[10] * a[15];
        res.mvec.values[6] = b[6] * a[0] + b[3] * a[1] + b[11] * a[2] - b[1] * a[3] - b[13] * a[4] + b[8] * a[5] + b[0] * a[6] - b[10] * a[7] - b[5] * a[8] - b[15] * a[9] + b[7] * a[10] + b[2] * a[11] + b[14] * a[12] - b[4] * a[13] - b[12] * a[14] - b[9] * a[15];
        res.mvec.values[7] = b[7] * a[0] + b[4] * a[1] - b[12] * a[2] + b[13] * a[3] - b[1] * a[4] - b[9] * a[5] + b[10] * a[6] + b[0] * a[7] - b[15] * a[8] + b[5] * a[9] - b[6] * a[10] + b[14] * a[11] - b[2] * a[12] + b[3] * a[13] - b[11] * a[14] - b[8] * a[15];
        res.mvec.values[8] = b[8] * a[0] + b[3] * a[2] - b[2] * a[3] + b[14] * a[4] + b[0] * a[8] + b[10] * a[9] - b[9] * a[10] + b[4] * a[14];
        res.mvec.values[9] = b[9] * a[0] - b[4] * a[2] + b[14] * a[3] + b[2] * a[4] - b[10] * a[8] + b[0] * a[9] + b[8] * a[10] + b[3] * a[14];
        res.mvec.values[10] = b[10] * a[0] + b[14] * a[2] + b[4] * a[3] - b[3] * a[4] + b[9] * a[8] - b[8] * a[9] + b[0] * a[10] + b[2] * a[14];
        res.mvec.values[11] = b[11] * a[0] - b[8] * a[1] + b[6] * a[2] - b[5] * a[3] + b[15] * a[4] - b[3] * a[5] + b[2] * a[6] - b[14] * a[7] - b[1] * a[8] + b[13] * a[9] - b[12] * a[10] + b[0] * a[11] + b[10] * a[12] - b[9] * a[13] + b[7] * a[14] - b[4] * a[15];
        res.mvec.values[12] = b[12] * a[0] - b[9] * a[1] - b[7] * a[2] + b[15] * a[3] + b[5] * a[4] + b[4] * a[5] - b[14] * a[6] - b[2] * a[7] - b[13] * a[8] - b[1] * a[9] + b[11] * a[10] - b[10] * a[11] + b[0] * a[12] + b[8] * a[13] + b[6] * a[14] - b[3] * a[15];
        res.mvec.values[13] = b[13] * a[0] - b[10] * a[1] + b[15] * a[2] + b[7] * a[3] - b[6] * a[4] - b[14] * a[5] - b[4] * a[6] + b[3] * a[7] + b[12] * a[8] - b[11] * a[9] - b[1] * a[10] + b[9] * a[11] - b[8] * a[12] + b[0] * a[13] + b[5] * a[14] - b[2] * a[15];
        res.mvec.values[14] = b[14] * a[0] + b[10] * a[2] + b[9] * a[3] + b[8] * a[4] + b[4] * a[8] + b[3] * a[9] + b[2] * a[10] + b[0] * a[14];
        res.mvec.values[15] = b[15] * a[0] + b[14] * a[1] + b[13] * a[2] + b[12] * a[3] + b[11] * a[4] + b[10] * a[5] + b[9] * a[6] + b[8] * a[7] + b[7] * a[8] + b[6] * a[9] + b[5] * a[10] - b[4] * a[11] - b[3] * a[12] - b[2] * a[13] - b[1] * a[14] + b[0] * a[15];

        return res;
    }

    /// Wedge
    /// The outer product. (MEET)
    pub fn meet(self: @This(), other: @This()) @This() {
        var res: @This() = undefined;
        const b = other.mvec.values;
        const a = self.mvec.values;

        res.mvec.values[0] = b[0] * a[0];
        res.mvec.values[1] = b[1] * a[0] + b[0] * a[1];
        res.mvec.values[2] = b[2] * a[0] + b[0] * a[2];
        res.mvec.values[3] = b[3] * a[0] + b[0] * a[3];
        res.mvec.values[4] = b[4] * a[0] + b[0] * a[4];
        res.mvec.values[5] = b[5] * a[0] + b[2] * a[1] - b[1] * a[2] + b[0] * a[5];
        res.mvec.values[6] = b[6] * a[0] + b[3] * a[1] - b[1] * a[3] + b[0] * a[6];
        res.mvec.values[7] = b[7] * a[0] + b[4] * a[1] - b[1] * a[4] + b[0] * a[7];
        res.mvec.values[8] = b[8] * a[0] + b[3] * a[2] - b[2] * a[3] + b[0] * a[8];
        res.mvec.values[9] = b[9] * a[0] - b[4] * a[2] + b[2] * a[4] + b[0] * a[9];
        res.mvec.values[10] = b[10] * a[0] + b[4] * a[3] - b[3] * a[4] + b[0] * a[10];
        res.mvec.values[11] = b[11] * a[0] - b[8] * a[1] + b[6] * a[2] - b[5] * a[3] - b[3] * a[5] + b[2] * a[6] - b[1] * a[8] + b[0] * a[11];
        res.mvec.values[12] = b[12] * a[0] - b[9] * a[1] - b[7] * a[2] + b[5] * a[4] + b[4] * a[5] - b[2] * a[7] - b[1] * a[9] + b[0] * a[12];
        res.mvec.values[13] = b[13] * a[0] - b[10] * a[1] + b[7] * a[3] - b[6] * a[4] - b[4] * a[6] + b[3] * a[7] - b[1] * a[10] + b[0] * a[13];
        res.mvec.values[14] = b[14] * a[0] + b[10] * a[2] + b[9] * a[3] + b[8] * a[4] + b[4] * a[8] + b[3] * a[9] + b[2] * a[10] + b[0] * a[14];
        res.mvec.values[15] = b[15] * a[0] + b[14] * a[1] + b[13] * a[2] + b[12] * a[3] + b[11] * a[4] + b[10] * a[5] + b[9] * a[6] + b[8] * a[7] + b[7] * a[8] + b[6] * a[9] + b[5] * a[10] - b[4] * a[11] - b[3] * a[12] - b[2] * a[13] - b[1] * a[14] + b[0] * a[15];

        return res;
    }

    /// Vee
    /// The regressive product. (JOIN)
    pub fn join(self: @This(), other: @This()) @This() {
        var res: @This() = undefined;
        const b = other.mvec.values;
        const a = self.mvec.values;

        res.mvec.values[15] = 1 * (a[15] * b[15]);
        res.mvec.values[14] = -1 * (a[14] * -1 * b[15] + a[15] * b[14] * -1);
        res.mvec.values[13] = -1 * (a[13] * -1 * b[15] + a[15] * b[13] * -1);
        res.mvec.values[12] = -1 * (a[12] * -1 * b[15] + a[15] * b[12] * -1);
        res.mvec.values[11] = -1 * (a[11] * -1 * b[15] + a[15] * b[11] * -1);
        res.mvec.values[10] = 1 * (a[10] * b[15] + a[13] * -1 * b[14] * -1 - a[14] * -1 * b[13] * -1 + a[15] * b[10]);
        res.mvec.values[9] = 1 * (a[9] * b[15] + a[12] * -1 * b[14] * -1 - a[14] * -1 * b[12] * -1 + a[15] * b[9]);
        res.mvec.values[8] = 1 * (a[8] * b[15] + a[11] * -1 * b[14] * -1 - a[14] * -1 * b[11] * -1 + a[15] * b[8]);
        res.mvec.values[7] = 1 * (a[7] * b[15] + a[12] * -1 * b[13] * -1 - a[13] * -1 * b[12] * -1 + a[15] * b[7]);
        res.mvec.values[6] = 1 * (a[6] * b[15] - a[11] * -1 * b[13] * -1 + a[13] * -1 * b[11] * -1 + a[15] * b[6]);
        res.mvec.values[5] = 1 * (a[5] * b[15] + a[11] * -1 * b[12] * -1 - a[12] * -1 * b[11] * -1 + a[15] * b[5]);
        res.mvec.values[4] = 1 * (a[4] * b[15] - a[7] * b[14] * -1 + a[9] * b[13] * -1 - a[10] * b[12] * -1 - a[12] * -1 * b[10] + a[13] * -1 * b[9] - a[14] * -1 * b[7] + a[15] * b[4]);
        res.mvec.values[3] = 1 * (a[3] * b[15] - a[6] * b[14] * -1 - a[8] * b[13] * -1 + a[10] * b[11] * -1 + a[11] * -1 * b[10] - a[13] * -1 * b[8] - a[14] * -1 * b[6] + a[15] * b[3]);
        res.mvec.values[2] = 1 * (a[2] * b[15] - a[5] * b[14] * -1 + a[8] * b[12] * -1 - a[9] * b[11] * -1 - a[11] * -1 * b[9] + a[12] * -1 * b[8] - a[14] * -1 * b[5] + a[15] * b[2]);
        res.mvec.values[1] = 1 * (a[1] * b[15] + a[5] * b[13] * -1 + a[6] * b[12] * -1 + a[7] * b[11] * -1 + a[11] * -1 * b[7] + a[12] * -1 * b[6] + a[13] * -1 * b[5] + a[15] * b[1]);
        res.mvec.values[0] = 1 * (a[0] * b[15] + a[1] * b[14] * -1 + a[2] * b[13] * -1 + a[3] * b[12] * -1 + a[4] * b[11] * -1 + a[5] * b[10] + a[6] * b[9] + a[7] * b[8] + a[8] * b[7] + a[9] * b[6] + a[10] * b[5] - a[11] * -1 * b[4] - a[12] * -1 * b[3] - a[13] * -1 * b[2] - a[14] * -1 * b[1] + a[15] * b[0]);

        return res;
    }

    /// Dot
    /// The inner product.
    pub fn innerProduct(self: @This(), other: @This()) @This() {
        var res: @This() = undefined;
        const b = other.mvec.values;
        const a = self.mvec.values;

        res.mvec.values[0] = b[0] * a[0] + b[2] * a[2] + b[3] * a[3] + b[4] * a[4] - b[8] * a[8] - b[9] * a[9] - b[10] * a[10] - b[14] * a[14];
        res.mvec.values[1] = b[1] * a[0] + b[0] * a[1] - b[5] * a[2] - b[6] * a[3] - b[7] * a[4] + b[2] * a[5] + b[3] * a[6] + b[4] * a[7] + b[11] * a[8] + b[12] * a[9] + b[13] * a[10] + b[8] * a[11] + b[9] * a[12] + b[10] * a[13] + b[15] * a[14] - b[14] * a[15];
        res.mvec.values[2] = b[2] * a[0] + b[0] * a[2] - b[8] * a[3] + b[9] * a[4] + b[3] * a[8] - b[4] * a[9] - b[14] * a[10] - b[10] * a[14];
        res.mvec.values[3] = b[3] * a[0] + b[8] * a[2] + b[0] * a[3] - b[10] * a[4] - b[2] * a[8] - b[14] * a[9] + b[4] * a[10] - b[9] * a[14];
        res.mvec.values[4] = b[4] * a[0] - b[9] * a[2] + b[10] * a[3] + b[0] * a[4] - b[14] * a[8] + b[2] * a[9] - b[3] * a[10] - b[8] * a[14];
        res.mvec.values[5] = b[5] * a[0] - b[11] * a[3] + b[12] * a[4] + b[0] * a[5] - b[15] * a[10] - b[3] * a[11] + b[4] * a[12] - b[10] * a[15];
        res.mvec.values[6] = b[6] * a[0] + b[11] * a[2] - b[13] * a[4] + b[0] * a[6] - b[15] * a[9] + b[2] * a[11] - b[4] * a[13] - b[9] * a[15];
        res.mvec.values[7] = b[7] * a[0] - b[12] * a[2] + b[13] * a[3] + b[0] * a[7] - b[15] * a[8] - b[2] * a[12] + b[3] * a[13] - b[8] * a[15];
        res.mvec.values[8] = b[8] * a[0] + b[14] * a[4] + b[0] * a[8] + b[4] * a[14];
        res.mvec.values[9] = b[9] * a[0] + b[14] * a[3] + b[0] * a[9] + b[3] * a[14];
        res.mvec.values[10] = b[10] * a[0] + b[14] * a[2] + b[0] * a[10] + b[2] * a[14];
        res.mvec.values[11] = b[11] * a[0] + b[15] * a[4] + b[0] * a[11] - b[4] * a[15];
        res.mvec.values[12] = b[12] * a[0] + b[15] * a[3] + b[0] * a[12] - b[3] * a[15];
        res.mvec.values[13] = b[13] * a[0] + b[15] * a[2] + b[0] * a[13] - b[2] * a[15];
        res.mvec.values[14] = b[14] * a[0] + b[0] * a[14];
        res.mvec.values[15] = b[15] * a[0] + b[0] * a[15];

        return res;
    }

    pub fn add(self: @This(), other: @This()) @This() {
        var res: @This() = undefined;

        inline for (
            &res.mvec.values,
            self.mvec.values,
            other.mvec.values,
        ) |*r, a, b| {
            r.* = a + b;
        }

        return res;
    }

    pub fn scale(self: @This(), other: Float) @This() {
        var res: @This() = undefined;

        inline for (
            &res.mvec.values,
            self.mvec.values,
        ) |*r, a| {
            r.* = a * other;
        }

        return res;
    }

    pub fn sadd(self: @This(), other: Float) @This() {
        var res: @This() = self;

        res.mvec.getPtr(.@"1").* += other;

        return res;
    }

    pub fn ssub(self: @This(), other: Float) @This() {
        return self.sadd(-other);
    }

    pub fn norm(self: @This()) Float {
        const scalar_part = self.mul(self.conjugate()).mvec.get(.@"1");
        return @sqrt(@abs(scalar_part));
    }

    pub fn inorm(self: @This()) Float {
        return self.dual().norm();
    }

    pub fn normalized(self: @This()) @This() {
        return self.scale(1.0 / self.norm());
    }

    pub fn rotor(angle: Float, line: @This()) @This() {
        return line.normalized().scale(@sin(angle / 2.0)).sadd(@cos(angle / 2.0));
    }

    pub fn translator(dist: Float, line: @This()) @This() {
        return line.scale(dist / 2.0).sadd(1.0);
    }

    /// A plane is defined using its homogenous equation ax + by + cz + d = 0
    pub fn plane(a: Float, b: Float, c: Float, d: Float) @This() {
        var res = zero;

        res.mvec.set(.e1, a);
        res.mvec.set(.e2, b);
        res.mvec.set(.e3, c);
        res.mvec.set(.e0, d);

        return res;
    }

    /// A point is just a homogeneous point, euclidean coordinates plus the origin
    pub fn point(x: Float, y: Float, z: Float) @This() {
        var res = zero;

        res.mvec.set(.e123, 1);
        res.mvec.set(.e032, x);
        res.mvec.set(.e013, y);
        res.mvec.set(.e021, z);

        return res;
    }

    pub fn get(self: @This(), b: basis) Float {
        return self.mvec.get(b);
    }

    pub fn getVec3(self: @This()) [3]f32 {
        return .{
            self.mvec.get(.e032),
            self.mvec.get(.e013),
            self.mvec.get(.e021),
        };
    }

    //     // for our toy problem (generate points on the surface of a torus)
    //     // we start with a function that generates motors.
    //     // circle(t) with t going from 0 to 1.
    //     pub fn circle(t: float_t, radius: float_t, line: Self) -> Self {
    //         Self::rotor(t * 2.0 * PI, line) * Self::translator(radius, e1 * e0)
    //     }

    //     // a torus is now the product of two circles.
    //     pub fn torus(s: float_t, t: float_t, r1: float_t, l1: Self, r2: float_t, l2: Self) -> Self {
    //         Self::circle(s, r2, l2) * Self::circle(t, r1, l1)
    //     }

    //     // and to sample its points we simply sandwich the origin ..
    //     pub fn point_on_torus(s: float_t, t: float_t) -> Self {
    //         let to: Self = Self::torus(s, t, 0.25, Self::e12(), 0.6, Self::e31());

    //         to * Self::e123() * to.Reverse()
    //     }

};

test {
    std.testing.refAllDeclsRecursive(@This());
}
// }

// fn main() {

//     // Elements of the even subalgebra (scalar + bivector + pss) of unit length are motors
//     let rot = PGA3D::rotor(PI / 2.0, e1 * e2);

//     // The outer product ^ is the MEET. Here we intersect the yz (x=0) and xz (y=0) planes.
//     let ax_z = e1 ^ e2;

//     // line and plane meet in point. We intersect the line along the z-axis (x=0,y=0) with the xy (z=0) plane.
//     let orig = ax_z ^ e3;

//     // We can also easily create points and join them into a line using the regressive (vee, &) product.
//     let px = PGA3D::point(1.0, 0.0, 0.0);
//     let line = orig & px;

//     // Lets also create the plane with equation 2x + z - 3 = 0
//     let p = PGA3D::plane(2.0, 0.0, 1.0, -3.0);

//     // rotations work on all elements
//     let rotated_plane = rot * p * rot.Reverse();
//     let rotated_line  = rot * line * rot.Reverse();
//     let rotated_point = rot * px * rot.Reverse();

//     // See the 3D PGA Cheat sheet for a huge collection of useful formulas
//     let point_on_plane = (p | px) * p;

//     // Some output
//     println!("a point       : {}", px);
//     println!("a line        : {}", line);
//     println!("a plane       : {}", p);
//     println!("a rotor       : {}", rot);
//     println!("rotated line  : {}", rotated_line);
//     println!("rotated point : {}", rotated_point);
//     println!("rotated plane : {}", rotated_plane);
//     println!("point on plane: {}", point_on_plane.normalized());
//     println!("point on torus: {}", PGA3D::point_on_torus(0.0, 0.0));

// }
