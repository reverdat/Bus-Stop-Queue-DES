const std = @import("std");
const MultiArrayList = std.MultiArrayList;

const Representation = enum {hello, bye};

const Complex = struct {
    a: f32,
    b: f32,
    r: Representation,
};

pub fn main() !void {
    var list = MultiArrayList(Complex){};
    const a = std.heap.page_allocator;

    const c1 = Complex{.a = 3.0, .b = 4.0, .r = Representation.hello}; 
    try list.append(a, c1);

    std.debug.print("{any}\n", .{list});
    std.debug.print("{any}\n", .{list.items[0]});
}

