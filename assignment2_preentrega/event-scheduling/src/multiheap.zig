const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const swap = std.mem.swap;

/// Implementació d'un MinHeap molt rudimentaria, però
/// absolutament eficient.
///
/// - push: afegeix un valor al heap
/// - pop: elimina el minim del min heap
/// - peek: mostra quin és el menor valor al heap
pub fn MultiHeap(comptime T: type) type {
    const type_info = @typeInfo(T);
    if (type_info != .int and type_info != .float) @compileError("Just integers and floats allowed.\n");

    return struct {
        const Self = @This();

        list: ArrayList(T),

        pub fn init() Self {
            return Self{
                .list = .empty,
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.list.deinit(allocator);
        }

        pub fn len(self: *Self) usize {
            return self.list.items.len;
        }

        fn getParentIndex(i: usize) usize {
            if (i == 0) return 0;
            return (i - 1) / 2;
        }

        fn getLeftChildIndex(i: usize) usize {
            return 2 * i + 1;
        }

        fn getRightChildIndex(i: usize) usize {
            return 2 * i + 2;
        }

        pub fn push(self: *Self, gpa: Allocator, value: T) !void {
            try self.list.append(gpa, value);
            var child_index: usize = self.list.items.len - 1;
            var parent_index: usize = getParentIndex(child_index);

            while (self.list.items[child_index] < self.list.items[parent_index]) {
                swap(T, &self.list.items[parent_index], &self.list.items[child_index]);
                child_index = parent_index;
                parent_index = getParentIndex(child_index);
            }

            return;
        }

        pub fn pop(self: *Self) ?T {
            if (self.list.items.len == 0) return null;

            const min = self.list.swapRemove(0);

            if (self.list.items.len == 0) return min;

            var parent_index: usize = 0;

            while (true) {
                const lchild_index = getLeftChildIndex(parent_index);
                const rchild_index = getRightChildIndex(parent_index);

                var smallest_index = parent_index; // assume parent_index is the smallest
                const items = self.list.items;

                if (lchild_index < items.len and items[lchild_index] < items[smallest_index]) {
                    smallest_index = lchild_index;
                }

                if (rchild_index < items.len and items[rchild_index] < items[smallest_index]) {
                    smallest_index = rchild_index;
                }

                if (smallest_index == parent_index) {
                    break;
                }

                swap(T, &items[parent_index], &items[smallest_index]);

                parent_index = smallest_index;
            }

            return min;
        }

        pub fn peek(self: *Self) ?T {
            if (self.list.items.len == 0) return null;
            return self.list.items[0];
        }
    };
}

test "MinHeap Integers" {
    const a = std.testing.allocator;

    var heap = Heap(i32).init();
    defer heap.deinit(a);

    try heap.push(a, 10);
    try heap.push(a, 5);
    try heap.push(a, 20);
    try heap.push(a, 2);

    try std.testing.expectEqual(@as(?i32, 2), heap.pop());
    try std.testing.expectEqual(@as(?i32, 5), heap.pop());
    try std.testing.expectEqual(@as(?i32, 10), heap.pop());
    try std.testing.expectEqual(@as(?i32, 20), heap.pop());
    try std.testing.expectEqual(@as(?i32, null), heap.pop());
}

test "MinHeap - Edge Cases" {
    const a = std.testing.allocator;
    var heap = Heap(i32).init();
    defer heap.deinit(a);

    // Pop from empty
    try std.testing.expectEqual(@as(?i32, null), heap.pop());

    // Single Element
    try heap.push(a, 42);
    try std.testing.expectEqual(@as(?i32, 42), heap.pop());

    // Heap should be empty again
    try std.testing.expectEqual(@as(?i32, null), heap.pop());

    // Negative Numbers
    try heap.push(a, -5);
    try heap.push(a, -10);
    try heap.push(a, 0);

    try std.testing.expectEqual(@as(?i32, -10), heap.pop());
    try std.testing.expectEqual(@as(?i32, -5), heap.pop());
    try std.testing.expectEqual(@as(?i32, 0), heap.pop());
}

test "MinHeap - Duplicates" {
    const a = std.testing.allocator;
    var heap = Heap(i32).init();
    defer heap.deinit(a);

    try heap.push(a, 5);
    try heap.push(a, 1);
    try heap.push(a, 5);
    try heap.push(a, 1);
    try heap.push(a, 5);

    // Should retrieve: 1, 1, 5, 5, 5
    try std.testing.expectEqual(@as(?i32, 1), heap.pop());
    try std.testing.expectEqual(@as(?i32, 1), heap.pop());
    try std.testing.expectEqual(@as(?i32, 5), heap.pop());
    try std.testing.expectEqual(@as(?i32, 5), heap.pop());
    try std.testing.expectEqual(@as(?i32, 5), heap.pop());
}
