const std = @import("std");

pub fn main() void {
    const i: usize = 4;
    if (i == 0) return 0;
    const result = @as(usize, (i - 1) / 2);
    try std.debug.print("{d}\n", .{result});
}
