///https://www.openmymind.net/SIMD-With-Zig/#
const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.Random;
const eql = std.mem.eql;
const ArrayList = std.ArrayList;

const VEC_LEN = std.simd.suggestVectorLength(f64) orelse 16;

const RNGError = error{
    InvalidRange,
    NotAFloat
};

const HELP = 
    \\ This program generates four files containing samples of the following distributions:
    \\ - Uniform between 0, 1.
    \\ - Exponential: 
    \\ - Weibull: 
    \\ - Gamma: 
    \\ - Cauchy
    \\
    \\ The script requires an int n as the number of samples to generate. Feel free to write any number needed.  
;


pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var gpa = arena.allocator();

    // set up the stdout buffer
    var buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;
    
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 2) {
        try stdout.print("Usage: n <int> sample. Write --help for more\n", .{});
        try stdout.flush();
        std.process.exit(1); 
    }

    if (eql(u8, args[1], "-h") or
        eql(u8, args[1], "--help") or
        eql(u8, args[1], "help"))
    {
        try stdout.print("{s}\n", .{HELP});
        try stdout.flush();
        std.process.exit(1);
    }

    const sample = std.fmt.parseInt(u32, args[1], 10) catch |err| {
        try stdout.print("Invalid number to convert: {any}\n", .{err});
        try stdout.flush();
        std.process.exit(1);
    };

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var rand = prng.random();

 
    const T: type = f64; 
    const a = 0;
    const b = 1;
    // const lambda_w = 9.0;
    // const k = 2;
    // const x0 = 8;
    // const gamma = 7;
    // const lambda_e = 2;
    // const shape = 10;
    // const scale = 2.0;
    
    const trials = 100;
    var timer = try std.time.Timer.start();
    
    var total_simd: u64 = 0;
    for (0..trials) |_| {
        timer.reset();
        var unif_sample: ArrayList(T) = try runifSampleAllocSIMD(&gpa, sample, T, a, b, &rand);
        const d = timer.lap();
        unif_sample.deinit(gpa);
        total_simd +=d;
    }
    const avg_simd = @as(f64, @floatFromInt(total_simd)) / @as(f64, @floatFromInt(trials));
   
    // reset the allocator fr it to be competely fresh
    _ = arena.reset(.retain_capacity);
    
    var total_normal: u64 = 0;
    for (0..trials) |_| {
        timer.reset(); 
        var unif_sample2: ArrayList(T) = try runifSampleAlloc(&gpa, sample, T, a, b, &rand);
        const d = timer.lap();
        unif_sample2.deinit(gpa);
        total_normal += d;
    }
    const avg_normal = @as(f64, @floatFromInt(total_normal)) / @as(f64, @floatFromInt(trials));

    try stdout.print("Avg Time elapsed SIMD: {d}\n", .{avg_simd});
    try stdout.print("Avg Time elapsed norm: {d}\n", .{avg_normal});
    try stdout.print("Vector Size: {d}\n", .{VEC_LEN});

    try stdout.flush();
}

/// Generate a random number of a uniform distribution
/// in the interval [a,b].
fn runif(comptime T: type, a: T, b: T, rng: *Random) !T {
    if ((T != f32) and (T != f64)){
        return RNGError.NotAFloat;
    }
    
    if (b < a) {
        return RNGError.InvalidRange;
    }
    // scale if needed 
    return a + (b - a) * rng.float(T);
}

/// Generate an sample of a uniform distribution [a,b) 
fn runifSampleAlloc(allocator: *Allocator, n: u32, comptime T: type, a: T, b: T, rng: *Random) !ArrayList(T) {
    var sample: ArrayList(T) = .empty;
    try sample.ensureTotalCapacity(allocator.*, n);

    for (0..n) |_| {
        const u = try runif(T, a, b, rng);
        _ = try sample.append(allocator.*, u);
    }

    return sample;
}


/// Generate an sample of a uniform distribution [a,b) 
fn runifSampleAllocSIMD(allocator: *Allocator, n: u32, comptime T: type, a: T, b: T, rng: *Random) !ArrayList(T) {
    var sample: ArrayList(T) = .empty;
    try sample.ensureTotalCapacity(allocator.*, n);

    var rng_buff: [VEC_LEN]T = undefined;
    const min_vec: @Vector(VEC_LEN, T) = @splat(a);
    const range_vec: @Vector(VEC_LEN, T) = @splat(b - a);

    var pos: usize = 0;
    var left: usize = n;

    while (left > 0) {
                
        for (0..VEC_LEN) |i| {
            const u = rng.float(T); 
            rng_buff[i] = u; 
        } 

        const u_vec: @Vector(VEC_LEN, T) = rng_buff[0..VEC_LEN].*;
        const res_vec = min_vec + range_vec*u_vec;
        
        const res_arr: [VEC_LEN]T = res_vec;
        try sample.appendSlice(allocator.*, &res_arr); 

        pos += VEC_LEN;
        left -= VEC_LEN;
    } 
    
    if (left < VEC_LEN) {
        // si l'input és menor que el tamany, no facis SIMD
        for (0..left) |_| {
            const u = try runif(T, a,b, rng);
            _ = try sample.append(allocator.*, u);
        }        
    }

    return sample;
}


