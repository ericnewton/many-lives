const std = @import("std");

const GENERATIONS = 1000;
const SHOW_WORK = false;

const stdout = std.io.getStdOut().writer();
// don't know where to get this from
const MAX_I32 = @as(i32, 0x7fffffff);
const MIN_I32 = @as(i32, -0x80000000);

const allocator = std.heap.c_allocator;

const Coord = struct {
    x: i32,
    y: i32,
};
const LiveSet = std.AutoHashMap(Coord, void);

const Destiny = enum {
    Live,
    Die,
};
const Change = struct {
    coord: Coord,
    destiny: Destiny,
};
const ChangeSet = std.AutoHashMap(Change, void);

// shorthand to make a Coord
fn c(x: i32, y: i32) Coord {
    return Coord{ .x = x, .y = y };
}
const r_pentomino = [_]Coord{ c(0, 0), c(0, 1), c(1, 1), c(-1, 0), c(0, -1) };

fn applyChanges(alive: LiveSet, changes: ChangeSet) !LiveSet {
    var result = LiveSet.init(allocator);
    try result.ensureCapacity(alive.count() + changes.count());
    var iter = alive.keyIterator();
    while (iter.next()) |next| {
        try result.put(next.*, {});
    }
    var change = changes.keyIterator();
    while (change.next()) |next| {
        if (next.destiny == Destiny.Live) {
            try result.put(next.coord, {});
        }
        if (next.destiny == Destiny.Die) {
            _ = result.remove(next.coord);
        }
    }
    return result;
}

const BoundingBox = struct {
    lowerLeft: Coord,
    upperRight: Coord,
};
fn boundingBox(alive: LiveSet) BoundingBox {
    var minx = MAX_I32;
    var miny = MAX_I32;
    var maxx = MIN_I32;
    var maxy = MIN_I32;
    var iter = alive.keyIterator();
    while (iter.next()) |next| {
        minx = std.math.min(minx, next.x);
        maxx = std.math.max(maxx, next.x);
        miny = std.math.min(miny, next.y);
        maxy = std.math.max(maxy, next.y);
    }
    return BoundingBox{ .lowerLeft = c(minx, miny), .upperRight = c(maxx, maxy) };
}

fn printGeneration(alive: LiveSet) !void {
    try stdout.print("\x1b[2J\x1b[;H", .{});
    const bbox = boundingBox(alive);
    var y = bbox.upperRight.y;
    while (y >= bbox.lowerLeft.y) {
        var x = bbox.lowerLeft.x;
        while (x <= bbox.upperRight.x) {
            if (alive.contains(c(x, y))) {
                try stdout.print("@", .{});
            } else {
                try stdout.print(" ", .{});
            }
            x = x + 1;
        }
        try stdout.print("\n", .{});
        y = y - 1;
    }
    const humanWaitMillis: i32 = 1000 / 30;
    std.time.sleep(humanWaitMillis * 1000000);
}

const neighborOffsets = [_][2]i32{
    [_]i32{ -1, -1 },
    [_]i32{ -1, 0 },
    [_]i32{ -1, 1 },

    [_]i32{ 0, -1 },
    [_]i32{ 0, 1 },

    [_]i32{ 1, -1 },
    [_]i32{ 1, 0 },
    [_]i32{ 1, 1 },
};

fn computeNeighbors(changes: ChangeSet) !LiveSet {
    var result = LiveSet.init(allocator);
    try result.ensureCapacity(changes.count() * 8);
    var iter = changes.keyIterator();
    while (iter.next()) |next| {
        for (neighborOffsets) |pair| {
            const x = pair[0];
            const y = pair[1];
            try result.put(c(next.coord.x + x, next.coord.y + y), {});
        }
    }
    return result;
}

fn neighborCount(alive: LiveSet, next: Coord) i32 {
    var result = @as(i32, 0);
    for (neighborOffsets) |pair| {
        const x = pair[0];
        const y = pair[1];
        if (alive.contains(c(next.x + x, next.y + y))) {
            result = result + 1;
        }
    }
    return result;
}

fn computeChanges(alive: LiveSet, changes: ChangeSet) !ChangeSet {
    var result = ChangeSet.init(allocator);
    var neighbors = try computeNeighbors(changes);
    try result.ensureCapacity(neighbors.count() / 2);
    defer neighbors.deinit();
    var iter = neighbors.keyIterator();
    while (iter.next()) |next| {
        const count = neighborCount(alive, next.*);
        if (count == 3) {
            if (!alive.contains(next.*)) {
                try result.put(Change{ .coord = next.*, .destiny = Destiny.Live }, {});
            }
        } else if (count != 2) {
            if (alive.contains(next.*)) {
                try result.put(Change{ .coord = next.*, .destiny = Destiny.Die }, {});
            }
        }
    }
    return result;
}

fn run() !void {
    var alive = LiveSet.init(allocator);
    defer alive.deinit();
    var changes = ChangeSet.init(allocator);
    defer changes.deinit();
    for (r_pentomino) |*coord, i| {
        const change = Change{ .coord = coord.*, .destiny = Destiny.Live };
        try changes.put(change, {});
    }
    var start = std.time.milliTimestamp();
    var i = @as(i32, 0);
    while (i < GENERATIONS) {
        var updated = applyChanges(alive, changes);
        alive.deinit();
        alive = try updated;
        if (SHOW_WORK) {
            try printGeneration(alive);
        }
        var nextGen = computeChanges(alive, changes);
        changes.deinit();
        changes = try nextGen;
        i = i + 1;
    }
    const diff = std.time.milliTimestamp() - start;
    try stdout.print("{d} generations per second\n", .{GENERATIONS / (@intToFloat(f32, diff) / 1000.0)});
}

pub fn main() !void {
    if (SHOW_WORK) {
        try run();
    } else {
        var i: i32 = 0;
        while (i < 5) {
            try run();
            i = i + 1;
        }
    }
}
