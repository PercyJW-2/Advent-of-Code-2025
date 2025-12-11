const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.smp_allocator;

pub fn Queue(comptime Child: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        gpa: std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,

        pub fn init(gpa: std.mem.Allocator) Self {
            return Self{
                .gpa = gpa,
                .start = null,
                .end = null,
            };
        }
        pub fn deinit(self: *Self) void {
            while (self.dequeue()) |_| {
                _ = "noop";
            }
        }
        pub fn enqueue(self: *Self, value: Child) !void {
            const node = try self.gpa.create(Node);
            node.* = .{ .data = value, .next = null };
            if (self.end) |end| end.next = node //
            else self.start = node;
            self.end = node;
        }
        pub fn dequeue(self: *Self) ?Child {
            const start = self.start orelse return null;
            defer self.gpa.destroy(start);
            if (start.next) |next|
                self.start = next
            else {
                self.start = null;
                self.end = null;
            }
            return start.data;
        }
    };
}

const Machine = struct {
    target_lamps: u16 = 0,
    buttons: std.ArrayList(u16) = .empty,
    joltage_buttons_array: [16][16]u16 = @splat(@splat(0)),
    joltage_button_slice: [][16]u16 = undefined,
    joltages_array: [16]u16 = undefined,
    joltage_slice: []u16 = undefined,
    fn find_minimal_button_presses(self: *const Machine) !usize {
        var nodes = std.AutoHashMap(u16, usize).init(allocator);
        defer nodes.deinit();
        try nodes.put(0, 0);
        var next_elements = Queue(u16).init(allocator);
        defer next_elements.deinit();
        try next_elements.enqueue(0);
        while (true) {
            const current_node = next_elements.dequeue().?;
            const current_dist = nodes.get(current_node).?;
            if (current_node == self.target_lamps) {
                return current_dist;
            }
            for (self.buttons.items) |button| {
                const next_node = current_node ^ button;
                if (nodes.contains(next_node)) {
                    continue;
                }
                try nodes.put(next_node, current_dist + 1);
                try next_elements.enqueue(next_node);
            }
        }
    }
    fn gaussian_ellimination(self: *const Machine) void {
        // constructing augmented matrix
        var aug_matrix: [16][16]u16 = @splat(@splat(0));
        const aug_matrix_slice = aug_matrix[0..self.joltage_slice.len];
        const matrix_cols = self.joltage_button_slice.len + 1;
        for (0..aug_matrix_slice.len) |idx| {
            for (0..matrix_cols - 1) |jdx| {
                aug_matrix_slice[idx][jdx] = self.joltage_buttons_array[jdx][idx];
                print("{d}\t", .{aug_matrix_slice[idx][jdx]});
            }
            aug_matrix_slice[idx][matrix_cols - 1] = self.joltages_array[idx];
            print("{d}\n", .{aug_matrix_slice[idx][matrix_cols - 1]});
        }
    }
};

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day10.txt", .{});
    defer file.close();

    var file_buffer: [8192]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var machines: std.ArrayList(Machine) = .empty;
    defer machines.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var machine = Machine{};
        // parse expected lamp state
        const raw_lamp_idx = std.mem.indexOf(u8, line, "] ").?;
        const raw_lamp_slice = line[1..raw_lamp_idx];
        for (raw_lamp_slice, 0..) |raw_lamp, i| {
            if (raw_lamp == '#') {
                machine.target_lamps |= @as(u16, 1) << @truncate(i);
            }
        }
        // parse buttons
        const raw_button_idx = std.mem.indexOf(u8, line, ") {").?;
        const raw_button_slice = line[raw_lamp_idx + 3 .. raw_button_idx];
        var raw_buttons = std.mem.splitSequence(u8, raw_button_slice, ") (");
        var button_count: usize = 0;
        while (raw_buttons.next()) |raw_button| {
            button_count += 1;
            var button: u16 = 0;
            var button_wires = std.mem.splitScalar(u8, raw_button, ',');
            while (button_wires.next()) |button_wire| {
                button |= @as(u16, 1) << @truncate(button_wire[0] - '0');
                machine.joltage_buttons_array[button_count - 1][@as(usize, button_wire[0] - '0')] = 1;
            }
            machine.joltage_button_slice = machine.joltage_buttons_array[0..button_count];
            try machine.buttons.append(allocator, button);
        }
        // parse joltages TODO this is for part 2
        const raw_joltage_slice = line[raw_button_idx + 3 .. line.len - 1];
        var raw_joltages = std.mem.splitScalar(u8, raw_joltage_slice, ',');
        var idx: usize = 0;
        while (raw_joltages.next()) |raw_joltage| {
            const joltage = try std.fmt.parseInt(u16, raw_joltage, 10);
            machine.joltages_array[idx] = joltage;
            idx += 1;
        }
        machine.joltage_slice = machine.joltages_array[0..idx];
        try machines.append(allocator, machine);
    }

    var button_presses: usize = 0;
    const button_joltage_presses: usize = 0;
    for (machines.items, 0..) |machine, idx| {
        print("\n{d}/{d}\n", .{ idx + 1, machines.items.len });
        button_presses += try machine.find_minimal_button_presses();
        //button_joltage_presses += try machine.find_minimal_button_joltage_presses();
        machine.gaussian_ellimination();
    }

    print("Total Button Presses: {d}\n", .{button_presses});
    print("Total Button Joltage Presses: {d}\n", .{button_joltage_presses});
}
