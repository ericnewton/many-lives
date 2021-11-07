#! /usr/bin/env node

// pretend we can be functional: use immutable data types
const { Set, Map } = require('immutable')
const live = "live";
const die = "die";
const showWork = false;
const generations = 1000;

// build an immutable cell position value
function pos(x, y) {
    return new Map({"x":x, "y":y})
}

// build an immutable cell change value
function change(liveDie, pos) {
    return new Map({"change": liveDie, "pos":pos})
}

// build a board, with live cells and next set of updates
function board(liveSet, updates) {
    return new Map({"liveSet":liveSet, "updates": updates});
}

// doesn't return an immutable value, but is only used for display
function boundingBox(liveSet) {
    if (liveSet.isEmpty()) {
	return [[0,0], [1,1]];
    }
    const xs = liveSet.map(p => p.get("x")).toArray();
    const ys = liveSet.map(p => p.get("y")).toArray();
    return [[Math.min(...xs), Math.min(...ys)],
	    [Math.max(...xs), Math.max(...ys)]]
}

// a simple range function
function range(start, end) {
    return [...Array(end - start).keys()].map(i => i + start);
}

// gross writing to stdout with console.log, but I don't know better
function clearScreen() {
    console.log("\033[2J\033[;H")
}

function printBoard(liveSet) {
    clearScreen();
    const bbox = boundingBox(liveSet);
    range(bbox[0][1], bbox[1][1] + 1).reverse().map(y => {
	const row = range(bbox[0][0], bbox[1][0] + 1);
	console.log(row.map(x => liveSet.has(pos(x, y)) ? "#" : " ").join(""));
    });
}

function applyUpdates(current, updates) {
    const toLive = new Set(
	updates.filter(e => e.get("change") == live).map(e => e.get("pos"))
    );
    const toDie = new Set(
	updates.filter(e => e.get("change") == die).map(e => e.get("pos"))
    );
    return current.union(toLive).subtract(toDie);
}

// This isn't functional: replacements wanted
function eight(p) {
    const result = []
    const px = p.get("x")
    const py = p.get("y")
    for (x = -1; x <= 1; x++) {
	for (y = -1; y <= 1; y++) {
	    if (x != 0 || y != 0) {
		result.push(pos(px + x, py + y));
	    }
	}
    }
    return result;
}

function neighbors(updates) {
    const each = updates.map(c => c.get("pos")).map(p => eight(p))
    return new Set([].concat(...each));
}

function neighborCount(alive, pos) {
    return eight(pos).map(p => alive.has(p)).filter(v => v).length;
}

function computeChange(liveSet, pos) {
    const count = neighborCount(liveSet, pos);
    if (count == 2) {
	return null;
    }
    const isAlive = liveSet.has(pos);
    if (count == 3) {
	if (isAlive) {
	    return null;
	} else {
	    return change("live", pos);
	}
    }
    if (isAlive) {
	return change("die", pos);
    }
    return null;
}

function computeChanges(alive, affected) {
    return affected.map(p => computeChange(alive, p)).filter(c => c);
}

function generation(count, b) {
    if (count <= 0) {
	return;
    }
    const liveSet = b.get("liveSet");
    const updates = b.get("updates");
    const newLiveSet = applyUpdates(liveSet, updates);
    const affected = neighbors(updates)
    const newUpdates = computeChanges(newLiveSet, affected)
    if (showWork) {
	printBoard(newLiveSet);
	setTimeout(() => generation(count - 1, board(newLiveSet, newUpdates)),
		   1000 / 30);
    } else {
	generation(count - 1, board(newLiveSet, newUpdates));
    }
}

const r_pentomino = [[0, 0], [0, 1], [1, 1], [-1, 0], [0, -1]]

function main() {
    const updates = r_pentomino.map(a => change("live", pos(a[0], a[1])));
    const b = board(new Set(), updates);
    const start = Date.now();
    generation(generations, board(new Set(), updates));
    const millis = Date.now() - start;
    console.log(generations * 1000 / millis + " generations per second");
}

if (showWork) {
    main()
} else {
    main()
    main()
    main()
    main()
    main()
}
