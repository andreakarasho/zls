const std = @import("std");
const types = @import("../lsp.zig");
const offsets = @import("../offsets.zig");

const InternPool = @import("InternPool.zig");
const Index = InternPool.Index;
const Key = InternPool.Key;

pub const ErrorMsg = union(enum) {
    /// zig: expected type '{}', found '{}'
    expected_type: struct {
        expected: Index,
        actual: Index,
    },
    /// zig: comparison of '{}' with null
    compare_eq_with_null: struct {
        non_null_type: Index,
    },
    /// zig: tried to unwrap optional of type `{}` which was '{}'
    invalid_optional_unwrap: struct {
        operand: Index,
    },
    /// zig: type '{}' cannot represent integer value '{}'
    integer_out_of_range: struct {
        dest_ty: Index,
        actual: Index,
    },
    /// zig: expected {d} array elements; found 0
    wrong_array_elem_count: struct {
        expected: u32,
        actual: u32,
    },
    /// zig: expected optional type, found '{}'
    expected_optional_type: struct {
        actual: Index,
    },
    /// zig: expected error set type, found '{}'
    expected_error_set_type: struct {
        actual: Index,
    },
    /// zig: expected pointer, found '{}'
    expected_pointer_type: struct {
        actual: Index,
    },
    /// zig: type '{}' does not support indexing
    /// zig: operand must be an array, slice, tuple, or vector
    expected_indexable_type: struct {
        actual: Index,
    },
    /// zig: `{}` has no member '{s}'
    /// zig: `{}` does not support field access
    unknown_field: struct {
        accessed_ty: Index,
        field_name: []const u8,
    },

    const FormatContext = struct {
        error_msg: ErrorMsg,
        ip: *const InternPool,
    };

    pub fn fmt(self: ErrorMsg, ip: *const InternPool) std.fmt.Formatter(format) {
        return .{ .data = .{ .error_msg = self, .ip = ip } };
    }

    pub fn format(
        ctx: FormatContext,
        comptime fmt_str: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) @TypeOf(writer).Error!void {
        _ = options;
        const ip = ctx.ip;
        if (fmt_str.len != 0) std.fmt.invalidFmtError(fmt_str, ctx.error_msg);
        return switch (ctx.error_msg) {
            .expected_type => |info| std.fmt.format(
                writer,
                "expected type '{}', found '{}'",
                .{ info.expected.fmt(ip), ip.typeOf(info.actual).fmt(ip) },
            ),
            .compare_eq_with_null => |info| std.fmt.format(
                writer,
                "comparison of '{}' with null",
                .{info.non_null_type.fmt(ip)},
            ),
            .invalid_optional_unwrap => |info| blk: {
                const operand_ty = ip.typeOf(info.operand);
                const payload_ty = ip.indexToKey(operand_ty).optional_type.payload_type;
                break :blk std.fmt.format(
                    writer,
                    "tried to unwrap optional of type `{}` which was {}",
                    .{ payload_ty.fmt(ip), info.operand.fmt(ip) },
                );
            },
            .integer_out_of_range => |info| std.fmt.format(
                writer,
                "type '{}' cannot represent integer value '{}'",
                .{ info.dest_ty.fmt(ip), info.actual.fmt(ip) },
            ),
            .wrong_array_elem_count => |info| std.fmt.format(
                writer,
                "expected {d} array elements; found {d}",
                .{ info.expected, info.actual },
            ),
            .expected_optional_type => |info| std.fmt.format(
                writer,
                "expected optional type, found '{}'",
                .{info.actual.fmt(ip)},
            ),
            .expected_error_set_type => |info| std.fmt.format(
                writer,
                "expected error set type, found '{}'",
                .{info.actual.fmt(ip)},
            ),
            .expected_pointer_type => |info| std.fmt.format(
                writer,
                "expected pointer, found '{}'",
                .{info.actual.fmt(ip)},
            ),
            .expected_indexable_type => |info| std.fmt.format(
                writer,
                "type '{}' does not support indexing",
                .{info.actual.fmt(ip)},
            ),
            .unknown_field => |info| if (ip.canHaveFields(info.accessed_ty))
                std.fmt.format(
                    writer,
                    "`{}` has no member '{s}'",
                    .{ info.accessed_ty.fmt(ip), info.field_name },
                )
            else
                std.fmt.format(
                    writer,
                    "`{}` does not support field access",
                    .{info.accessed_ty.fmt(ip)},
                ),
        };
    }
};
