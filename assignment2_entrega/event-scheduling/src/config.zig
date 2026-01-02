const std = @import("std");
const Random = std.Random;
const ArrayList = std.ArrayList;
const Io = std.Io;

const main = @import("main.zig");
const Event = main.Event;
const sampling = @import("rng.zig");

/// Okay, aquí estaria la màgia...
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
    save_usertimes: bool = false,           // guardar o no els temps d'usuari
                  
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
    variance: f64,
    lost_passengers: u64,
    lost_buses: u64,
    processed_events: u64,
    average_queue_clients: f64,

    pub fn format(self: SimResults, writer: *Io.Writer) !void {
        try writer.writeAll("+-------------------+\n");
        try writer.print("| SIMULATION RESULT |\n", .{});
        try writer.writeAll("+-------------------+\n");
        try writer.print("{s: <24}: {d:.4} \n", .{ "Duration", self.duration});
        try writer.print("{s: <24}: {d} \n", .{"Events processed", self.processed_events});
        try writer.print("{s: <24}: {d:.4}\n", .{"Average Queue (L)", self.average_clients});
        try writer.print("{s: <24}: {d:.4}\n", .{"Average Queue (L_q)", self.average_queue_clients});
        try writer.print("{s: <24}: {d:.4}\n", .{"Variance (Var)", self.variance});
        try writer.print("{s: <24}: {d}\n", .{"Lost passengers", self.lost_passengers});
        try writer.print("{s: <24}: {d}\n", .{"Lost buses", self.lost_buses});
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


pub const User = struct {
    id: u64,
    arrival: f64,
    about_to_board: ?f64 = null,    // Estic apunt de pujar!
    boarded: ?f64 = null,           // He pujat i de fet estic assegut al bus (he tret l'Steam Deck per jugar, Sekiro en particular)!
    departure: ?f64 = null,         // Marxo amb els meus companys que me'ls estimo moltíssim!
    boarding_time: ?f64 = null,     // Temps que trigo a pujar a l'autobus
    queue_time: ?f64 = null,        // w_q: arrival + for (gent davant meu de la cua) boarding_time
    enqueued_time: ?f64 = null,     // queue_time + boarding_time (això és només perque la definició de l'esteve està terrible)
    service_time: ?f64 = null,      // w_s: temps que estàs dins  // w: suma de les dues anteriosde l'autobus
    total_time: ?f64 = null,        // w: suma de les dues anterios

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("User {d}\n", .{self.id});
        try writer.print("{s} at {f}\n", .{"Arrived", self.arrival});

        if (self.about_to_board) |atb| {
            try writer.print("{s} at {f}\n", .{"About to board", atb});
        } else {
            try writer.writerAll("User did not arrived at the first spot at the queue\n");
            return;
        }
        
        if (self.boarded) |b| {
            try writer.print("{s} at {f}\n", .{"Boarded", b});
        } else {
            try writer.writerAll("User did not board the bus\n");
            return;
        }
        
        if (self.departure) |dep| {
            try writer.print("{s} at {f}\n",  .{"Departure", dep});
        } else {
            try writer.writerAll("User did not get served.\n");
            return;
        }

        return;
    }
};
