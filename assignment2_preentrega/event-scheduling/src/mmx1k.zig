const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Random = std.Random;

const heap = @import("structheap.zig"); 
const sampling = @import("rng.zig");

const EventType = enum { arrival, service, boarding };

const Event = struct {
    time: f64,
    type: EventType,
    id: u64,
};

/// Okay, aquí estaria la màgia...
/// TODO EXPLICAR BÉ
/// En essència la unió només conté una de les tres quan s'inicialitza
const Distribution = union(enum) {
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
};

/// Hi havia com moltes variables. He decidit per el "diccionari"
/// que diu l'Esteve però molt més eficient, és a dir, amb memòria
/// contigua
const SimConfig = struct {
    passenger_interarrival: Distribution,   // distribució que segueix l'arrivada de passatjers
    bus_interarrival: Distribution,         // distribució que segueix l'arrivada d'autobusos
    bus_capacity: Distribution,             // distribució que segueix la capacitat de l'autobus
    boarding_time: Distribution,            // distribució que segueix el temps de pujada d'un passatjer al bus
    system_capacity: u64,                   // sempre serà un nombre
    horizon: f64,                           // temps que dura la simulació
};

const SimResults = struct {
    duration: f64,
    average_clients: f64,
    lost_passengers: u64, 
    processed_events: u64,
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

    var area_under_q: f64 = 0.0;
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

    while (t_clock <= config.horizon and hp.len() > 0) : (processed_events += 1) {
        
        const next_event = hp.pop().?; // we use ? because we are pretty sure that cannot fail
        t_clock = next_event.time;

        // L_q = num_passengers_queue
        area_under_q += @as(f64, @floatFromInt(num_passengers_queue)) * (t_clock - last_event_time);
        last_event_time = t_clock;

        switch (next_event.type) { // passanger arrives
            EventType.arrival => {
                
                event_id_counter += 1;
                const time_passanger = try config.passenger_interarrival.sample(random);
                const next_time = t_clock + time_passanger;
                
                try hp.push(gpa, Event{ 
                    .time = next_time, 
                    .type = .arrival, 
                    .id = event_id_counter 
                });

                // if the sistem is full, client is lost
                if (num_passengers_queue >= config.system_capacity) {
                    lost_passengers += 1;
                } else {
                    num_passengers_queue += 1;
                }

            },
            EventType.service => { // bus arrives
                current_bus_capacity = try config.bus_capacity.sampleInt(random);

                event_id_counter += 1;
                const time_bus = try config.bus_interarrival.sample(random);
                const next_bus_time = t_clock + time_bus;
                
                try hp.push(gpa, Event{ 
                    .time = next_bus_time, 
                    .type = .service, 
                    .id = event_id_counter 
                });
                
                // Aquí hi ha un fix a preguntar:
                // Si podem començar el boarding directament ho fem oi?
                // (s'ha afegit el current_bus_capacity) en comptes de l'altre
                if (num_passengers_queue > 0 and current_bus_capacity > 0) { 
                    event_id_counter += 1;
                    const duration = try config.boarding_time.sample(random);
                    
                    try hp.push(gpa, Event{ 
                        .time = t_clock + duration, 
                        .type = .boarding, 
                        .id = event_id_counter 
                    });
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
                        
                        try hp.push(gpa, Event{ 
                            .time = t_clock + duration, 
                            .type = .boarding, 
                            .id = event_id_counter 
                        });
                    }
                }
            },
        }
    }

    return SimResults{
        .average_clients = area_under_q / t_clock,
        .duration = t_clock,
        .lost_passengers = lost_passengers,
        .processed_events = processed_events,
    };
}


pub fn main() !void {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_allocator.deinit();
    const gpa = gpa_allocator.allocator();

    // set up the stdout buffer
    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

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
    
    const config = SimConfig{
        .horizon = 100000.0,
        .passenger_interarrival = Distribution{ .exponential = 5.0 },   // lambda
        .bus_interarrival = Distribution{ .exponential = 2.0 },         // mu
        .bus_capacity = Distribution{ .constant = 3.0 },                // X
        .boarding_time = Distribution{ .constant = 1e-16 },              // minim perque no importa
        .system_capacity = 9,                                           // K
    };
    
    try stdout.print("SIMULATION START\n", .{});
    try stdout.flush();

    const results = try eventSchedulingBus(gpa, rng, config);

    try stdout.print("\nSIMULATION FINISH\n", .{});
    try stdout.print("\tDuration: \t\t{d:.4} \n", .{results.duration});
    try stdout.print("\tEvents processed: \t{d} \n", .{results.processed_events});
    try stdout.print("\tAvg Queue (L): \t\t{d:.4}\n", .{results.average_clients});
    try stdout.print("\tLost passengers: \t{d}\n", .{results.lost_passengers});
    try stdout.flush();
}
