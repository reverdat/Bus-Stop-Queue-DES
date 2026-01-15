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
const loader = @import("loader.zig");

const eventSchedulingBus = @import("simulation.zig").eventSchedulingBus;

const Distribution = structs.Distribution;
const SimResults = structs.SimResults;
const SimConfig = structs.SimConfig;
const Stats = structs.Stats;
const User = structs.User;


/// Hola Arnau! Sóc en Pau, i això és un todo del que ens falta fer :)
/// 1. Print de la Hypo, Hyper, kerlang, rexp_trunc ##### DONE
/// 2. L'string de help, igual que comprovar si algun dels arguments és help (està commentat al main) ##### DONE
/// 3. Calcular la mitjana dels waittimes dins de la funció i afergir-ho a sim results. Així i tot, l'anàlisi de dades el fem a python
/// 4. Mirar si podem escriure millor els strings dels usuaris mitjançant un format (eg, podem fer que sigui un csv si ho fem cleverly!)
/// 5. Ara mateix el tema de les unitats és un caos. Els json estan TOTS ens minuts, però no sé si és la mateixa pregunta
/// NOTA: ara, per no posar limits al sistema, system_capacity ha de ser 0 (es posa a maxInt a dins de la funció)
const HELP =
    \\Usage: busstop_simulation <config_filepath>
    \\
    \\Simulates a finite-capacity FIFO queuing system at a bus stop.
    \\
    \\Arguments:
    \\  <config_filepath> STR     Path to simulation config file (JSON).
    \\
    \\Options:
    \\  --info, -i                    Show the full simulation logic and state diagrams.
    \\  --help, -h                    Show this message and exit.
    \\
    \\CONFIG FILE STRUCTURE
    \\  The configuration file must be a valid JSON object containing:
    \\
    \\  {
    \\    "iterations": INT,      // Total number of simulation runs
    \\    "sim_config": {
    \\      "horizon": FLOAT,     // Max simulation time
    \\      "system_capacity": INT, // Max queue size (0 for infinite?)
    \\      
    \\      // Distributions for specific events:
    \\      "passenger_interarrival": DISTRIBUTION,
    \\      "bus_interarrival":       DISTRIBUTION,
    \\      "bus_capacity":           DISTRIBUTION,
    \\      "boarding_time":          DISTRIBUTION
    \\    }
    \\  }
    \\
    \\DISTRIBUTIONS
    \\  The fields marked DISTRIBUTION above accept a single object defining one
    \\  of the following probability distributions:
    \\
    \\  { "constant": FLOAT }
    \\      Degenerate r.v. with constant value.
    \\  
    \\  { "exponential": FLOAT }
    \\      Exponential distribution defined by rate.
    \\
    \\  { "uniform": { "min": FLOAT, "max": FLOAT } }
    \\      Uniform distribution between min and max.
    \\
    \\  { "hypo": [ FLOAT, ... ] }
    \\      Hypoexponential defined by a list of rates.
    \\
    \\  { "hyper": { "probs": [FLOAT, ...], "rates": [FLOAT, ...] } }
    \\      Hyperexponential defined by branching probabilities and rates.
    \\
    \\  { "erlang": { "k": INT, "lambda": FLOAT } }
    \\      k-Erlang distribution with rate (lambda).
    \\
    \\  { "exp_trunc": { "lambda": FLOAT, "max": FLOAT } }
    \\      Truncated exponential with rate (lambda) with a cutoff value (max).
;

const INFO =
    \\ BUS STOP SIMULATION
    \\ -------------------
    \\ DESCRIPTION
    \\     Simulates a queuing system at a bus stop consisting of two main components:
    \\     the Waiting Area (Arrivals) and the Bus (Service).
    \\ COMPONENTS
    \\     1. Waiting Area (Arrivals)
    \\         - Capacity: Finite limit K.
    \\         - Logic: Passengers arrive at random intervals τ_A(ω) and form a FIFO 
    \\             (First-In, First-Out) queue.
    \\         - Overflow: If the queue reaches capacity K, new arrivals are discarded.
    \\     2. Bus (Service)
    \\         - Capacity: Arrives with a specific capacity C(ω) at random interval τ_B(ω).
    \\         - Service: Boarding takes a random amount of time τ_C(ω) per passenger.
    \\         - Departure: The bus departs only when it is full OR when the waiting 
    \\             queue is empty.
    \\ 
    \\ We can represent the waiting system as the tuple
    \\     (n, c) = (Number of users in the waiting area, Remaining capacity of the bus) >= (0, 0)
    \\ with the following transition diagram: 
    \\
    \\     + When no user is at the stop (n=0):
    \\          
    \\                τ_A(ω): A user arrives to the stop
    \\          (0,0) ───────> (1,0)
    \\     
    \\     
    \\     + When no bus is at the stop (c = 0):
    \\     
    \\                τ_A(ω): A user arrives to the stop
    \\          (n,0) ───────> (n+1,0)
    \\            |
    \\            |
    \\            | τ_B(ω): A bus arrives with random capacity C(ω)
    \\            |
    \\            v
    \\          (n, C(ω))
    \\     
    \\     + When a bus is stationed at the stop (c > 0):
    \\     
    \\          (n-1,c-1)
    \\            ^
    \\             \
    \\              \
    \\               \ τ_C(ω): A user boards onto the bus
    \\                \
    \\                 \     τ_A(ω):  A user arrives to the stop
    \\                (n,c) ───────> (n+1,c)
;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator(); // set up the stdout buffer

    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    var bufferr: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&bufferr);
    const stderr = &stderr_writer.interface;

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len <= 1) {
        try stdout.print("Usage: <config_filepath> --iterations/-i <int>\n", .{});
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

    if (eql(u8, args[1], "-i") or
        eql(u8, args[1], "--info") or
        eql(u8, args[1], "info"))
    {
        try stdout.print("{s}\n", .{INFO});
        try stdout.flush();
        std.process.exit(0);
    }
    
    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rng = prng.random();

    const config_path = args[1];
    const override_iterations: ?u64 = if (args.len == 4 and (std.mem.eql(u8, args[2], "--iterations") or (std.mem.eql(u8, args[2], "-i")))) try std.fmt.parseInt(u64, args[3], 10) else null; 
    
    // We use a separate parsing_arena because the JSON parser allocates internal
    // slices (like the 'hypo' array) that must live as long as the config exists.
    var parsing_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer parsing_arena.deinit();
    const parsing_allocator = parsing_arena.allocator();

    const loaded_data = loader.loadConfig(parsing_allocator, config_path) catch |err| {
        try stderr.print("Error parsing the JSON: {any}", .{err});
        try stderr.flush();
        std.process.exit(0);
    };
    defer loaded_data.deinit();

    const app_config = loaded_data.value;
    const config = app_config.sim_config;
    const B = if (override_iterations) |iterations| iterations else app_config.iterations;
    //const B = app_config.iterations;

    try stdout.print("Loaded configuration from {s}\n", .{config_path});
    try stdout.print("Iterations (B): {d}\n", .{B});
    try stdout.print("{f}\n", .{config});
    try stdout.flush();

    if (B == 1) {
        try stdout.print("Running the simulation once, saving 'traca.txt' and 'usertimes.txt'\n", .{});
        try stdout.flush();

        var traca_buffer: [64 * 1024]u8 = undefined;
        const traca_file = try std.fs.cwd().createFile("traca.txt", .{ .read = false });
        var traca_writer = traca_file.writer(&traca_buffer);
        const twriter = &traca_writer.interface;

        var user_buffer: [64 * 1024]u8 = undefined;
        const user_file = try std.fs.cwd().createFile("usertimes.txt", .{ .read = false });
        var user_writer = user_file.writer(&user_buffer);
        const uwriter = &user_writer.interface;

        var timer = try Timer.start();
        const results = try eventSchedulingBus(gpa, rng, config, twriter, uwriter);
        const end = timer.read();

        const seconds = @as(f64, @floatFromInt(end)) / 1_000_000_000.0;

        try stdout.print("{f}\n", .{results});
        try stdout.print("Time Elapsed: {d:.4} seconds\n", .{seconds});
        try stdout.flush();
    } else {

        try stdout.print("Running the simulation {d} times\n", .{B});
        try stdout.flush();

        const L_vals = try gpa.alloc(f64, B);
        defer gpa.free(L_vals);

        const Lq_vals = try gpa.alloc(f64, B);
        defer gpa.free(L_vals);

        const t_vals = try gpa.alloc(f64, B);
        defer gpa.free(t_vals);

        const Wq_vals = try gpa.alloc(f64, B);
        defer gpa.free(Wq_vals);

        const Ws_vals = try gpa.alloc(f64, B);
        defer gpa.free(Ws_vals);

        const W_vals = try gpa.alloc(f64, B);
        defer gpa.free(W_vals);

        var global_timer = try Timer.start();

        for (0..B) |i| {
            var timer = try Timer.start();

            const results = try eventSchedulingBus(gpa, rng, config, null, null);

            const end = timer.read();
            const seconds = @as(f64, @floatFromInt(end)) / 1_000_000_000.0;

            L_vals[i] = results.average_clients;
            Lq_vals[i] = results.average_queue_clients;
            Wq_vals[i] = results.average_queue_time;
            Ws_vals[i] = results.average_service_time;
            W_vals[i] = results.average_total_time;
            t_vals[i] = seconds;
            
            const mod = @divTrunc(B, 10);
            if ((i + 1) % mod == 0) {
                const checkpoint = global_timer.read();
                const checkpoint_seconds = @as(f64, @floatFromInt(checkpoint)) / 1_000_000_000.0;
                try stdout.print("Done {d}/{d} iterations. Time Elapsed {d:.4}s.\n", .{ i + 1, B, checkpoint_seconds });
                try stdout.flush();
            }
        }

        const total_time = @as(f64, @floatFromInt(global_timer.read())) / 1_000_000_000.0;
        const l_stats: Stats = Stats.calculateFromData(L_vals);
        const lq_stats: Stats = Stats.calculateFromData(Lq_vals);
        const Wq_stats: Stats = Stats.calculateFromData(Wq_vals);
        const Ws_stats: Stats = Stats.calculateFromData(Ws_vals);
        const W_stats: Stats = Stats.calculateFromData(W_vals);
        const t_stats: Stats = Stats.calculateFromData(t_vals);

        try stdout.writeAll("\n+----------------------+\n");
        try stdout.print("| BATCH RESULTS (B={d}) |\n", .{B});
        try stdout.writeAll("+----------------------+\n");
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Duration (s)", t_stats.mean, t_stats.ci });
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Clients (L)", l_stats.mean, l_stats.ci });
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Clients Queue (L_q)", lq_stats.mean, lq_stats.ci });
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Queue Time (W_q)", Wq_stats.mean, Wq_stats.ci });
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Service Time (W_s)", Ws_stats.mean, Ws_stats.ci });
        try stdout.print("{s: <24}: {d:.4} +/- {d:.6} (95% CI)\n", .{ "Avg Total Time (W)", W_stats.mean, W_stats.ci });
        try stdout.print("Total Time Elapsed: {d:.4}s\n", .{total_time});
        try stdout.flush();
    }
}
