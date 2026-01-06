const std = @import("std");
const config_mod = @import("config.zig");
const SimConfig = config_mod.SimConfig;

pub const AppConfig = struct {
    iterations: usize,
    sim_config: SimConfig,
};

pub fn loadConfig(allocator: std.mem.Allocator, file_path: []const u8) !std.json.Parsed(AppConfig) {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const max_size = 1024 * 1024; // 1MB max config file
    const file_content = try file.readToEndAlloc(allocator, max_size);
    defer allocator.free(file_content);

    // We use .ignore_unknown_fields = true so comments or extra metadata in JSON don't crash it
    const options = std.json.ParseOptions{ .ignore_unknown_fields = true };
    
    // parsed_result holds the data AND the arena allocator used for strings/slices in the JSON
    const parsed_result = try std.json.parseFromSlice(AppConfig, allocator, file_content, options);

    return parsed_result;
}
