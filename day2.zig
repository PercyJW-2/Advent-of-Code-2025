const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day2.txt", .{});
    defer file.close();

    var file_buffer: [8192]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var invalid_id_sum: u64 = 0;
    var second_invalid_id_sum: u64 = 0;

    while (try reader.interface.takeDelimiter(',')) |line| {
        if (line.len < 3) {
            continue;
        }
        var it = std.mem.splitScalar(u8, line, '-');
        const start_str = it.next().?;
        const end_str = it.next().?;
        const seq_start = try std.fmt.parseInt(u64, start_str, 10);
        const seq_end = try std.fmt.parseInt(u64, end_str, 10);

        for (seq_start..seq_end + 1) |item_id| {
            var buffer: [64]u8 = undefined;
            const res = try std.fmt.bufPrint(&buffer, "{d}", .{item_id});

            for (1..(res.len / 2) + 1) |section_length| {
                if (@rem(res.len, section_length) != 0) {
                    continue;
                }
                const first_section = res[0..section_length];
                var invalid_id: bool = true;
                for (1..res.len / section_length) |section_number| {
                    const section_to_check = res[(section_length * section_number)..(section_length * (section_number + 1))];
                    if (std.mem.eql(u8, first_section, section_to_check) == false) {
                        invalid_id = false;
                        break;
                    }
                }
                if (invalid_id) {
                    second_invalid_id_sum += item_id;
                    //print("complete: {s}\n", .{res});
                    break;
                }
            }

            if (@rem(res.len, 2) == 1) {
                continue;
            }
            const first_half = res[0 .. res.len / 2];
            const second_half = res[(res.len / 2)..];
            if (std.mem.eql(u8, first_half, second_half) == true) {
                invalid_id_sum += item_id;
                //print("complete: {s}\tfirst_half: {s}\tsecond_half: {s}\n", .{ res, first_half, second_half });
            }
        }
    }
    print("Sum of Invalid Ids: {d}\n", .{invalid_id_sum});
    print("Secont Sum of Invalid Ids: {d}\n", .{second_invalid_id_sum});
}
