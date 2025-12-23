const std = @import("std");
const py = @import("pydust");

const Random = std.Random;
const mmx1k = @import("mmx1k.zig");

const root = @This();

const PyDistribution = struct {
    type: []const u8, // "constant", "exponential", or "uniform"
    value: ?f64 = null, // optional, for constant and exponential
    min: ?f64 = null, // optional for uniform
    max: ?f64 = null, // optional for uniform
};

const PySimConfig = struct {
    passenger_interarrival: PyDistribution,
    bus_interarrival: PyDistribution,
    bus_capacity: PyDistribution,
    boarding_time: PyDistribution,
    system_capacity: u64,
    horizon: f64,
};

const PySimResults = struct {
    duration: f64,
    average_clients: f64,
    lost_passengers: u64,
    processed_events: u64,
};

fn toDistribution(py_dist: PyDistribution) !mmx1k.Distribution {
    if (std.mem.eql(u8, py_dist.type, "constant")) {
        if (py_dist.value == null) {
            return error.MissingConstantParameters;
        } else {
            return mmx1k.Distribution{ .constant = py_dist.value.? };
        }
    } else if (std.mem.eql(u8, py_dist.type, "exponential")) {
        if (py_dist.value == null) {
            return error.MissingExponentialParameters;
        } else {
            return mmx1k.Distribution{ .exponential = py_dist.value.? };
        }
    } else if (std.mem.eql(u8, py_dist.type, "uniform")) {
        if (py_dist.min == null or py_dist.max == null) {
            return error.MissingUniformParameters;
        } else {
            return mmx1k.Distribution{ .uniform = .{ .min = py_dist.min.?, .max = py_dist.max.? } };
        }
    } else {
        return error.InvalidDistributionType;
    }
}

pub fn eventSchedulingBus(args: struct { config: PySimConfig }) !PySimResults {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_allocator.deinit();
    const gpa = gpa_allocator.allocator();

    var prng = Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rng = prng.random();

    const zig_config = mmx1k.SimConfig{
        .passenger_interarrival = try toDistribution(args.config.passenger_interarrival),
        .bus_interarrival = try toDistribution(args.config.bus_interarrival),
        .bus_capacity = try toDistribution(args.config.bus_capacity),
        .boarding_time = try toDistribution(args.config.boarding_time),
        .system_capacity = args.config.system_capacity,
        .horizon = args.config.horizon,
    };

    const results = try mmx1k.eventSchedulingBus(gpa, rng, zig_config);

    return PySimResults{
        .duration = results.duration,
        .average_clients = results.average_clients,
        .lost_passengers = results.lost_passengers,
        .processed_events = results.processed_events,
    };
}

comptime {
    py.rootmodule(root);
}
