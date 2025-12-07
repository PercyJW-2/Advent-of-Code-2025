const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

const Operator = enum {
    plus,
    mult,
};

const Col = struct {
    entries: std.ArrayList(u64) = .{},
    operator: Operator = undefined,
    fn calc_result(self: *const Col) u64 {
        switch (self.operator) {
            .plus => {
                var sum: u64 = 0;
                for (self.entries.items) |entr| {
                    sum += entr;
                }
                return sum;
            },
            .mult => {
                var prod: u64 = 1;
                for (self.entries.items) |entr| {
                    prod *= entr;
                }
                return prod;
            },
        }
    }
};

fn getEntryFromSlice(slice: []const u8) !u64 {
    var number: []const u8 = undefined;
    if (slice[0] == ' ') {
        var current_pos: usize = 0;
        while (slice[current_pos] == ' ') {
            current_pos += 1;
        }
        number = slice[current_pos..];
    } else {
        var current_pos: usize = slice.len - 1;
        while (slice[current_pos] == ' ') {
            current_pos -= 1;
        }
        number = slice[0 .. current_pos + 1];
    }
    return try std.fmt.parseInt(u64, number, 10);
}

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day6.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var raw_input: std.ArrayList(std.ArrayList(u8)) = .{};
    defer raw_input.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var raw_line: std.ArrayList(u8) = .{};
        try raw_line.appendSlice(allocator, line);
        try raw_input.append(allocator, raw_line);
    }

    var col_widths: std.ArrayList(usize) = .{};
    defer col_widths.deinit(allocator);
    var col_start: usize = 0;
    for (0..raw_input.items[0].items.len) |idx| {
        var col_end: bool = true;
        for (raw_input.items) |row| {
            if (row.items[idx] != ' ') {
                col_end = false;
                break;
            }
        }
        if (col_end) {
            try col_widths.append(allocator, idx - col_start);
            col_start = idx + 1;
        }
    }
    // append last col width
    try col_widths.append(allocator, raw_input.items[0].items.len - col_start);

    var cols: std.ArrayList(Col) = .{};
    var rotaded_cols: std.ArrayList(Col) = .{};
    defer cols.deinit(allocator);
    defer rotaded_cols.deinit(allocator);

    var current_pos: usize = 0;
    for (col_widths.items) |width| {
        var column: Col = .{};
        var rotated_col: Col = .{};
        var raw_col_numbers: std.ArrayList([]const u8) = .{};
        defer raw_col_numbers.deinit(allocator);
        for (raw_input.items[0 .. raw_input.items.len - 1]) |value| {
            const raw_entr = value.items[current_pos .. current_pos + width];
            const entr = try getEntryFromSlice(raw_entr);
            try column.entries.append(allocator, entr);
            try raw_col_numbers.append(allocator, raw_entr);
        }

        for (0..raw_col_numbers.items[0].len) |idx| {
            var rotated_num: std.ArrayList(u8) = .{};
            defer rotated_num.deinit(allocator);
            for (raw_col_numbers.items) |row| {
                try rotated_num.append(allocator, row[idx]);
            }
            const entr = try getEntryFromSlice(rotated_num.items);
            try rotated_col.entries.append(allocator, entr);
        }

        switch (raw_input.items[raw_input.items.len - 1].items[current_pos]) {
            '+' => {
                column.operator = .plus;
                rotated_col.operator = .plus;
            },
            '*' => {
                column.operator = .mult;
                rotated_col.operator = .mult;
            },
            else => {
                return error.InvalidOperator;
            },
        }

        try cols.append(allocator, column);
        try rotaded_cols.append(allocator, rotated_col);
        current_pos += width + 1;
    }

    var total_result: u64 = 0;
    var total_rotated_result: u64 = 0;
    for (cols.items) |column| {
        total_result += column.calc_result();
    }
    for (rotaded_cols.items) |column| {
        total_rotated_result += column.calc_result();
    }

    print("Total Result: {d}\n", .{total_result});
    print("Total Rotated Result {d}\n", .{total_rotated_result});
}
