const std = @import("std");
const Queue = @import("day10.zig").Queue;
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.smp_allocator;

const GraphNode = struct {
    name: []const u8,
    next_nodes: std.ArrayList([]const u8),
};

pub fn MemGraph() type {
    const Child = []const u8;
    return struct {
        const Self = @This();
        pub const Node = struct {
            data: Child,
            next: std.ArrayList(*Node) = .empty,
            path_count: usize = 0,
        };
        const CacheContext = struct {
            pub fn hash(ctx: @This(), key: struct { *Node, bool, bool }) u64 {
                _ = ctx;
                var h = std.hash.Fnv1a_64.init();
                h.update(key.@"0".data);
                const tmp: [2]u8 = .{ @as(u8, @intFromBool(key.@"1")), @as(u8, @intFromBool(key.@"2")) };
                h.update(&tmp);
                const final_hash = h.final();
                //print("Hash: {d}\n", .{final_hash});
                return final_hash;
            }
            pub fn eql(ctx: @This(), a: struct { *Node, bool, bool }, b: struct { *Node, bool, bool }) bool {
                _ = ctx;
                return std.mem.eql(u8, a.@"0".data, b.@"0".data) and
                    a.@"1" == b.@"1" and
                    a.@"2" == b.@"2";
            }
        };
        gpa: std.mem.Allocator,
        nodes: std.ArrayList(*Node),
        cache_map: std.HashMap(struct { *Node, bool, bool }, usize, CacheContext, 80),
        pub fn init(gpa: std.mem.Allocator) Self {
            return Self{
                .gpa = gpa,
                .nodes = .empty,
                .cache_map = .init(gpa),
            };
        }
        pub fn deinit(self: *Self) void {
            for (self.nodes.items) |value| {
                value.next.deinit(self.gpa);
                self.gpa.destroy(value);
            }
            self.nodes.deinit(self.gpa);
            self.cache_map.deinit();
        }
        pub fn insert(self: *Self, new_value: Child, connections: ?[]Child) !*Node {
            var new_node: *Node = undefined;
            if (self.find_node(new_value)) |node| {
                new_node = node;
            } else {
                new_node = try self.gpa.create(Node);
                new_node.* = .{ .data = try self.gpa.dupe(u8, new_value) };
                try self.nodes.append(self.gpa, new_node);
            }
            if (connections == null) {
                return new_node;
            }
            for (connections.?) |connection| {
                if (self.find_node(connection)) |node_connection| {
                    try new_node.next.append(self.gpa, node_connection);
                } else {
                    const node_connection = try self.insert(connection, null);
                    try new_node.next.append(self.gpa, node_connection);
                }
            }
            return new_node;
        }
        pub fn find_node(self: *Self, value: Child) ?*Node {
            for (self.nodes.items) |node| {
                if (std.mem.eql(u8, node.data, value)) {
                    return node;
                }
            }
            return null;
        }
        pub fn recursive_path_count(self: *Self, current_node: *Node, visited_dac: bool, visited_fft: bool) !usize {
            if (self.cache_map.get(.{ current_node, visited_dac, visited_fft })) |path_count| {
                //print("Cache Hit!\n", .{});
                return path_count;
            }
            var fft = visited_fft;
            var dac = visited_fft;
            if (std.mem.eql(u8, current_node.data, "out")) {
                var result: usize = 0;
                if (visited_dac or visited_fft) {
                    print("Found End\n", .{});
                    result = 1;
                } else {
                    print("No End\n", .{});
                    result = 0;
                }
                try self.cache_map.put(.{ current_node, visited_dac, visited_fft }, result);
                return result;
            } else if (std.mem.eql(u8, current_node.data, "fft")) {
                fft = true;
            } else if (std.mem.eql(u8, current_node.data, "dac")) {
                dac = true;
            }
            var count: usize = 0;
            for (current_node.next.items) |value| {
                count += try self.recursive_path_count(value, dac, fft);
            }
            try self.cache_map.put(.{ current_node, dac, fft }, count);
            return count;
        }
        pub fn reset_cache(self: *Self) !void {
            self.cache_map.deinit();
            self.cache_map = .init(self.gpa);
        }
    };
}

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day11.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var nodes: std.ArrayList(GraphNode) = .empty;
    defer nodes.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var line_node_iter = std.mem.splitSequence(u8, line, ": ");
        const node_name = line_node_iter.next().?;
        const connections_raw = line_node_iter.next().?;
        var line_iter = std.mem.splitScalar(u8, connections_raw, ' ');
        var connections: std.ArrayList([]const u8) = .empty;
        while (line_iter.next()) |node_conn| {
            try connections.append(allocator, try allocator.dupe(u8, node_conn));
        }
        try nodes.append(allocator, .{ .name = try allocator.dupe(u8, node_name), .next_nodes = connections });
    }
    try nodes.append(allocator, .{ .name = "out", .next_nodes = .empty });

    var mem_graph = MemGraph().init(allocator);
    for (nodes.items) |g_node| {
        _ = try mem_graph.insert(g_node.name, g_node.next_nodes.items);
    }

    {
        const start = "you";
        const start_node = mem_graph.find_node(start).?;

        const path_count = try mem_graph.recursive_path_count(start_node, true, true);
        print("Possible Paths {d}\n", .{path_count});
    }
    try mem_graph.reset_cache();
    {
        const start = "svr";
        const start_node = mem_graph.find_node(start).?;

        const path_count = try mem_graph.recursive_path_count(start_node, false, false);

        print("Possible Problematic Paths {d}\n", .{path_count});
    }
}
