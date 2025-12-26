const std = @import("std");
const Random = std.Random;
const ArrayList = std.ArrayList;
const Io = std.Io;

const main = @import("main.zig");
const Event = main.Event;
const sampling = @import("rng.zig");

/// Okay, aquí estaria la màgia...
/// TODO EXPLICAR BÉ
/// En essència la unió només conté una de les tres quan s'inicialitza
pub const Distribution = union(enum) {
    constant: f64,
    exponential: f64,
    uniform: struct { min: f64, max: f64 },

    pub fn sample(self: Distribution, rng: Random) !f64 {
        switch (self) {
            .constant => |val| return val,
            .exponential => |lambda| return sampling.rexp(f64, lambda, rng),
            .uniform => |p| return try sampling.runif(f64, p.min, p.max, rng),
        }
    }

    // Helper to get integer capacity (e.g. 3.0 -> 3)
    pub fn sampleInt(self: Distribution, rng: Random) !u64 {
        const samp = try self.sample(rng);
        return @as(u64, @intFromFloat(@round(samp)));
    }

    pub fn format(
        self: Distribution,
        writer: *std.Io.Writer,
    ) !void {
        switch (self) {
            .constant => |val| try writer.print("Const({d:.2})", .{val}),
            .exponential => |lambda| try writer.print("Exp(λ={d:.2})", .{lambda}),
            .uniform => |u| try writer.print("Uni({d:.1}, {d:.1})", .{ u.min, u.max }),
        }
    }
};

/// Hi havia com moltes variables. He decidit per el "diccionari"
/// que diu l'Esteve però molt més eficient, és a dir, amb memòria
/// contigua
pub const SimConfig = struct {
    passenger_interarrival: Distribution,   // distribució que segueix l'arrivada de passatjers
    bus_interarrival: Distribution,         // distribució que segueix l'arrivada d'autobusos
    bus_capacity: Distribution,             // distribució que segueix la capacitat de l'autobus
    boarding_time: Distribution,            // distribució que segueix el temps de pujada d'un passatjer al bus
    system_capacity: u64,                   // sempre serà un nombre
    horizon: f64,                           // temps que dura la simulació
    save_traca: bool = false,               // guardar o no la traca a un fitxer
                  
    pub fn format(
        self: SimConfig,
        writer: *std.Io.Writer,
    ) !void {

        try writer.writeAll("\n");
        try writer.writeAll("+--------------------------+\n");
        try writer.print("| SIMULATION CONFIGURATION |\n", .{});
        try writer.writeAll("+--------------------------+\n");
        try writer.print("{s: <24}:  {f}\n", .{ "Passenger Interarrival", self.passenger_interarrival });
        try writer.print("{s: <24}:  {f}\n", .{ "Bus Interarrival", self.bus_interarrival });
        try writer.print("{s: <24}:  {f}\n", .{ "Bus Capacity", self.bus_capacity });
        try writer.print("{s: <24}:  {f}\n", .{ "Boarding Time", self.boarding_time });
        try writer.writeAll("---------\n");
        try writer.print("{s: <24}:  {d: <23}\n", .{ "System Capacity", self.system_capacity });
        try writer.print("{s: <24}:  {d: <23.2}\n", .{ "Horizon (Time)", self.horizon });

    }
};

pub const SimResults = struct {
    duration: f64,
    average_clients: f64,
    lost_passengers: u64,
    processed_events: u64,
    traca: ?ArrayList(Event), //recordaque l'array list és un fat pointer, quan retornes això només estas copiant un punter a items i capaciy

    pub fn format(self: SimResults, writer: *Io.Writer) !void {
        try writer.writeAll("+-------------------+\n");
        try writer.print("| SIMULATION RESULT |\n", .{});
        try writer.writeAll("+-------------------+\n");
        try writer.print("{s: <24}: {d:.4} \n", .{ "Duration", self.duration});
        try writer.print("{s: <24}: {d} \n", .{"Events processed", self.processed_events});
        try writer.print("{s: <24}: {d:.4}\n", .{"Average Queue (L)", self.average_clients});
        try writer.print("{s: <24}: {d}\n", .{"Lost passengers", self.lost_passengers});
    }
};


pub const Stats = struct {
    mean: f64,
    ci: f64,

    pub fn calculateFromData(data: []f64) Stats {
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
};
