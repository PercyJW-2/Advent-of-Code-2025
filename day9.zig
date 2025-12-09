const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.smp_allocator;

const Vec2 = struct {
    x: i64,
    y: i64,
    fn get_area_with(self: *const Vec2, other: *const Vec2) u64 {
        return (@abs(self.x - other.x) + 1) * (@abs(self.y - other.y) + 1);
    }
};

fn get_square_points(corners: [2]Vec2) [2]Vec2 {
    var min_xy = Vec2{ .x = 0, .y = 0 };
    var max_xy = Vec2{ .x = 0, .y = 0 };
    if (corners[0].x > corners[1].x) {
        max_xy.x = corners[0].x;
        min_xy.x = corners[1].x;
    } else {
        max_xy.x = corners[1].x;
        min_xy.x = corners[0].x;
    }
    if (corners[0].y > corners[1].y) {
        max_xy.y = corners[0].y;
        min_xy.y = corners[1].y;
    } else {
        max_xy.y = corners[1].y;
        min_xy.y = corners[0].y;
    }
    return .{ min_xy, max_xy };
}
fn is_edge_within_or_intersecting_square(square_points: [2]Vec2, edge: [2]Vec2) bool {
    return square_points[0].x < edge[1].x and
        square_points[1].x > edge[0].x and
        square_points[0].y < edge[1].y and
        square_points[1].y > edge[0].y;
}

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day9.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var positions: std.ArrayList(Vec2) = .empty;
    defer positions.deinit(allocator);
    var edges: std.ArrayList([2]Vec2) = .empty;
    defer edges.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var splits = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, splits.next().?, 10);
        const y = try std.fmt.parseInt(i64, splits.next().?, 10);
        const pos = Vec2{ .x = x, .y = y };

        if (positions.items.len > 0) {
            try edges.append(allocator, get_square_points(.{ positions.getLast(), pos }));
        }

        try positions.append(allocator, pos);
    }
    try edges.append(allocator, get_square_points(.{ positions.getLast(), positions.items[0] }));

    var max_area: u64 = 0;
    var max_area_in_poly: u64 = 0;
    for (positions.items[0 .. positions.items.len - 1], 0..) |pos_0, idx| {
        for (positions.items[idx + 1 ..]) |pos_1| {
            // check part 1
            const current_area = pos_0.get_area_with(&pos_1);
            if (current_area > max_area) {
                max_area = current_area;
            }
            // check part 2
            if (current_area <= max_area_in_poly) {
                continue;
            }
            var square_in_poly: bool = true;
            const square_points = get_square_points(.{ pos_0, pos_1 });

            for (edges.items) |edge| {
                if (is_edge_within_or_intersecting_square(square_points, edge)) {
                    square_in_poly = false;
                    break;
                }
            }
            if (square_in_poly) {
                max_area_in_poly = current_area;
            }
        }
    }

    print("Largest Area possible: {d}\n", .{max_area});
    print("Largest Area within poly possible: {d}\n", .{max_area_in_poly});
}
