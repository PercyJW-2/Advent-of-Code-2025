const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day1.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var dial: i32 = 50;

    var zero_pos_count: i32 = 0;
    var zero_click_count: i32 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var direction: i8 = 0;
        switch (line[0]) {
            'L' => {
                direction = -1;
            },
            'R' => {
                direction = 1;
            },
            else => {},
        }
        const raw_amount = try std.fmt.parseInt(i32, line[1..], 10);
        zero_click_count += @divTrunc(raw_amount, 100);
        const amount = direction * (@rem(raw_amount, 100));
        const temp: i32 = dial + amount;
        if (temp < 0) {
            if (dial != 0) {
                zero_click_count += 1;
            }
            dial = 100 + temp;
        } else if (temp > 99) {
            if (dial != 0) {
                zero_click_count += 1;
            }
            dial = temp - 100;
        } else {
            dial = temp;
            if (dial == 0) {
                zero_click_count += 1;
            }
        }
        print("Current Dial Pos: {d}\tAmount: {d}\tClickCount: {d}\n", .{ dial, temp, zero_click_count });
        if (dial == 0) {
            zero_pos_count += 1;
        }
    }
    print("Dial Pos Count: {d}\n Dial Zero Click Count: {d}\n", .{ zero_pos_count, zero_click_count });
}
