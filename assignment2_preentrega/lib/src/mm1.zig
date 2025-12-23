const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Random = std.Random;

const heap = @import("structheap.zig");
const sampling = @import("rng.zig");
const runif = sampling.runif;
const rexp = sampling.rexp;

const ServerState = enum { free, busy };
const EventType = enum { arrival, service, boarding };

const Event = struct { time: f64, type: EventType, client_id: u64 };

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
    
    var area_under_q: f64 = 0.0;
    var last_event_time: f64 = 0.0;

    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var rng = prng.random();

    const first_arrival: f64 = try rexp(f64, lambda, &rng);
    const arrival_event: Event = Event{ .time = first_arrival, .type = EventType.arrival, .client_id = client_counter };

    try hp.push(gpa, arrival_event);
    
    while (t_clock <= horizon and hp.len() > 0) : (processed_events += 1) {
        const next_event = hp.pop().?;
        t_clock = next_event.time;
        
        // estem fent la integral :3
        area_under_q += @as(f64, @floatFromInt(num_clients_in_system)) * (t_clock - last_event_time);
        last_event_time = t_clock;

        switch (next_event.type) {
            EventType.arrival => {
                client_counter += 1;
                num_clients_in_system += 1;

                const next_arrival_time = try rexp(f64, lambda, &rng);
                const new_arrival_event: Event = Event{ .time = t_clock + next_arrival_time, .type = EventType.arrival, .client_id = client_counter };
                try hp.push(gpa, new_arrival_event);
        
                if (server_state == ServerState.free) {
                    server_state = ServerState.busy;
                    const next_service_time = try rexp(f64, mu, &rng);
                    const next_service_event: Event = Event{ .time = t_clock + next_service_time, .type = EventType.service, .client_id = client_counter };
                    try hp.push(gpa, next_service_event);
                }
            },
            EventType.service => {
                num_clients_in_system -= 1;

                if (num_clients_in_system > 0) {
                    const next_service_time: f64 = try rexp(f64, mu, &rng);
                    const next_service_event: Event = Event{ .time = t_clock + next_service_time, .type = EventType.service, .client_id = next_event.client_id + 1 };
                    try hp.push(gpa, next_service_event);
                } else {
                    server_state = ServerState.free;
                }
            },
            else => {}, 
        }
    }

    const average_clients = area_under_q / t_clock;

    print("----- Simulation finished! -----\n", .{});
    print("\tDuration: \t\t{e} \n\tEvents processed: \t{d} \n\tAverage clients (L): \t{e}", .{t_clock, processed_events, average_clients});
}


pub fn main() !void {
    var debug_gpa = std.heap.DebugAllocator(std.heap.DebugAllocatorConfig{}){};
    defer _ = debug_gpa.deinit();
    const gpa = debug_gpa.allocator();

    const K: u64 = 9;
    const X: u64 = 3;
    const mu: f64 = 1.0;
    const lambda: f64 = 0.5;

    print("Starting and MM1 silulation\n", .{});
    try eventSchedulingMM1(gpa, lambda, mu, X, K, 10000);
}


