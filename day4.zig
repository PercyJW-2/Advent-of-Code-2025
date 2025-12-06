const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day4.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var grid: std.ArrayList(std.ArrayList(u8)) = .{};
    defer grid.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len < 3) {
            continue;
        }
        var line_array: std.ArrayList(u8) = .{};
        try line_array.append(allocator, 0);
        for (line) |val| {
            if (val == '.') {
                try line_array.append(allocator, 0);
            } else if (val == '@') {
                try line_array.append(allocator, 1);
            }
        }
        try line_array.append(allocator, 0);
        try grid.append(allocator, line_array);
    }

    var buffer_line_start: std.ArrayList(u8) = .{};
    var buffer_line_end: std.ArrayList(u8) = .{};

    for (0..grid.items[0].items.len) |_| {
        try buffer_line_start.append(allocator, 0);
        try buffer_line_end.append(allocator, 0);
    }
    try grid.insert(allocator, 0, buffer_line_start);
    try grid.append(allocator, buffer_line_end);

    var total_accessible_rolls: u32 = 0;
    var possible_to_take_stuff = true;
    while (possible_to_take_stuff) {
        var taken_rolls: u32 = 0;
        for (1..grid.items.len - 1) |idx| {
            for (1..grid.items[idx].items.len - 1) |jdx| {
                const neighbourcount: u32 =
                    grid.items[idx - 1].items[jdx - 1] +
                    grid.items[idx - 1].items[jdx] +
                    grid.items[idx - 1].items[jdx + 1] +
                    grid.items[idx].items[jdx - 1] +
                    grid.items[idx].items[jdx + 1] +
                    grid.items[idx + 1].items[jdx - 1] +
                    grid.items[idx + 1].items[jdx] +
                    grid.items[idx + 1].items[jdx + 1];
                if (neighbourcount < 4 and grid.items[idx].items[jdx] == 1) {
                    //print("{d}", .{neighbourcount});
                    taken_rolls += 1;
                    grid.items[idx].items[jdx] = 0;
                } else {
                    //print(".", .{});
                }
            }
            //print("\n", .{});
        }
        total_accessible_rolls += taken_rolls;
        if (taken_rolls == 0) {
            possible_to_take_stuff = false;
        }
    }

    print("Accessible Rolls: {d}\n", .{total_accessible_rolls});
}
