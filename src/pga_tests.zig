const std = @import("std");

const pga = @import("geom.zig").pga;

const mult = pga.mult;
const add = pga.add;
const expectApproxEqualIgnoreNorm = pga.expectApproxEqualIgnoreNorm;
const point = pga.point;
const orhogonalProjection = pga.orhogonalProjection;
const sandwichProduct = pga.sandwichProduct;
const regressiveProduct = pga.regressiveProduct;
const equal = pga.equal;
const RegressiveProduct = pga.RegressiveProduct;
const outerProduct = pga.outerProduct;
const OuterProduct = pga.OuterProduct;
const Product = pga.Product;
const innerProduct = pga.innerProduct;
const InnerProduct = pga.InnerProduct;
const iDual = pga.iDual;
const dual = pga.dual;
const DualWithBasis = pga.DualWithBasis;
const xorBlade = pga.xorBlade;
const iNorm = pga.iNorm;
const norm = pga.norm;
const reverse = pga.reverse;
const involute = pga.involute;
const reduce = pga.reduce;
const expectEqual = pga.expectEqual;
const geometricProduct = pga.geometricProduct;
const normalized = pga.normalized;
const expectApproxEqualRel = pga.expectApproxEqualRel;
const sqrt = pga.sqrt;
const GeometricProduct = pga.GeometricProduct;
const collapseBlade = pga.collapseBlade;
const same = pga.same;
const Basis = @import("geom.zig").PGABasis;
const sameSign = pga.sameSign;
const getFieldNameFromBlade = pga.getFieldNameFromBlade;
const primitive = @import("geom.zig").pga_primitive;
const Sign = @import("geom.zig").Sign;

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
test GeometricProduct {
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Motor, primitive.Motor));
    try std.testing.expectEqual(primitive.Translator, GeometricProduct(primitive.Translator, primitive.Translator));
    try std.testing.expectEqual(primitive.Rotor, GeometricProduct(primitive.Rotor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Motor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Translator, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, GeometricProduct(primitive.Plane, primitive.Plane));
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
test iNorm {
    try std.testing.expectEqual(@sqrt(@as(f32, 0)), iNorm(.{
        .e1 = 1,
    }));
    try std.testing.expectEqual(@sqrt(@as(f32, 1)), iNorm(.{
        .e0 = 1,
    }));
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
test DualWithBasis {
    try std.testing.expectEqual(
        primitive.Plane,
        DualWithBasis(
            primitive.Point,
            Basis.pseudo_vector,
        ),
    );
}
test dual {
    @setEvalBranchQuota(1000000);
    inline for (@typeInfo(primitive.Multivector).@"struct".field_names) |name| {
        var blade: primitive.Multivector = .{};
        @field(blade, name) = 1;

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
test InnerProduct {
    try std.testing.expectEqual(primitive.Scalar, InnerProduct(primitive.Point, primitive.Point));
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
test Product {
    try std.testing.expectEqual(primitive.Scalar, Product(primitive.Point, primitive.Point, .inner));
    try std.testing.expectEqual(primitive.Translator, Product(primitive.Point, primitive.Point, .geometric));
    try std.testing.expectEqual(primitive.Point, Product(primitive.Line, primitive.Plane, .outer));
}
test OuterProduct {
    try std.testing.expectEqual(primitive.Motor, OuterProduct(primitive.Motor, primitive.Motor));
    try std.testing.expectEqual(primitive.Translator, OuterProduct(primitive.Translator, primitive.Translator));
    try std.testing.expectEqual(primitive.Rotor, OuterProduct(primitive.Rotor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, OuterProduct(primitive.Motor, primitive.Rotor));
    try std.testing.expectEqual(primitive.Motor, OuterProduct(primitive.Translator, primitive.Rotor));
    try std.testing.expectEqual(primitive.Line, OuterProduct(primitive.Plane, primitive.Plane));
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
test RegressiveProduct {
    try std.testing.expectEqual(primitive.Line, RegressiveProduct(primitive.Point, primitive.Point));
    try std.testing.expectEqual(primitive.Plane, RegressiveProduct(primitive.Point, primitive.Line));
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
test normalized {
    try std.testing.expectEqual(1, norm(normalized(primitive.Line{
        .e12 = 2,
    })));
    try std.testing.expectEqual(1, norm(normalized(primitive.Line{
        .e01 = 1,
        .e12 = 1,
    })));
}
