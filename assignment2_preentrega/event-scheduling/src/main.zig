const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Random = std.Random;
const eql = std.mem.eql;
const Timer = std.time.Timer;

const heap = @import("structheap.zig");
const structs = @import("config.zig");

const Distribution = structs.Distribution;
const SimResults = structs.SimResults;
const SimConfig = structs.SimConfig;

const EventType = enum { arrival, service, boarding };

pub const Event = struct {
    time: f64,
    type: EventType,
    id: u64,
};

pub fn eventSchedulingBus(gpa: Allocator, random: Random, config: SimConfig) !SimResults {
    var hp = heap.Heap(Event).init();
    defer hp.deinit(gpa);

    var processed_events: u64 = 0;
    var t_clock: f64 = 0.0;

    // variables d'estat globals
    var num_passengers_queue: u64 = 0;
    var current_bus_capacity: u64 = 0;
    var lost_passengers: u64 = 0;
    var boarding_active: bool = false;

    var area_queue: f64 = 0.0;
    //var area_system: f64 = 0.0;
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

    // guardem els passatjers amb quan arriben a la parada, quan marxen i la diferència
    // guardem l'ordre de tots els esdeveniments que han passat
    var traca: ArrayList(Event) = .empty;

    while (t_clock <= config.horizon and hp.len() > 0) : (processed_events += 1) {
        const next_event = hp.pop().?; // we use ? because we are pretty sure that cannot fail
        t_clock = next_event.time;
        try traca.append(gpa, next_event);

        const deltat = t_clock - last_event_time;

        // L_q = num_passengers_queue
        area_queue += @as(f64, @floatFromInt(num_passengers_queue)) * deltat;
        //   area_system += @as(f64, @floatFromInt(system_size)) * dt;
        last_event_time = t_clock;

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
                }
            },
            EventType.service => { // bus arrives
                current_bus_capacity = try config.bus_capacity.sampleInt(random);

                event_id_counter += 1;
                const time_bus = try config.bus_interarrival.sample(random);
                const next_bus_time = t_clock + time_bus;

                try hp.push(gpa, Event{ .time = next_bus_time, .type = .service, .id = event_id_counter });

                // if we are NOT boarding start the boarding
                if (num_passengers_queue > 0 and current_bus_capacity > 0 and boarding_active == false) {
                    event_id_counter += 1;
                    const duration = try config.boarding_time.sample(random);

                    try hp.push(gpa, Event{ .time = t_clock + duration, .type = .boarding, .id = event_id_counter });

                    // si arriba un bus i podem, començem el boarding
                    boarding_active = true;
                }
            },
            EventType.boarding => { // passatjer ha pujat a l'autobus
                if (num_passengers_queue > 0 and current_bus_capacity > 0) {
                    num_passengers_queue -= 1;
                    current_bus_capacity -= 1;

                    // si encara hi ha passatjers a la marquesina i el bus no és ple (segon fix a preguntar)
                    if (num_passengers_queue > 0 and current_bus_capacity > 0) {
                        event_id_counter += 1;
                        const duration = try config.boarding_time.sample(random);

                        try hp.push(gpa, Event{ .time = t_clock + duration, .type = .boarding, .id = event_id_counter });
                    } else {
                        boarding_active = false; //stop the boearding once there is no passnegers or the bus is full
                    }
                }
            },
        }
    }

    return SimResults{
        .average_clients = area_queue / t_clock,
        .duration = t_clock,
        .lost_passengers = lost_passengers,
        .processed_events = processed_events,
        .traca = traca,
    };
}

const HELP =
    \\This program runs a Simulation of an M/M^[X]/1/K system. 
    \\Both arrivals and services are Exp, with parameters lambda (arrivals) and mu (services).
    \\X is the batch services, and K is the maximum system clients.
    \\Boarding times are assumed to be negliglble (1e-16)
    \\Parameter B allows to run the simulation B times.
    \\
    \\Usage:
    \\      lambda  <f64>
    \\      mu      <f64>
    \\      X       <u64>
    \\      K       <u64>
    \\      horizon <f64>
    \\      B       <u64>
;

pub fn main() !void {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_allocator.deinit();
    const gpa = gpa_allocator.allocator();

    // set up the stdout buffer
    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    // argAlloc per a fer-ho correcte
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len != 7) {
        try stdout.print("Usage: lambda <float> mu <float> X <int> K <int> horizon <float> B <int>. Write --help for more\n", .{});
        try stdout.flush();
        std.process.exit(0);
    }

    if (eql(u8, args[1], "-h") or
        eql(u8, args[1], "--help") or
        eql(u8, args[1], "help"))
    {
        try stdout.print("{s}\n", .{HELP});
        try stdout.flush();
        std.process.exit(0);
    }

    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rng = prng.random();

    // per a una cua M/M^[X]/1/K considerem la configuració següent
    // Arribades de passatgers: exp(lambda)
    // Serveis de busos: exp(mu)
    // Capacitat del bus: X
    // Maxim nombre de persones a la marquesina: K
    const lambda = try std.fmt.parseFloat(f64, args[1]);
    const mu = try std.fmt.parseFloat(f64, args[2]);
    const x = try std.fmt.parseFloat(f64, args[3]);
    const k = try std.fmt.parseInt(u64, args[4], 10);
    const horizon = try std.fmt.parseFloat(f64, args[5]);
    const B = try std.fmt.parseInt(usize, args[6], 10);

    const config = SimConfig{
        .horizon = horizon,
        .passenger_interarrival = Distribution{ .exponential = lambda }, // lambda
        .bus_interarrival = Distribution{ .exponential = mu }, // mu
        .bus_capacity = Distribution{ .constant = x }, // X
        .boarding_time = Distribution{ .constant = 1e-16 }, // minim perque no importa
        .system_capacity = k, // K
    };

    try stdout.print("{f}\n", .{config});
    try stdout.flush();

    if (B == 1) {
        var timer = try Timer.start();
        var results = try eventSchedulingBus(gpa, rng, config);
        defer results.traca.deinit(gpa);
        const end = timer.read();

        const seconds = @as(f64, @floatFromInt(end)) / 1_000_000_000.0;

        try stdout.print("{f}\n", .{results});
        try stdout.print("Time Elapsed: {d:.4} seconds\n", .{seconds});
        try stdout.flush();
    } else {
        const L_vals = try gpa.alloc(f64, B);
        defer gpa.free(L_vals);

        const t_vals = try gpa.alloc(f64, B);
        defer gpa.free(t_vals);

        for (0..B) |i| {
            var timer = try Timer.start();

            var results = try eventSchedulingBus(gpa, rng, config);
            defer results.traca.deinit(gpa);

            const end = timer.read();
            const seconds = @as(f64, @floatFromInt(end)) / 1_000_000_000.0;

            L_vals[i] = results.average_clients;
            t_vals[i] = seconds;
        }

        const Stats = struct { mean: f64, ci: f64 };

        const calculate_stats = struct {
            fn run(data: []f64) Stats {
                var sum: f64 = 0.0;
                for (data) |v| sum += v;
                const mean = sum / @as(f64, @floatFromInt(data.len));

                var sum_sq_diff: f64 = 0.0;
                for (data) |v| {
                    const diff = v - mean;
                    sum_sq_diff += diff * diff;
                }

                const variance = sum_sq_diff / @as(f64, @floatFromInt(data.len - 1));
                const std_dev = std.math.sqrt(variance);

                const margin_error = 1.96 * (std_dev / std.math.sqrt(@as(f64, @floatFromInt(data.len))));

                return Stats{ .mean = mean, .ci = margin_error };
            }
        }.run;

        const l_stats = calculate_stats(L_vals);
        const t_stats = calculate_stats(t_vals);

        try stdout.writeAll("\n+-------------------+\n");
        try stdout.print("| BATCH RESULTS (B={d})|\n", .{B});
        try stdout.writeAll("+-------------------+\n");
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Duration (s)", t_stats.mean, t_stats.ci });
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Queue (L)", l_stats.mean, l_stats.ci });

        try stdout.flush();
    }
}
