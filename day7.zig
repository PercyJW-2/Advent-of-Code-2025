const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

const FieldType = enum {
    start,
    splitter,
    normal,
};

const Start = struct {};
const Splitter = struct {};
const Normal = struct {
    beam_count: usize = 0,
};

const Field = union(FieldType) {
    start: Start,
    splitter: Splitter,
    normal: Normal,
};

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day7.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var field: std.ArrayList(std.ArrayList(Field)) = .empty;
    defer field.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var field_line: std.ArrayList(Field) = .{};
        for (line) |value| {
            switch (value) {
                '.' => {
                    try field_line.append(allocator, Field{ .normal = .{} });
                },
                'S' => {
                    try field_line.append(allocator, Field{ .start = .{} });
                },
                '^' => {
                    try field_line.append(allocator, Field{ .splitter = .{} });
                },
                else => {},
            }
        }
        try field.append(allocator, field_line);
    }

    // find start index
    for (field.items[0].items, 0..) |tile, idx| {
        switch (tile) {
            .start => |_| {
                const normal_tile = &field.items[1].items[idx].normal;
                normal_tile.*.beam_count += 1;
                break;
            },
            else => {},
        }
    }
    // update field

    var split_count: usize = 0;

    for (field.items[2..], 2..) |line, idx| {
        for (line.items, 0..) |tile, jdx| {
            switch (field.items[idx - 1].items[jdx]) {
                .normal => |normal| {
                    if (normal.beam_count == 0) {
                        continue;
                    }
                    switch (tile) {
                        .normal => |_| {
                            const normal_tile = &line.items[jdx].normal;
                            normal_tile.*.beam_count += normal.beam_count;
                        },
                        .splitter => |_| {
                            split_count += 1;
                            const left_tile = &line.items[jdx - 1].normal;
                            const right_tile = &line.items[jdx + 1].normal;
                            left_tile.*.beam_count += normal.beam_count;
                            right_tile.*.beam_count += normal.beam_count;
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }
    }

    var timeline_count: usize = 0;
    for (field.getLast().items) |tile| {
        switch (tile) {
            .normal => |normal_tile| {
                timeline_count += normal_tile.beam_count;
            },
            else => {},
        }
    }

    print("Split Count: {d}\n", .{split_count});
    print("Timeline Count: {d}\n", .{timeline_count});
}
