const std = @import("std");
const geom = @import("geom");

const testing = std.testing;
const Wyhash = std.hash.Wyhash;

/// Don't really care which hash to use. Its just to force compiler to not optimize value away.
fn hash(hasher_ptr: anytype, key: anytype) void {
    inline for (@typeInfo(@TypeOf(key)).@"struct".fields) |field| {
        hasher_ptr.update(@ptrCast(&@field(key, field.name)));
    }
}

const FastMotor = extern struct {
    /// 1, e23, e31, e12
    rotator: Vec,
    /// e0123, e01, e02, e03
    translator: Vec,

    const id: FastMotor = .{
        .rotator = .{ 1, 0, 0, 0 },
        .translator = @splat(0),
    };

    const Vec = @Vector(4, f32);

    fn random(rand: std.Random) FastMotor {
        return .{
            .rotator = .{
                rand.float(f32),
                rand.float(f32),
                rand.float(f32),
                rand.float(f32),
            },
            .translator = .{
                rand.float(f32),
                rand.float(f32),
                rand.float(f32),
                rand.float(f32),
            },
        };
    }

    const Mask = @Vector(4, i32);
    fn swizzle(a: Vec, comptime mask: Mask) Vec {
        return @shuffle(f32, a, undefined, mask);
    }

    fn mul(m1: FastMotor, m2: FastMotor) FastMotor {
        @setFloatMode(.optimized);

        const a = m1.rotator;
        const b = m1.translator;
        const c = m2.rotator;
        const d = m2.translator;

        // -------------------------
        // ROTOR PART
        // -------------------------
        const a_xxxx = swizzle(a, .{ 0, 0, 0, 0 });
        const a_zyzw = swizzle(a, .{ 3, 2, 1, 2 });
        const a_ywyz = swizzle(a, .{ 2, 1, 3, 1 });
        const a_wzwy = swizzle(a, .{ 1, 3, 2, 3 });

        const c_wwyz = swizzle(c, .{ 2, 1, 3, 3 });
        const c_yzwy = swizzle(c, .{ 1, 3, 2, 1 });

        var e = a_xxxx * c;

        var t = a_ywyz * c_yzwy;
        t = t + (a_zyzw * swizzle(c, .{ 0, 0, 0, 2 }));
        t = -t;

        e = e + t;
        e = e - (a_wzwy * c_wwyz);

        // -------------------------
        // TRANSLATOR PART
        // -------------------------

        var f = a_xxxx * d;
        f = f + (b * swizzle(c, .{ 0, 0, 0, 0 }));
        f = f + (a_ywyz * swizzle(d, .{ 1, 3, 2, 1 }));
        f = f + (swizzle(b, .{ 2, 1, 3, 1 }) * c_yzwy);

        var t2 = a_zyzw * swizzle(d, .{ 0, 0, 0, 2 });
        t2 = t2 + (a_wzwy * swizzle(d, .{ 2, 1, 3, 3 }));
        t2 = t2 + (swizzle(b, .{ 0, 0, 0, 2 }) *
            swizzle(c, .{ 3, 2, 1, 2 }));
        t2 = t2 + (swizzle(b, .{ 1, 3, 2, 3 }) * c_wwyz);

        t2 = -t2;

        f = f - t2;

        return .{ .rotator = e, .translator = f };
    }

    /// Euclidean dot product: a0*b0 + a1*b1 + a2*b2 + a3*b3
    fn dot4(a: Vec, b: Vec) f32 {
        return @reduce(.Add, a * b);
    }

    /// Reciprocal square root with one Newton‑Raphson refinement.
    fn rsqrt_nr1(x: f32) f32 {
        const y = 1.0 / @sqrt(x);
        return y * (1.5 - 0.5 * x * y * y);
    }

    /// Reciprocal with one Newton‑Raphson refinement.
    fn rcp_nr1(x: f32) f32 {
        const y = 1.0 / x;
        return y * (2.0 - x * y);
    }

    /// Normalize this motor so that rotor part is unit and translator is adjusted.
    fn normalize(m: FastMotor) FastMotor {
        const b = m.rotator; // (a, b, c, d)
        const c = m.translator; // (h, e, f, g)  -- note: Klein stores (e0123, e01, e02, e03)

        // |b|^2 = a² + b² + c² + d²
        const b2 = dot4(b, b);

        // s = 1 / |b|
        const s_scalar = rsqrt_nr1(b2);
        const s = @as(Vec, @splat(s_scalar));

        // bc = -a*h + b*e + c*f + d*g
        // To compute, flip sign of 'a' (index 0) in b before dot with c.
        const b_flip_sign = @as(Vec, @bitCast(@as(@Vector(4, u32), @bitCast(b)) ^ @as(@Vector(4, u32), @splat(0x80000000))));
        const bc = dot4(b_flip_sign, c);

        // t = bc / (|b|^3) = bc * (1/|b|²) * s
        const t_scalar = bc * rcp_nr1(b2) * s_scalar;
        const t = @as(Vec, @splat(t_scalar));

        // New rotor: s * b
        const new_rot = b * s;

        // New translator: s * c - t * b
        // (Klein uses subtraction with sign flip on first component of t*b)
        const tb = @as(Vec, @bitCast(@as(@Vector(4, u32), @bitCast(b * t)) ^ @as(@Vector(4, u32), @splat(0x80000000))));
        const new_trans = c * s + tb; // note: tb already has first component sign‑flipped

        return .{ .rotator = new_rot, .translator = new_trans };
    }
};

fn multAllElements(GeomType: type, init: GeomType, mul: anytype, motors: []const GeomType) GeomType {
    @setFloatMode(.optimized);
    var result: GeomType = init;
    for (motors) |motor| {
        result = mul(result, motor).normalize();
        std.debug.print("result: {any}", .{result});
    }
    return result;
}

fn bench(
    io: std.Io,
    arena: std.mem.Allocator,
    GeomType: type,
    id: GeomType,
    number_of_motors: usize,
    random: std.Random,
) !void {
    const motors = try arena.alloc(GeomType, number_of_motors);

    for (motors) |*motor| {
        if (@hasDecl(GeomType, "random")) {
            motor.* = .random(random);
        } else {
            inline for (@typeInfo(GeomType).@"struct".fields) |field| {
                @field(motor, field.name) = (1 - random.float(f32)) * 2 * 1;
            }
            motor.* = geom.pga.normalized(motor.*);
        }
    }

    var total_hash: std.hash.Wyhash = .init(0);
    var delta_sum: std.Io.Timestamp = .zero;
    const repeats = 1;
    for (0..repeats) |_| {
        const time_start: std.Io.Timestamp = .now(io, .awake);
        const result = if (@hasDecl(GeomType, "mul"))
            multAllElements(GeomType, id, GeomType.mul, motors)
        else
            multAllElements(GeomType, id, geom.pga.geometricProduct, motors);

        const time_end: std.Io.Timestamp = .now(io, .awake);
        const delta = time_start.durationTo(time_end);

        hash(&total_hash, result);

        delta_sum = delta_sum.addDuration(delta);
    }
    const avarage_time_per_mult = @as(f64, @floatFromInt(delta_sum.nanoseconds)) / @as(f64, @floatFromInt(repeats * number_of_motors));

    std.debug.print("Time per mult: {d}ns hash: {d}\n", .{ avarage_time_per_mult, total_hash.final() });
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const number_of_motors = 1000;

    var random_state: std.Random.DefaultPrng = .init(0);
    const random = random_state.random();
    try bench(io, arena, FastMotor, .id, number_of_motors, random);
}
