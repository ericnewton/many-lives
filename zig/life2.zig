const std = @import("std");

const GENERATIONS = 1000;
const SHOW_WORK = false;
const HUMAN_WAIT_MILLIS: i32 = 1000 / 30;

const stdout = std.io.getStdOut().writer();
const allocator = std.heap.c_allocator;

const Coord = struct {
    x: i32,
    y: i32,
};
const LiveSet = std.AutoHashMap(Coord, void);

// shorthand to make a Coord
fn c(x: i32, y: i32) Coord {
    return Coord{ .x = x, .y = y };
}
const r_pentomino = [_]Coord{ c(0, 0), c(0, 1), c(1, 1), c(-1, 0), c(0, -1) };

fn printGeneration(alive: LiveSet) !void {
    try stdout.print("\x1b[2J\x1b[;H", .{});
    var y: i32 = 12;
    while (y > -12) : (y -= 1) {
        var x: i32 = -40;
        while (x < 40) : (x += 1) {
            if (alive.contains(c(x, y))) {
                try stdout.print("@", .{});
            } else {
                try stdout.print(" ", .{});
            }
        }
        try stdout.print("\n", .{});
    }
    std.time.sleep(HUMAN_WAIT_MILLIS * 1000000);
}

const Offset = Coord;
fn offset(x: i32, y: i32) Offset {
    return Offset{ .x = x, .y = y };
}
const neighborOffsets = [_]Offset{
    offset(-1, -1), offset(0, -1), offset(1, -1),
    offset(-1, 0),  offset(1, 0),  offset(-1, 1),
    offset(0, 1),   offset(1, 1),
};

fn nextGeneration(live: LiveSet) !LiveSet {
    var counts = std.AutoHashMap(Coord, u8).init(allocator);
    defer counts.deinit();
    try counts.ensureTotalCapacity(live.count() * 8);
    {
        var iter = live.keyIterator();
        while (iter.next()) |next| {
            for (neighborOffsets) |xy| {
                const gop = try counts.getOrPut(c(next.x + xy.x, next.y + xy.y));
                if (gop.found_existing) {
                    gop.value_ptr.* += 1;
                } else {
                    gop.value_ptr.* = 1;
                }
            }
        }
    }
    {
        var result = LiveSet.init(allocator);
        try result.ensureTotalCapacity(live.count() * 2);
        var iter = counts.iterator();
        while (iter.next()) |next| {
            if (next.value_ptr.* == 3 or (next.value_ptr.* == 2 and live.contains(next.key_ptr.*))) {
                try result.put(next.key_ptr.*, {});
            }
        }
        return result;
    }
}

fn run() !void {
    var alive = LiveSet.init(allocator);
    defer alive.deinit();
    for (&r_pentomino) |*coord| {
        try alive.put(coord.*, {});
    }
    const start = std.time.milliTimestamp();
    for (0..GENERATIONS) |_| {
        if (SHOW_WORK) {
            try printGeneration(alive);
        }
        const updated = nextGeneration(alive);
        alive.deinit();
        alive = try updated;
    }
    const diff = std.time.milliTimestamp() - start;
    try stdout.print("{d} generations per second\n", .{GENERATIONS / (@as(f32, @floatFromInt(diff)) / 1000.0)});
}

pub fn main() !void {
    if (SHOW_WORK) {
        try run();
    } else {
        for (0..5) |_| {
            try run();
        }
    }
}
