const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.smp_allocator;

const NetType = enum {
    point,
    network,
};

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
    fn distance_to(self: *const Vec3, other: *const Vec3) f32 {
        return std.math.sqrt(std.math.pow(f32, self.x - other.x, 2.0) +
            std.math.pow(f32, self.y - other.y, 2.0) +
            std.math.pow(f32, self.z - other.z, 2.0));
    }
    fn equal_to(self: *const Vec3, other: *const Vec3) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }
};

const Network = struct {
    points: std.ArrayList(Vec3) = .empty,
    fn min_distance_to_point(self: *const Network, other: *const Vec3) f32 {
        var minimum: f32 = 500000;
        for (self.points.items) |point| {
            const dist = point.distance_to(other);
            if (dist < minimum) {
                minimum = dist;
            }
        }
        return minimum;
    }
    fn min_distance_to_net(self: *const Network, other: *const Network) f32 {
        var minimum: f32 = 500000;
        for (self.points.items) |point| {
            const dist = other.min_distance_to_point(&point);
            if (dist < minimum) {
                minimum = dist;
            }
        }
        return minimum;
    }
};

const NetNode = union(NetType) {
    point: Vec3,
    network: Network,
    fn distance_to(self: *const NetNode, other: *const NetNode) f32 {
        switch (self.*) {
            .point => |point| {
                switch (other.*) {
                    .point => |other_point| {
                        return point.distance_to(&other_point);
                    },
                    .network => |network| {
                        return network.min_distance_to_point(&point);
                    },
                }
            },
            .network => |network| {
                switch (other.*) {
                    .point => |point| {
                        return network.min_distance_to_point(&point);
                    },
                    .network => |other_network| {
                        return network.min_distance_to_net(&other_network);
                    },
                }
            },
        }
    }
    fn join(self: *const NetNode, other: *const NetNode) !NetNode {
        var new_network: Network = .{};
        switch (self.*) {
            .point => |point| {
                try new_network.points.append(allocator, point);
            },
            .network => |network| {
                try new_network.points.appendSlice(allocator, network.points.items);
            },
        }
        switch (other.*) {
            .point => |point| {
                try new_network.points.append(allocator, point);
            },
            .network => |network| {
                try new_network.points.appendSlice(allocator, network.points.items);
            },
        }
        return .{ .network = new_network };
    }
};

const NodeConnection = struct { a: Vec3, b: Vec3, dist: f32 };

fn find_pos_idx(positions: *const std.ArrayList(NetNode), to_find: *const Vec3) !usize {
    for (positions.items, 0..) |position, idx| {
        switch (position) {
            .point => |point| {
                if (point.equal_to(to_find)) {
                    return idx;
                }
            },
            .network => |network| {
                for (network.points.items) |net_pos| {
                    if (net_pos.equal_to(to_find)) {
                        return idx;
                    }
                }
            },
        }
    }
    return error.CouldNotFindVec3;
}

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day8.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var positions: std.ArrayList(NetNode) = .empty;
    defer positions.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var splits = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseFloat(f32, splits.next().?);
        const y = try std.fmt.parseFloat(f32, splits.next().?);
        const z = try std.fmt.parseFloat(f32, splits.next().?);
        const pos = Vec3{ .x = x, .y = y, .z = z };
        try positions.append(allocator, .{ .point = pos });
    }

    var distances: std.ArrayList(NodeConnection) = .empty;
    defer distances.deinit(allocator);
    //calculate all distances
    for (positions.items, 0..) |pos_0, idx| {
        for (positions.items[idx..], idx..) |pos_1, jdx| {
            if (idx == jdx) {
                continue;
            }
            const node_conn: NodeConnection = .{ .a = pos_0.point, .b = pos_1.point, .dist = pos_0.distance_to(&pos_1) };
            try distances.append(allocator, node_conn);
        }
    }
    std.mem.sort(NodeConnection, distances.items, {}, struct {
        pub fn lessThan(ctx: void, a: NodeConnection, b: NodeConnection) bool {
            _ = ctx;
            return a.dist < b.dist;
        }
    }.lessThan);
    print("Calculated and sorted all distances\n", .{});

    for (distances.items[0..1000]) |dist| {
        const first_idx = try find_pos_idx(&positions, &dist.a);
        const second_idx = try find_pos_idx(&positions, &dist.b);
        if (first_idx == second_idx) {
            continue;
        }
        var smaller_idx: usize = 0;
        var larger_idx: usize = 0;
        if (first_idx < second_idx) {
            smaller_idx = first_idx;
            larger_idx = second_idx;
        } else {
            smaller_idx = second_idx;
            larger_idx = first_idx;
        }
        //print("first: {d}, second: {d}, current len: {d}\n", .{ first_idx, second_idx, positions.items.len });
        const first = positions.swapRemove(larger_idx);
        const second = positions.swapRemove(smaller_idx);
        const joined = try first.join(&second);
        try positions.append(allocator, joined);
    }

    std.mem.sort(NetNode, positions.items, {}, struct {
        pub fn lessThan(ctx: void, a: NetNode, b: NetNode) bool {
            _ = ctx;
            switch (a) {
                .point => |point| {
                    switch (b) {
                        .point => |other_point| {
                            return other_point.x < point.x;
                        },
                        .network => |_| {
                            return false;
                        },
                    }
                },
                .network => |network| {
                    switch (b) {
                        .point => |_| {
                            return true;
                        },
                        .network => |other_network| {
                            return other_network.points.items.len < network.points.items.len;
                        },
                    }
                },
            }
        }
    }.lessThan);

    const net_len0 = positions.items[0].network.points.items.len;
    const net_len1 = positions.items[1].network.points.items.len;
    const net_len2 = positions.items[2].network.points.items.len;

    const result_part1 = net_len0 * net_len1 * net_len2;

    print("Part 1 Solution: {d}\n{d} {d} {d}\n", .{ result_part1, net_len0, net_len1, net_len2 });

    for (distances.items) |dist| {
        const first_idx = try find_pos_idx(&positions, &dist.a);
        const second_idx = try find_pos_idx(&positions, &dist.b);
        if (first_idx == second_idx) {
            continue;
        }
        var smaller_idx: usize = 0;
        var larger_idx: usize = 0;
        if (first_idx < second_idx) {
            smaller_idx = first_idx;
            larger_idx = second_idx;
        } else {
            smaller_idx = second_idx;
            larger_idx = first_idx;
        }
        //print("first: {d}, second: {d}, current len: {d}\n", .{ first_idx, second_idx, positions.items.len });
        const first = positions.swapRemove(larger_idx);
        const second = positions.swapRemove(smaller_idx);
        const joined = try first.join(&second);
        try positions.append(allocator, joined);
        if (positions.items.len == 1) {
            print("Part 2 Solution: {d}\n", .{dist.a.x * dist.b.x});
            return;
        }
    }
}
