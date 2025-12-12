const std = @import("std");
const heap = @import("heap.zig");
const rng = @import("rng.zig");
const sampleExp = rng.rexpSampleAlloc;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Random = std.Random;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(std.heap.DebugAllocatorConfig{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var hp = heap.Heap(u8).init();

    defer hp.deinit(allocator);

    const K: u64 = 9;
    const X: u64 = 3;
    const mu: f64 = 2.0;
    const lambda: f64 = 3.0;
}

const ServerState = enum { free, busy };
const EventType = enum { arrival, service };
const RNGError = error{ InvalidRange, NotAFloat };

const Event = struct { time: f64, type: EventType, client_id: u64 };

fn runif(comptime T: type, a: T, b: T, gen: *Random) !T {
    if (@typeInfo(T) != .float) {
        return RNGError.NotAFloat;
    }
    if (b < a) {
        return RNGError.InvalidRange;
    }
    return a + (b - a) * gen.float(T);
}

fn rexp(comptime T: type, lambda: T, gen: *Random) !T {
    const u = try runif(T, 0, 1, gen);
    const e: T = 1.0 / lambda * (-@log(u));
    return e;
}

fn eventScheduling(gpa: *std.Allocator, lambda: f64, mu: f64, x: u64, k: u64, horizon: f64) !void {
    var hp = heap.Heap(f64).init();
    defer hp.deinit(gpa);

    var hash = std.AutoHashMap(f64, EventType).init(gpa);
    defer hash.deinit();
    var t_clock: f64 = 0.0;

    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var gen = prng.random();

    const first_arrival: f64 = try rexp(f64, lambda, &gen);
    const arrival_event: Event = Event{ .time = first_arrival, .type = EventType.arrival, .client_id = 1 };
    hp.push(gpa, first_arrival);
    hash.put(first_arrival, arrival_event);

    while (t_clock <= horizon and hp.len() > 0) {
        const next_event_time = hp.pop().?;
        const next_event: Event = hash.get(next_event_time).?;

        // TODO: METRIQUES DE CUES
        switch (next_event.type) {
            EventType.arrival => {
                const next_arrival_time = try rexp(f64, lambda, &gen);
                hp.push(gpa, next_arrival_time);

                const new_arrival_event: Event = Event{ .time = first_arrival, .type = EventType.arrival, .client_id = 1 };
                hash.put(next_arrival_time, new_arrival_event);
            },
        }
    }
}
