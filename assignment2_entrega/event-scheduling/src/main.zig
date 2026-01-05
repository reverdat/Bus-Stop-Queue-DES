const std = @import("std");

const json = std.json;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Random = std.Random;
const eql = std.mem.eql;
const Timer = std.time.Timer;
const Io = std.Io;

const heap = @import("structheap.zig");
const structs = @import("config.zig");

const Distribution = structs.Distribution;
const SimResults = structs.SimResults;
const SimConfig = structs.SimConfig;
const Stats = structs.Stats;
const User = structs.User;

const EventType = enum { arrival, service, boarding };

pub const Event = struct {
    time: f64,
    type: EventType,
    id: u64,
};


pub fn eventSchedulingBus(gpa: Allocator, random: Random, config: SimConfig, traca_writer: ?*Io.Writer) !SimResults {
    var hp = heap.Heap(Event).init();
    defer hp.deinit(gpa);

    var processed_events: u64 = 0;
    var t_clock: f64 = 0.0;

    // variables d'estat globals
    var num_passengers_queue: u64 = 0;
    var current_bus_capacity: u64 = 0;
    var lost_passengers: u64 = 0;
    var lost_buses: u64 = 0;
    var realized_bus_capacity: u64 = 0.0;
   
    var boarding_active: bool = false;
    
    // stats
    var area_queue: f64 = 0.0;
    var area_system: f64 = 0.0;
    var area_sq: f64 = 0.0;

    var last_event_time: f64 = 0.0;
    var event_id_counter: u64 = 0;
    
    // primera arribada de passatjer per començar la simulació
    const t_p = try config.passenger_interarrival.sample(random);
    event_id_counter += 1;
    try hp.push(gpa, Event{ .time = t_p, .type = .arrival, .id = event_id_counter });

    // primera arribada de bus per començar la simulació
    const t_b = try config.bus_interarrival.sample(random);
    event_id_counter += 1;
    try hp.push(gpa, Event{ .time = t_b, .type = .service, .id = event_id_counter });
   
    var bus_stop: ArrayList(User) = .empty;
    defer bus_stop.deinit(gpa);
    var first_user_in_queue: usize = 0;
    
    var current_bus_arrival: f64 = 0.0;
    var acc_boarding: f64 = 0.0;

    while (t_clock <= config.horizon and hp.len() > 0) : (processed_events += 1) {
        const next_event = hp.pop().?; // we use ? because we are absolutely sure there will be an element
        t_clock = next_event.time;
    
        if (traca_writer) |writer| {
            try writer.print("Estat {d}: ({d},{d}); t={d:.4}\n", .{
                processed_events, 
                num_passengers_queue, 
                current_bus_capacity, 
                t_clock
            });
        }
        const deltat = t_clock - last_event_time;

        const people_on_bus = realized_bus_capacity - current_bus_capacity;
        const system_size = num_passengers_queue + people_on_bus;
        area_queue += @as(f64, @floatFromInt(num_passengers_queue)) * deltat;   // n_j (t_j - t_i)
        area_system += @as(f64, @floatFromInt(system_size)) * deltat;           // L
        area_sq += @as(f64, @floatFromInt(system_size*system_size))*deltat;     // n_j**2 (t_j - t_i)
        

        switch (next_event.type) {
            EventType.arrival => { // passanger arrives

                event_id_counter += 1;
                const time_passanger = try config.passenger_interarrival.sample(random);
                const next_time = t_clock + time_passanger;

                try hp.push(gpa, Event{
                    .time = next_time,
                    .type = .arrival, //hostia que guapo
                    .id = event_id_counter,
                });

                // if the sistem is full, client is lost
                if (num_passengers_queue >= config.system_capacity) {
                    lost_passengers += 1;
                } else {
                    num_passengers_queue += 1; //len de passangers_in_queue
                    try bus_stop.append(gpa, User{ .id = processed_events, .arrival = t_clock });
                }
            },
            EventType.service => { // bus arrives
                // si ja hi ha un bus a la parada, poso la memòria a zero
                const time_bus = try config.bus_interarrival.sample(random);
                
                if (boarding_active) {
                    lost_buses += 1;
                    event_id_counter += 1;
                    try hp.push(gpa, Event{ .time = t_clock + time_bus, .type = .service, .id = event_id_counter });
                } else {
                    // com que no hi ha cap bus, genero la capacitat d'aquest
                    realized_bus_capacity = try config.bus_capacity.sampleInt(random);
                    try hp.push(gpa, Event{ .time = t_clock + time_bus, .type = .service, .id = event_id_counter });
                    
                    current_bus_capacity = realized_bus_capacity;                   
                    
                    // if we are NOT boarding start the boarding
                    if (num_passengers_queue > 0 and current_bus_capacity > 0 and boarding_active == false) {

                        event_id_counter += 1;
                        const duration = try config.boarding_time.sample(random);
                        
                        try hp.push(gpa, Event{ .time = t_clock + duration, .type = .boarding, .id = event_id_counter });

                        current_bus_arrival = t_clock;
                        (&bus_stop.items[first_user_in_queue]).*.boarding_time = duration;
                        boarding_active = true;
                    }

                }
            },
            EventType.boarding => { // passatjer ha pujat a l'autobus
                if (num_passengers_queue > 0 and current_bus_capacity > 0) {
                    // update leaving time of the queue
                    const leaving_user: *User = &bus_stop.items[first_user_in_queue];
                    leaving_user.*.about_to_board = current_bus_arrival + acc_boarding;
                    acc_boarding += leaving_user.*.boarding_time.?;
                    
                    leaving_user.*.queue_time = leaving_user.*.about_to_board.? - leaving_user.*.arrival;
                    leaving_user.*.enqueued_time = leaving_user.*.queue_time.? + leaving_user.*.boarding_time.?;

                    first_user_in_queue += 1;
                    
                    num_passengers_queue -= 1;
                    current_bus_capacity -= 1;

                    // si encara hi ha passatjers a la marquesina i el bus no és ple (segon fix a preguntar)
                    if (num_passengers_queue > 0 and current_bus_capacity > 0) {
                        event_id_counter += 1;
                        const duration = try config.boarding_time.sample(random);
                        
                        try hp.push(gpa, Event{ .time = t_clock + duration, .type = .boarding, .id = event_id_counter });

                        (&bus_stop.items[first_user_in_queue]).*.boarding_time = duration;
                        
                    } else {
                        boarding_active = false; //stop the boearding once there is no passnegers or the bus is full
                        
                        const passengers_on_bus = realized_bus_capacity - current_bus_capacity;
                        const start_index: usize = first_user_in_queue - passengers_on_bus;
                        
                        for (start_index..first_user_in_queue) |i| {
                            const user: *User = &bus_stop.items[i];
                            user.*.departure = t_clock;
                            user.*.service_time = t_clock - user.*.about_to_board.?;
                            user.*.total_time = user.*.queue_time.? + user.*.service_time.?;
                        }

                        acc_boarding = 0.0;
                        current_bus_capacity = 0;
                        realized_bus_capacity = 0;
                    }
                }
            },
        }

        last_event_time = t_clock;
    }
    
    if (traca_writer) |writer| {
        try writer.flush(); // Don't forget to flush! :)
    }

 
    // WAIT, this won't scale if you are too ambitious and run out of heap memory lol
    // as well as slowing down the function a lot!
    if (config.save_usertimes) {
        var usertimes_buffer: [64 * 1024]u8 = undefined; 
        const user_file = try std.fs.cwd().createFile("usertime.json", .{ .read = false });
        defer user_file.close();
       
        var usertime_writer = user_file.writer(&usertimes_buffer);
        var user_writer  = &usertime_writer.interface;
        try std.json.Stringify.value(bus_stop.items, .{ .whitespace = .indent_2 }, user_writer);
        try user_writer.flush();
    }

    const L = area_system / t_clock;
    return SimResults{
        .average_clients = area_system / t_clock,
        .variance = (area_sq / t_clock) - L*L,
        .duration = t_clock,
        .lost_passengers = lost_passengers,
        .lost_buses = lost_buses,
        .processed_events = processed_events,
        .average_queue_clients = area_queue / t_clock,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();    // set up the stdout buffer
    
    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    // argAlloc per a fer-ho correcte
    // const args = try std.process.argsAlloc(gpa);
    // defer std.process.argsFree(gpa, args);
    
    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rng = prng.random();

    const B=1;
    const horizon = 10000;
    const lambda = 5.0;
    const mu = 4.0;
    const x = 3;
    const k = 9;

    if (B == 1) {
        //const service_rates = [_]f64{ 3.0, 7.0 };

        const config = SimConfig{
            .horizon = horizon,
            .passenger_interarrival = Distribution{ .exponential = lambda }, // lambda
            .bus_interarrival = Distribution{ .exponential = mu },
            .bus_capacity = Distribution{ .constant = x }, // X
            .boarding_time = Distribution{ .constant = 1e-16 },
            .system_capacity = k, // K
            .save_usertimes = false,
        };

        try stdout.print("{f}\n", .{config});
        try stdout.print("Executing the simulation {d} times\n", .{B});
        try stdout.flush();
    
        var traca_buffer: [64 * 1024]u8 = undefined; 
        const traca_file = try std.fs.cwd().createFile("traca.txt", .{ .read = false });
        var traca_writer = traca_file.writer(&traca_buffer);
        const twriter  = &traca_writer.interface;
    
        var timer = try Timer.start();
        const results = try eventSchedulingBus(gpa, rng, config, twriter);
        const end = timer.read();

        const seconds = @as(f64, @floatFromInt(end)) / 1_000_000_000.0;

        try stdout.print("{f}\n", .{results});
        try stdout.print("Time Elapsed: {d:.4} seconds\n", .{seconds});
        try stdout.flush();
    } else {
        std.debug.print("\n", .{});
    //     const config = SimConfig{
    //         .horizon = horizon,
    //         .passenger_interarrival = Distribution{ .exponential = lambda }, // lambda
    //         .bus_interarrival = Distribution{ .exponential = mu }, // mu
    //         .bus_capacity = Distribution{ .constant = x }, // X
    //         .boarding_time = Distribution{ .constant = 1e-16 }, // minim perque no importa
    //         .system_capacity = k, // K
    //     };
    //
    //     try stdout.print("{f}\n", .{config});
    //     try stdout.print("Executing the simulation {d} times\n", .{B});
    //     try stdout.flush();
    //
    //     const L_vals = try gpa.alloc(f64, B);
    //     defer gpa.free(L_vals);
    //
    //     const t_vals = try gpa.alloc(f64, B);
    //     defer gpa.free(t_vals);
    //     var global_timer = try Timer.start();
    //
    //     for (0..B) |i| {
    //         var timer = try Timer.start();
    //
    //         const results = try eventSchedulingBus(gpa, rng, config);
    //
    //         const end = timer.read();
    //         const seconds = @as(f64, @floatFromInt(end)) / 1_000_000_000.0;
    //
    //         L_vals[i] = results.average_clients;
    //         t_vals[i] = seconds;
    //
    //         if (i%100 == 0) {
    //             const checkpoint = global_timer.read();
    //             const checkpoint_seconds = @as(f64, @floatFromInt(checkpoint)) / 1_000_000_000.0;
    //             try stdout.print("Done {d}/{d} iterations. Time Elapsed {d:.4}s.\n", .{i, B, checkpoint_seconds});
    //             try stdout.flush();
    //         }
    //     }
    //
    //     const total_time = @as(f64, @floatFromInt(global_timer.read())) /  1_000_000_000.0;
    //     const l_stats: Stats = Stats.calculateFromData(L_vals);
    //     const t_stats: Stats = Stats.calculateFromData(t_vals);
    //
    //     try stdout.writeAll("\n+----------------------+\n");
    //     try stdout.print("| BATCH RESULTS (B={d}) |\n", .{B});
    //     try stdout.writeAll("+----------------------+\n");
    //     try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Duration (s)", t_stats.mean, t_stats.ci });
    //     try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Queue (L)", l_stats.mean, l_stats.ci });
    //     try stdout.print("Total Time Elapsed: {d:.4}s\n", .{total_time});
    //     try stdout.flush();
    // }
    }
}
