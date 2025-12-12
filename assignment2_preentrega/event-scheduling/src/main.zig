const std = @import("std");
const print = std.debug.print;
const heap = @import("structheap.zig");
const rng = @import("rng.zig");
const sampleExp = rng.rexpSampleAlloc;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Random = std.Random;

pub fn main() !void {
    var debug_gpa = std.heap.DebugAllocator(std.heap.DebugAllocatorConfig{}){};
    defer _ = debug_gpa.deinit();
    const gpa = debug_gpa.allocator();

    const K: u64 = 9;
    const X: u64 = 3;
    const mu: f64 = 2.0;
    const lambda: f64 = 3.0;

    try eventSchedulingMM1(gpa, lambda, mu, X, K, 1000000);
}

const ServerState = enum { free, busy };
const EventType = enum { arrival, service, boarding };
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

fn eventSchedulingMM1(gpa: Allocator, lambda: f64, mu: f64, x: u64, k: u64, horizon: f64) !void {
    _ = x;
    _ = k;

    var hp = heap.Heap(Event).init();
    defer hp.deinit(gpa);
    var client_counter: u64 = 1;
    var processed_events: u64 = 0;
    var num_clients_in_system: u64 = 0;
    var server_state: ServerState = ServerState.free;
    var t_clock: f64 = 0.0;

    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var gen = prng.random();

    const first_arrival: f64 = try rexp(f64, lambda, &gen);
    const arrival_event: Event = Event{ .time = first_arrival, .type = EventType.arrival, .client_id = client_counter };

    try hp.push(gpa, arrival_event);

    while (t_clock <= horizon and hp.len() > 0) : (processed_events += 1) {
        const next_event = hp.pop().?;
        t_clock = next_event.time;

        // TODO: METRIQUES DE CUES
        switch (next_event.type) {
            EventType.arrival => {
                client_counter += 1;
                num_clients_in_system += 1;

                const next_arrival_time = try rexp(f64, lambda, &gen);
                const new_arrival_event: Event = Event{ .time = t_clock + next_arrival_time, .type = EventType.arrival, .client_id = client_counter };
                try hp.push(gpa, new_arrival_event);
                if (server_state == ServerState.free) {
                    server_state = ServerState.busy;
                    const next_service_time = try rexp(f64, mu, &gen);
                    const next_service_event: Event = Event{ .time = t_clock + next_service_time, .type = EventType.service, .client_id = client_counter };
                    try hp.push(gpa, next_service_event);
                }
            },
            EventType.service => {
                num_clients_in_system -= 1;

                if (num_clients_in_system > 0) {
                    const next_service_time: f64 = try rexp(f64, mu, &gen);
                    const next_service_event: Event = Event{ .time = t_clock + next_service_time, .type = EventType.service, .client_id = next_event.client_id + 1 };
                    try hp.push(gpa, next_service_event);
                } else {
                    server_state = ServerState.free;
                }
            },
        }
        print("{any}\n", .{hp.list.items});
    }
}

fn eventSchedulingBus(gpa: Allocator, lambda: f64, mu: f64, x: u64, horizon: f64) !void {
    _ = x;

    var hp = heap.Heap(Event).init();
    defer hp.deinit(gpa);
    var client_counter: u64 = 1;
    var processed_events: u64 = 0;
    var num_clients_in_system: u64 = 0;
    var server_state: ServerState = ServerState.free;
    var t_clock: f64 = 0.0;
    var current_bus_capacity: u64 = 0;

    const boarding_time: f64 = 1e-8;

    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var gen = prng.random();

    const first_passenger_time: f64 = try rexp(f64, lambda, &gen);
    const passenger_event: Event = Event{ .time = first_passenger_time, .type = EventType.arrival, .client_id = 1 };
    try hp.push(gpa, passenger_event);

    client_counter += 1;
    const first_bus_time: f64 = try rexp(f64, mu, &gen);
    const bus_event: Event = Event{ .time = first_bus_time, .type = EventType.service, .client_id = 2 };
    try hp.push(gpa, bus_event);

    client_counter = 3; // Comencem a contar a partir del tercer esdeveniment.

    while (t_clock <= horizon and hp.len() > 0) : (processed_events += 1) {
        const next_event = hp.pop().?;
        t_clock = next_event.time;

        // TODO: METRIQUES DE CUES
        switch (next_event.type) {
            EventType.arrival => {
                num_clients_in_system += 1;

                client_counter += 1;
                const next_arrival_time = try rexp(f64, lambda, &gen);
                const new_arrival_event: Event = Event{ .time = t_clock + next_arrival_time, .type = EventType.arrival, .client_id = client_counter };
                try hp.push(gpa, new_arrival_event);
            },
            EventType.service => {
                //num_clients_in_system -= 1;
                current_bus_capacity = k;

                if (num_clients_in_system > 0) {
                    const next_service_time: f64 = try rexp(f64, mu, &gen);
                    const next_service_event: Event = Event{ .time = t_clock + next_service_time, .type = EventType.service, .client_id = next_event.client_id + 1 };
                    try hp.push(gpa, next_service_event);
                } else {
                    server_state = ServerState.free;
                }
            },
        }
        print("{any}\n", .{hp.list.items});
    }
}
