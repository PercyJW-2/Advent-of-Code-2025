const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const allocator = std.heap.smp_allocator;

const PackageType = struct {
    const Self = @This();
    shape_mask: [3][3]u8 = undefined,
    tile_count: usize = 0,
    pub fn buildPackageType(file_reader: *fs.File.Reader) !Self {
        var new_type: Self = .{};
        for (0..3) |row_idx| {
            const current_line = (try file_reader.interface.takeDelimiter('\n')).?;
            for (current_line, 0..) |field_value, col_idx| {
                switch (field_value) {
                    '#' => {
                        new_type.shape_mask[row_idx][col_idx] = 1;
                        new_type.tile_count += 1;
                    },
                    '.' => {
                        new_type.shape_mask[row_idx][col_idx] = 0;
                    },
                    else => {},
                }
            }
        }
        return new_type;
    }
};

const Field = struct {
    const Self = @This();
    height: usize = 0,
    width: usize = 0,
    package_type_counts: [6]usize = undefined,
    pub fn buildField(raw_str: []u8) !Self {
        var new_field: Self = .{};
        new_field.height = try std.fmt.parseInt(usize, raw_str[0..2], 10);
        new_field.width = try std.fmt.parseInt(usize, raw_str[3..5], 10);
        var str_iter = std.mem.splitScalar(u8, raw_str[7..], ' ');
        for (0..6) |package_type_idx| {
            const raw_count = str_iter.next().?;
            new_field.package_type_counts[package_type_idx] = try std.fmt.parseInt(usize, raw_count, 10);
        }
        return new_field;
    }
    pub fn getPackageCount(self: *const Self) usize {
        var acc_counts: usize = 0;
        for (self.package_type_counts) |count| {
            acc_counts += count;
        }
        return acc_counts;
    }
    pub fn doesFitPackages(self: *const Self, package_types: *[6]PackageType) bool {
        _ = package_types;
        // check most basic fit
        const package_count = self.getPackageCount();
        const max_needed_area = package_count * 9;
        const max_possible_height = self.height - @rem(self.height, 3);
        const max_possible_width = self.width - @rem(self.width, 3);
        return max_possible_height * max_possible_width >= max_needed_area;
    }
};

pub fn main() !void {
    const file = try fs.cwd().openFile("./inputs/day12.txt", .{});
    defer file.close();

    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var package_types: [6]PackageType = undefined;

    // read package_types
    var reading_package_types = true;
    var package_type_idx: usize = 0;
    while (reading_package_types) {
        const current_line = (try reader.interface.takeDelimiter('\n')).?;
        if (current_line.len == 0) {
            continue;
        }
        if (current_line[0] == '5') {
            reading_package_types = false;
        }
        package_types[package_type_idx] = try PackageType.buildPackageType(&reader);
        package_type_idx += 1;
    }

    // read areas to fit
    var areas: std.ArrayList(Field) = .empty;
    defer areas.deinit(allocator);
    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        const new_field = try Field.buildField(line);
        try areas.append(allocator, new_field);
    }

    var area_count: usize = 0;
    for (areas.items) |area| {
        if (area.doesFitPackages(&package_types)) {
            area_count += 1;
        }
    }
    print("{} of {} Areas fit all packages\n", .{ area_count, areas.items.len });
}
