const std = @import("std");
const Queue = @import("day10.zig").Queue;
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.smp_allocator;

const GraphNode = struct {
    name: []const u8,
    next_nodes: std.ArrayList([]const u8),
};

const Graph = struct {
    nodes: std.ArrayList(GraphNode) = .empty,
    fn get_connections_of(self: *const Graph, node_to_search: []const u8) ?*const std.ArrayList([]const u8) {
        for (self.nodes.items) |node| {
            if (std.mem.eql(u8, node.name, node_to_search)) {
                return &node.next_nodes;
            }
        }
        print("Could not Find Value: {s}\n", .{node_to_search});
        return null;
    }
};

pub fn ReverseTree(comptime Child: type) type {
    return struct {
        const Self = @This();
        pub const Node = struct {
            data: Child,
            previous: ?*Node,
            leaf: bool = true,
        };
        gpa: std.mem.Allocator,
        nodes: std.ArrayList(*Node),
        cmp_fn: *const fn (Child, Child) bool,

        pub fn init(gpa: std.mem.Allocator, comp_fcn: fn (Child, Child) bool) Self {
            return Self{
                .gpa = gpa,
                .nodes = .empty,
                .cmp_fn = comp_fcn,
            };
        }
        pub fn deinit(self: *Self) void {
            for (self.nodes.items) |value| {
                self.gpa.destroy(value);
            }
            self.nodes.deinit(self.gpa);
        }
        pub fn insert(self: *Self, prev_node: ?*Node, new_value: Child) !*Node {
            const new_node = try self.gpa.create(Node);
            new_node.* = .{ .data = new_value, .previous = prev_node };
            if (prev_node == null and self.nodes.items.len != 0) {
                self.gpa.destroy(new_node);
                return error.NoParentNodeProvided;
            }
            if (prev_node != null) {
                prev_node.?.leaf = false;
            }
            try self.nodes.append(self.gpa, new_node);
            return new_node;
        }
        pub fn count_leafs_with_data(self: *const Self, data: Child) usize {
            var counter: usize = 0;
            for (self.nodes.items) |node| {
                if (node.leaf and self.cmp_fn(node.data, data)) {
                    counter += 1;
                }
            }
            return counter;
        }
        pub fn find_value_in_branch(self: *const Self, start_node: *const Node, value: Child) bool {
            var current_node = start_node;
            while (current_node.previous) |node| {
                if (self.cmp_fn(current_node.data, value)) {
                    return true;
                }
                current_node = node;
            }
            return false;
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

    const node_graph = Graph{ .nodes = nodes };

    const str_eql_fcn = struct {
        pub fn eql(fst: []const u8, snd: []const u8) bool {
            return std.mem.eql(u8, fst, snd);
        }
    }.eql;

    const path_count_fn = struct {
        pub fn get_path_count(start: []const u8, end: []const u8, node_graph_local: *const Graph) !usize {
            var next_node_to_check = Queue(*ReverseTree([]const u8).Node).init(allocator);
            defer next_node_to_check.deinit();

            var path_tree = ReverseTree([]const u8).init(allocator, str_eql_fcn);
            defer path_tree.deinit();

            const node_ptr = try path_tree.insert(null, start);
            try next_node_to_check.enqueue(node_ptr);

            while (next_node_to_check.dequeue()) |node| {
                if (str_eql_fcn(node.data, end)) {
                    continue;
                }
                //print("{s}\n", .{node.data});
                const g_node = node_graph_local.get_connections_of(node.data).?;
                for (g_node.items) |next_node| {
                    if (path_tree.find_value_in_branch(node, next_node)) {
                        continue;
                    }
                    //print("Next node: {s}\n", .{next_node});
                    const next_node_ptr = try path_tree.insert(node, next_node);
                    try next_node_to_check.enqueue(next_node_ptr);
                }
            }

            const path_count = path_tree.count_leafs_with_data(end);
            return path_count;
        }
    }.get_path_count;
    {
        const start = "you";
        const end = "out";

        const path_count = try path_count_fn(start, end, &node_graph);
        print("Possible Paths {d}\n", .{path_count});
    }

    {
        const start = "svr";
        const end = "out";
        const checkpoint_1 = "fft";
        const checkpoint_2 = "dac";

        const start_checkpoint_1 = try path_count_fn(start, checkpoint_1, &node_graph);
        print("start_checkpoint_1: {d}\n", .{start_checkpoint_1});
        const start_checkpoint_2 = try path_count_fn(start, checkpoint_2, &node_graph);
        print("start_checkpoint_2: {d}\n", .{start_checkpoint_2});
        const checkpoint_1_checkpoint_2 = try path_count_fn(checkpoint_1, checkpoint_2, &node_graph);
        print("checkpoint_1_checkpoint_2: {d}\n", .{checkpoint_1_checkpoint_2});
        const checkpoint_2_checkpoint_1 = try path_count_fn(checkpoint_2, checkpoint_1, &node_graph);
        print("checkpoint_2_checkpoint_1: {d}\n", .{checkpoint_2_checkpoint_1});
        const checkpoint_1_end = try path_count_fn(checkpoint_1, end, &node_graph);
        print("checkpoint_1_end: {d}\n", .{checkpoint_1_end});
        const checkpoint_2_end = try path_count_fn(checkpoint_2, end, &node_graph);
        print("checkpoint_2_end: {d}\n", .{checkpoint_2_end});

        const path_count =
            start_checkpoint_1 * checkpoint_1_checkpoint_2 * checkpoint_2_end +
            start_checkpoint_2 * checkpoint_2_checkpoint_1 * checkpoint_2_end;

        print("Possible Problematic Paths {d}\n", .{path_count});
    }
}
