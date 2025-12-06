const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

fn getBankJoltage(bank: []const u8, bats_to_activate: comptime_int) error{ InvalidCharacter, Overflow }!u64 {
    if (bank.len < 3) {
        return 0;
    }
    var joltage_str: [bats_to_activate]u8 = undefined;
    var start_joltage_idx: usize = 0;
    for (1..bats_to_activate + 1) |i| {
        var current_max_joltage: u8 = 0;
        var current_max_idx: usize = 0;
        for (bank[start_joltage_idx .. bank.len - (bats_to_activate - i)], 0..) |bat_joltage, idx| {
            if (bat_joltage > current_max_joltage) {
                current_max_joltage = bat_joltage;
                current_max_idx = idx + start_joltage_idx;
            }
        }
        //print("{d}", .{current_max_idx});
        joltage_str[i - 1] = current_max_joltage;
        start_joltage_idx = current_max_idx + 1;
    }
    //print("Bank Joltage: {s}\n", .{joltage_str});
    const bank_joltage = try std.fmt.parseInt(u64, &joltage_str, 10);
    return bank_joltage;
}

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day3.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var total_joltage: u64 = 0;
    var larger_total_joltage: u64 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const bank_joltage = try getBankJoltage(line, 2);
        const second_joltage = try getBankJoltage(line, 12);
        //print("Bank Joltage: {d}\n", .{bank_joltage});
        total_joltage += bank_joltage;
        larger_total_joltage += second_joltage;
    }
    print("Total Joltage: {d}\n", .{total_joltage});
    print("Larger Total Joltage: {d}\n", .{larger_total_joltage});
}
