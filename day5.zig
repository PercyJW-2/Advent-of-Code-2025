const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

const Range = struct {
    start: u64,
    end: u64,
    fn isWithin(self: *const Range, to_check: u64) bool {
        if (to_check >= self.start and to_check <= self.end) {
            return true;
        }
        return false;
    }
    fn getAmount(self: *const Range) u64 {
        return self.end - (self.start - 1);
    }
    fn combine(self: *const Range, other: Range) ?Range {
        if (self.isWithin(other.start) or self.isWithin(other.end)) {
            var start: u64 = 0;
            if (self.start < other.start) {
                start = self.start;
            } else {
                start = other.start;
            }
            var end: u64 = 0;
            if (self.end > other.end) {
                end = self.end;
            } else {
                end = other.end;
            }
            return .{ .start = start, .end = end };
        }
        return null;
    }
};

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day5.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var ranges: std.ArrayList(Range) = .{};

    // reading valid id ranges
    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            break;
        }
        var range_raw = std.mem.splitScalar(u8, line, '-');
        const start = try std.fmt.parseInt(u64, range_raw.next().?, 10);
        const end = try std.fmt.parseInt(u64, range_raw.next().?, 10);
        try ranges.append(allocator, .{ .start = start, .end = end });
    }

    var fresh_count: u64 = 0;
    // reading all item ids
    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        const item_id = try std.fmt.parseInt(u64, line, 10);
        for (ranges.items) |range_loc| {
            if (range_loc.isWithin(item_id)) {
                fresh_count += 1;
                break;
            }
        }
    }

    std.mem.sort(Range, ranges.items, {}, struct {
        pub fn lessThan(ctx: void, a: Range, b: Range) bool {
            _ = ctx;
            return a.start < b.start;
        }
    }.lessThan);

    var idx: usize = 0;
    while (idx < ranges.items.len) {
        var jdx: usize = idx + 1;
        var updated: bool = false;
        while (jdx < ranges.items.len) {
            const result = ranges.items[idx].combine(ranges.items[jdx]);
            if (result == null) {
                jdx += 1;
                continue;
            }
            updated = true;
            ranges.items[idx].start = result.?.start;
            ranges.items[idx].end = result.?.end;
            _ = ranges.orderedRemove(jdx);
        }
        if (!updated) {
            idx += 1;
        }
    }

    var total_fresh_count: u64 = 0;
    for (ranges.items) |range_loc| {
        //print("Range amount: {d}, Start {d}, End {d}\n", .{ range_loc.getAmount(), range_loc.start, range_loc.end });
        total_fresh_count += range_loc.getAmount();
    }

    print("Amount fresh: {d}\n", .{fresh_count});
    print("Total amount fresh: {d}\n", .{total_fresh_count});
}
